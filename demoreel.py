#!/usr/bin/env python3
"""Record a GUI app on a private virtual display.

See README.md for why this exists and — more importantly — what it must never
grow into. In short: recording the real screen films the user's desktop and
their accessibility tools, so instead the app runs on an Xvfb display that has
neither, and that display is what gets recorded.

Usage:

    demoreel.py --app "flatpak run com.example.App" --out demo.mp4 --duration 25
    demoreel.py --app "python -m myapp" --out demo.mp4 \\
        --do wait:3 --do "type:hello" --do key:Return --do wait:2

Any Claude Code session may call this, from any project, at the same time as
another one — so the display number is discovered per run, never fixed.
"""

from __future__ import annotations

import argparse
import os
import shlex
import signal
import subprocess
import sys
import time
from pathlib import Path

# Where to look for a free X display. :0 is the real session; start well clear
# of it and of the handful of numbers other tooling tends to grab.
_DISPLAY_RANGE = range(101, 200)
_X11_SOCKETS = Path("/tmp/.X11-unix")

# How long to wait for things that are normally near-instant but occasionally
# are not: the display coming up, and the app mapping its first window.
_DISPLAY_TIMEOUT_S = 10.0
_WINDOW_TIMEOUT_S = 40.0

_REQUIRED_TOOLS = ("Xvfb", "xdotool", "ffmpeg")


class DemoreelError(RuntimeError):
    """Anything that should stop the run with a readable message."""


def _log(message: str) -> None:
    print(f">> {message}", file=sys.stderr, flush=True)


def _check_tools() -> None:
    missing = [t for t in _REQUIRED_TOOLS if _which(t) is None]
    if missing:
        raise DemoreelError(
            f"missing required tool(s): {', '.join(missing)}. "
            "Install them and retry (Xvfb: package xorg-x11-server-Xvfb or "
            "xvfb; xdotool and ffmpeg are packaged under their own names)."
        )


def _which(name: str) -> str | None:
    from shutil import which

    return which(name)


def _claim_display() -> int:
    """Return a display number nothing else is using.

    Racy in principle — another process could claim the same number between the
    check and Xvfb starting — so the caller confirms the display actually came
    up and moves on to the next number if it did not. That loop is what makes
    concurrent runs safe, not this check on its own.
    """
    for number in _DISPLAY_RANGE:
        if not (_X11_SOCKETS / f"X{number}").exists():
            return number
    raise DemoreelError(
        f"no free X display in :{_DISPLAY_RANGE.start}-:{_DISPLAY_RANGE.stop - 1} "
        "— likely leaked Xvfb processes from earlier runs (check `pgrep -a Xvfb`)"
    )


def _start_display(size: str) -> tuple[subprocess.Popen[bytes], str]:
    """Start Xvfb on a free number and return it once it answers."""
    width, height = _parse_size(size)
    last_error = ""
    for _ in range(5):
        number = _claim_display()
        display = f":{number}"
        proc = subprocess.Popen(
            [
                "Xvfb",
                display,
                "-screen",
                "0",
                f"{width}x{height}x24",
                "-nolisten",
                "tcp",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )
        if _wait_for_display(display, proc):
            _log(f"virtual display {display} up at {width}x{height}")
            return proc, display
        # Someone else took the number, or Xvfb died. Try the next one.
        proc.kill()
        proc.wait(timeout=5)
        last_error = f"{display} did not come up"
    raise DemoreelError(f"could not start a virtual display ({last_error})")


def _wait_for_display(display: str, proc: subprocess.Popen[bytes]) -> bool:
    deadline = time.monotonic() + _DISPLAY_TIMEOUT_S
    while time.monotonic() < deadline:
        if proc.poll() is not None:
            return False
        probe = subprocess.run(
            ["xdotool", "getdisplaygeometry"],
            env={**os.environ, "DISPLAY": display},
            capture_output=True,
        )
        if probe.returncode == 0:
            return True
        time.sleep(0.2)
    return False


def _parse_size(size: str) -> tuple[int, int]:
    try:
        width, height = (int(part) for part in size.lower().split("x", 1))
    except ValueError:
        raise DemoreelError(f"--size must look like 1600x1000, got {size!r}") from None
    if width < 320 or height < 240:
        raise DemoreelError(f"--size {size} is too small to be a useful recording")
    # x264 needs even dimensions; refuse rather than silently rescale, so the
    # recorded frame is exactly the size that was asked for.
    if width % 2 or height % 2:
        raise DemoreelError(f"--size {size} must use even numbers (H.264 requires it)")
    return width, height


def _launch_app(command: str, display: str) -> subprocess.Popen[bytes]:
    """Start the target app on the virtual display.

    DISPLAY is set in the environment the app is spawned with, which is what a
    normal X client reads. Note this is NOT sufficient for a Flatpak: the
    sandbox is given the session's X socket, not one named later, so a Flatpak
    target needs `flatpak run --socket=x11 …` in the command itself. See
    README.md's "known obstacle".
    """
    env = {**os.environ, "DISPLAY": display}
    env.pop("WAYLAND_DISPLAY", None)  # else Qt/GTK prefer Wayland and ignore us
    proc = subprocess.Popen(
        shlex.split(command),
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        start_new_session=True,  # so we can kill the whole tree, not just the shim
    )
    _log(f"launched: {command}")
    return proc


def _wait_for_window(display: str, app: subprocess.Popen[bytes]) -> str:
    """Return the id of the app's first mapped window.

    Waits for a window rather than a fixed sleep — startup time varies wildly
    between a source launch and a cold Flatpak, and a sleep long enough for the
    slow case wastes it on every fast one.
    """
    deadline = time.monotonic() + _WINDOW_TIMEOUT_S
    while time.monotonic() < deadline:
        if app.poll() is not None:
            stderr = (app.stderr.read().decode(errors="replace") if app.stderr else "")
            hint = ""
            if app.returncode == 0:
                # Exiting 0 without a window is almost always a single-instance
                # guard: the app found a copy of itself already running, handed
                # the request over and quit. That copy is on the user's real
                # display, so nothing ever appears here. Worth naming, because
                # "succeeded but produced nothing" reads like a demoreel bug.
                hint = (
                    "\n\nIt exited SUCCESSFULLY without showing a window, which "
                    "usually means the app has a single-instance guard and one "
                    "copy is already running (it raised that window instead). "
                    "Close the running copy and retry."
                )
            raise DemoreelError(
                f"the app exited before showing a window (code {app.returncode}).\n"
                f"Its stderr:\n{stderr.strip() or '(nothing)'}{hint}"
            )
        found = subprocess.run(
            ["xdotool", "search", "--onlyvisible", "--name", "."],
            env={**os.environ, "DISPLAY": display},
            capture_output=True,
            text=True,
        )
        ids = [line for line in found.stdout.split() if line.strip()]
        if ids:
            return ids[-1]
        time.sleep(0.3)
    raise DemoreelError(
        f"no window appeared within {_WINDOW_TIMEOUT_S:.0f}s — the app may be "
        "waiting on something, or failing to reach the display"
    )


def _fit_window(display: str, window_id: str, size: str) -> None:
    """Move the window to the origin and size it to the whole frame.

    No window manager runs on the virtual display — none is needed to record a
    single app, and adding one would be a dependency for no gain. Two
    consequences: `windowactivate` fails (it needs a WM advertising
    _NET_ACTIVE_WINDOW) and is skipped, which costs nothing because the only
    window on the display already has focus; and an app that genuinely needs a
    WM — one whose dialogs must be positioned or stacked — may misbehave. If
    that ever comes up, the fix is to run a minimal WM, not to grow this
    function.
    """
    width, height = _parse_size(size)
    env = {**os.environ, "DISPLAY": display}
    subprocess.run(
        ["xdotool", "windowmove", window_id, "0", "0"], env=env, check=False
    )
    subprocess.run(
        ["xdotool", "windowsize", window_id, str(width), str(height)],
        env=env,
        check=False,
    )
    time.sleep(0.5)  # let the toolkit finish relayout before the first frame


def _start_recording(display: str, size: str, out: Path, fps: int) -> subprocess.Popen[bytes]:
    width, height = _parse_size(size)
    out.parent.mkdir(parents=True, exist_ok=True)
    command = [
        "ffmpeg",
        "-y",
        "-f", "x11grab",
        "-video_size", f"{width}x{height}",
        "-framerate", str(fps),
        "-i", display,
        "-codec:v", "libx264",
        "-preset", "veryfast",
        # yuv420p because some players (and GitHub's inline preview) will not
        # show x264's default 4:4:4 at all — a video nobody can play is worse
        # than a slightly larger one.
        "-pix_fmt", "yuv420p",
        "-movflags", "+faststart",
        str(out),
    ]
    proc = subprocess.Popen(
        command, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, stdin=subprocess.PIPE
    )
    _log(f"recording {display} -> {out}")
    return proc


def _run_actions(display: str, actions: list[str]) -> None:
    """Play a short list of `verb:argument` steps through xdotool."""
    env = {**os.environ, "DISPLAY": display}
    for action in actions:
        verb, _, argument = action.partition(":")
        verb = verb.strip().lower()
        argument = argument.strip()
        if verb == "wait":
            time.sleep(_positive_float(argument, action))
        elif verb == "type":
            subprocess.run(
                ["xdotool", "type", "--delay", "60", argument], env=env, check=False
            )
        elif verb == "key":
            subprocess.run(["xdotool", "key", argument], env=env, check=False)
        elif verb == "click":
            x, _, y = argument.partition(",")
            subprocess.run(
                ["xdotool", "mousemove", x.strip(), y.strip(), "click", "1"],
                env=env,
                check=False,
            )
        elif verb == "move":
            x, _, y = argument.partition(",")
            subprocess.run(
                ["xdotool", "mousemove", x.strip(), y.strip()], env=env, check=False
            )
        else:
            raise DemoreelError(
                f"unknown action {action!r} — use wait:SECONDS, type:TEXT, "
                "key:KEYNAME, click:X,Y or move:X,Y"
            )
        _log(f"did {action}")


def _positive_float(value: str, action: str) -> float:
    try:
        seconds = float(value)
    except ValueError:
        raise DemoreelError(f"{action!r}: not a number") from None
    if seconds <= 0:
        raise DemoreelError(f"{action!r}: must be positive")
    return seconds


def _stop(proc: subprocess.Popen[bytes] | None, name: str, *, group: bool = False) -> None:
    """Stop a child, escalating to SIGKILL, and never raise.

    Called from the cleanup path, where a failure to stop one thing must not
    prevent stopping the rest — a leaked Xvfb holds its display number against
    every later run.
    """
    if proc is None or proc.poll() is not None:
        return
    try:
        if group:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
        else:
            proc.terminate()
        proc.wait(timeout=5)
    except Exception:
        try:
            if group:
                os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            else:
                proc.kill()
            proc.wait(timeout=5)
        except Exception as exc:  # pragma: no cover - last resort
            _log(f"warning: could not stop {name}: {exc}")


def record(
    app_command: str,
    out: Path,
    size: str,
    duration: float,
    fps: int,
    actions: list[str],
) -> None:
    _check_tools()
    _parse_size(size)  # fail on a bad size before starting anything

    xvfb = app = recorder = None
    try:
        xvfb, display = _start_display(size)
        app = _launch_app(app_command, display)
        window_id = _wait_for_window(display, app)
        _fit_window(display, window_id, size)
        recorder = _start_recording(display, size, out, fps)

        if actions:
            _run_actions(display, actions)
        else:
            time.sleep(duration)

        # ffmpeg needs a clean 'q' to finalise the container; killing it leaves
        # an unplayable file with no moov atom.
        if recorder.stdin:
            recorder.stdin.write(b"q")
            recorder.stdin.flush()
        try:
            recorder.wait(timeout=20)
        except subprocess.TimeoutExpired:
            _log("warning: ffmpeg did not exit on 'q'; terminating")
            _stop(recorder, "ffmpeg")
        recorder = None
    finally:
        _stop(recorder, "ffmpeg")
        _stop(app, "app", group=True)
        _stop(xvfb, "Xvfb")

    if not out.exists() or out.stat().st_size == 0:
        raise DemoreelError(f"no video was written to {out}")
    _log(f"done: {out} ({out.stat().st_size // 1024} KiB)")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Record a GUI app on a private virtual display.",
        epilog="Actions: wait:SECONDS, type:TEXT, key:KEYNAME, click:X,Y, move:X,Y",
    )
    parser.add_argument("--app", required=True, help="command that launches the app")
    parser.add_argument("--out", required=True, type=Path, help="output video path")
    parser.add_argument("--size", default="1600x1000", help="frame size (default 1600x1000)")
    parser.add_argument(
        "--duration",
        type=float,
        default=20.0,
        help="seconds to record when no --do actions are given (default 20)",
    )
    parser.add_argument("--fps", type=int, default=25, help="frames per second (default 25)")
    parser.add_argument(
        "--do",
        action="append",
        default=[],
        dest="actions",
        metavar="ACTION",
        help="a step to perform while recording; repeatable, in order",
    )
    args = parser.parse_args(argv)

    try:
        record(args.app, args.out, args.size, args.duration, args.fps, args.actions)
    except DemoreelError as exc:
        print(f"demoreel: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("demoreel: interrupted", file=sys.stderr)
        return 130
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

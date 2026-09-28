# fish completion for demoreel (DEMO-0056).
# Install it as ~/.config/fish/completions/demoreel.fish, or
# /usr/share/fish/vendor_completions.d/demoreel.fish.

# The names of recordings still running, for `demoreel stop`. Asked of
# demoreel's own live_runs(), the test `stop` itself uses: every run leaves its
# state file behind, so the files alone would offer finished runs too. Never
# test the run's lock instead -- taking it, even for a moment, can make a run
# starting at that instant refuse to record.
function __demoreel_running
    set -l exe (command -v -- (commandline -opc)[1]); or return
    python3 -c 'import importlib.machinery as m, importlib.util as u, sys
l = m.SourceFileLoader("demoreel", sys.argv[1])
d = u.module_from_spec(u.spec_from_loader("demoreel", l))
l.exec_module(d)
sys.stdout.write("".join(e["name"] + "\n" for e in d.live_runs()))' \
        $exe 2>/dev/null
end

# True once `--` is on the line: everything after it is the app's own command.
function __demoreel_in_app
    contains -- -- (commandline -opc)
end

# Complete the app's command line as fish would on its own. Not
# __fish_complete_subcommand --fcs-skip: that counts only the words that are
# not options, so an option's value such as demo.mp4 throws the count off.
function __demoreel_app
    set -l tokens (commandline -opc)
    set -l app
    set -l at (contains -i -- -- $tokens)
    test $at -lt (count $tokens); and set app (string escape -- $tokens[(math $at + 1)..-1])
    complete -C (string join ' ' -- $app (commandline -ct))
end

function __demoreel_on
    not __demoreel_in_app; and __fish_seen_subcommand_from $argv
end

complete -c demoreel -f
complete -c demoreel -n __demoreel_in_app -x -a '(__demoreel_app)'

complete -c demoreel -n __fish_use_subcommand -s h -l help -d 'show help'
complete -c demoreel -n __fish_use_subcommand -l version -d 'show the version'
complete -c demoreel -n __fish_use_subcommand -a record -d 'record an app and write a video file'
complete -c demoreel -n __fish_use_subcommand -a shot -d 'take one picture of an app and write a PNG'
complete -c demoreel -n __fish_use_subcommand -a check -d 'test whether this machine can record, without recording'
complete -c demoreel -n __fish_use_subcommand -a stop -d 'end a running recording early'

complete -c demoreel -n '__demoreel_on record shot check stop' -s h -l help -d 'show help'

complete -c demoreel -n '__demoreel_on record' -s o -l output -r -F -d 'video file to write'
complete -c demoreel -n '__demoreel_on shot' -s o -l output -r -F -d 'picture file to write'
complete -c demoreel -n '__demoreel_on record' -s d -l duration -x -d 'seconds to record; 0 means until stop'
complete -c demoreel -n '__demoreel_on record' -s r -l framerate -x -d 'frames per second'
complete -c demoreel -n '__demoreel_on record' -s n -l name -x -d 'name for this run'
complete -c demoreel -n '__demoreel_on record shot' -s s -l size -x -d 'virtual display size'
complete -c demoreel -n '__demoreel_on record shot' -s a -l action -x \
    -a "'wait ' 'move ' 'click ' 'type ' 'key ' 'hold '" -d 'scripted step'
complete -c demoreel -n '__demoreel_on record shot' -l app-log -r -F -d "keep the app's own output"
complete -c demoreel -n '__demoreel_on record shot' -l settle -x -d 'wait for the first frame'
complete -c demoreel -n '__demoreel_on record shot' -l gpu -d 'for an app that needs the graphics card'
complete -c demoreel -n '__demoreel_on record shot' -l cursor -d 'show the mouse pointer'
complete -c demoreel -n '__demoreel_on record shot' -l startup-timeout -x -d "how long to wait for the app's window"

complete -c demoreel -n '__demoreel_on stop' -a '(__demoreel_running)' -d 'running recording'

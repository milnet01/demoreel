# demoreel — Schnellstart

**Nehmen Sie ein Video einer laufenden App auf, ohne Ihren Desktop zu filmen.**

Diese Seite zeigt, wie Sie demoreel installieren und eine erste Aufnahme
machen. Die vollständige Anleitung, auf Englisch, ist
[README.md](../../README.md).

## Installation

demoreel ist ein einzelnes Python-3-Skript. Es steuert einige verbreitete
Programme, und jede der unten genannten Distributionen liefert sie alle als
Pakete.

**1. Installieren Sie die Programme, die es steuert.** Eine Zeile, für Ihre
Distribution:

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian und Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

Sie brauchen außerdem `python3` und `git`.

**Unter openSUSE und Fedora kann das ffmpeg der Distribution das Video nicht
schreiben.** Ihm fehlt der H.264-Encoder libx264. Nehmen Sie ffmpeg unter
openSUSE von Packman, unter Fedora von RPM Fusion:

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

Beim ersten Mal fragt zypper, ob es dem Signaturschlüssel von Packman vertrauen
soll. Wählen Sie die Antwort, die ihm immer vertraut.

**2. Holen Sie demoreel, und legen Sie es in Ihren PATH.**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

Meldet die Shell danach, dass sie den Befehl `demoreel` nicht finden kann, dann
ist `~/.local/bin` noch nicht in Ihrem PATH. Fügen Sie diese Zeile in
`~/.bashrc` ein und öffnen Sie ein neues Terminal:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. Prüfen Sie es.**

```sh
demoreel check
```

Es nimmt nichts auf. Es meldet `bereit`, oder es nennt, was fehlt, und den
Befehl, der es installiert.

**Für Apps, die die Grafikkarte brauchen**, benötigt `--gpu` vier weitere
Programme:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian und Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

## Schnellstart

Starten Sie `demoreel` aus einem beliebigen Ordner. Ohne `-o` landet das Video
in dem Ordner, aus dem Sie es starten, benannt nach der App und der Uhrzeit.

```sh
# Kate 30 Sekunden lang aufnehmen, in eine Datei, die nach der App benannt ist
demoreel record -- kate

# den Dateinamen und die Aufnahmedauer selbst wählen
demoreel record -o demo.mp4 -d 20 -- kate

# ansehen, in Ihrem gewohnten Videoplayer
xdg-open demo.mp4

# zeigen, wie die App benutzt wird, statt dass sie nur dasteht
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# aufnehmen, bis Sie Stopp sagen, statt für eine feste Zeit
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...dann, im selben oder einem anderen Terminal:
demoreel stop mydemo
```

`stop` wirkt sofort, sogar in der allernächsten Zeile eines Skripts. Startet
die Aufnahme noch, wartet `stop`, bis sie aufnimmt, und stoppt sie dann. So
bekommen Sie immer ein Video. Danach wartet `stop`, bis das Video fertig und
geprüft ist, und gibt seinen Pfad aus. Schlägt die Aufnahme fehl, vor dem
Aufnehmen oder nach dem Stoppen, gibt `stop` keinen Pfad aus und endet mit
einem Fehler.

**Strg+C tut dasselbe für eine Aufnahme im Vordergrund.** Lassen Sie das `&`
weg, drücken Sie Strg+C, wenn Sie genug haben, und das Video wird fertig
gestellt, geprüft und sein Pfad ausgegeben, genau wie mit `stop`.

Alles nach `--` ist der Befehl, der Ihre App startet, genau so, wie Sie ihn
selbst eintippen würden. demoreel weiß nichts über irgendeine bestimmte App.

Am Ende gibt es eine Zeile aus: den Pfad zu Ihrem Video. Sonst steht nichts in
dieser Zeile, also können Sie sie in einem Skript gefahrlos auffangen. Alles,
was die App selbst ausgibt, erscheint getrennt davon im Terminal, oder mit
`--app-log` in einer Datei.

In einem Terminal sehen Sie außerdem, wie viel Zeit noch bleibt, oder bei einer
Aufnahme mit `-d 0`, wie lange sie schon läuft. Das steht in einer Zeile, die
sich an Ort und Stelle aktualisiert. Sie endet mit der Länge und Größe des
Videos. Nichts davon wird ausgegeben, wenn die Ausgabe an ein Skript oder in
eine Datei geht.

---

Vollständige Dokumentation, auf Englisch: [README.md](../../README.md).
Diese Übersetzung ist ein Entwurf. Wenn Sie eine bessere Formulierung
vorschlagen möchten, lesen Sie [CONTRIBUTING.md](../../CONTRIBUTING.md).

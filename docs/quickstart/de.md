# demoreel — Schnellstart

**Nehmen Sie ein Video einer laufenden App auf, ohne Ihren Desktop zu filmen.**

Diese Seite zeigt, wie Sie demoreel installieren und eine erste Aufnahme
machen. Die vollständige Anleitung, auf Englisch, ist
[README.md](../../README.md).

## Installation

Ab 0.9.0 enthält jede Veröffentlichung ein Paket für Debian, Ubuntu, Fedora,
openSUSE und Arch. Das Paket holt die Programme, die demoreel steuert, aus den
Paketquellen Ihrer Distribution. Es installiert auch die Handbuchseite und die
Tab-Vervollständigung. Für jede andere Distribution lesen Sie
[Installation aus dem Quellcode](../../README.md#install-from-source) (auf
Englisch).

**1. Laden Sie das Paket für Ihre Distribution herunter**, aus der
[neuesten Veröffentlichung](https://github.com/milnet01/demoreel/releases/latest):
die `.deb` für Debian und Ubuntu, die `.rpm` für Fedora und openSUSE, oder den
`PKGBUILD` für Arch.

**2. Installieren Sie es.** Im Ordner, in den Sie es heruntergeladen haben,
eine Zeile für Ihre Distribution:

```sh
# Debian und Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

Das Paket ist nicht signiert. Deshalb braucht openSUSE
`--allow-unsigned-rpm`.

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

**3. Prüfen Sie es.**

```sh
demoreel check
```

Es nimmt nichts auf. Es meldet `bereit`, oder es nennt, was fehlt, und den
Befehl, der es installiert.

**Zum Entfernen** nutzen Sie Ihren Paketmanager:

```sh
# Debian und Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**Für Apps, die die Grafikkarte brauchen**, benötigt `--gpu` vier weitere
Programme. Die Pakete für Debian, Ubuntu, Fedora und openSUSE bringen sie mit.
Unter Arch, oder nach einer Installation aus dem Quellcode, installieren Sie
sie selbst:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
sudo zypper install --from packman --allow-vendor-change libavcodec62
# Debian und Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

**Führen Sie unter openSUSE die Zeile mit `libavcodec62` aus, egal wie Sie
installiert haben.** Sie holt die Videobibliothek von wf-recorder aus Packman,
das oben für ffmpeg hinzugefügt wurde. openSUSEs eigene Fassung davon hat kein
libx264. Lädt wf-recorder eine neuere Bibliothek, nennt `demoreel check`
stattdessen das zu installierende Paket.

**Für Ton** braucht demoreel `pactl`. Damit erreicht der Ton einer aufgenommenen App nie Ihre Lautsprecher, und `--audio` kann diesen Ton ins Video legen:

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian und Ubuntu
sudo apt install pulseaudio-utils
# Fedora
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
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

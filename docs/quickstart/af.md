# demoreel — Vinnige begin

**Neem 'n video op van 'n toep wat loop, sonder om u werkskerm te verfilm.**

Hierdie bladsy wys hoe u demoreel installeer en 'n eerste opname maak. Die
volledige gids, in Engels, is [README.md](../../README.md).

## Installeer

demoreel is een Python 3-skrip. Dit stuur 'n paar algemene programme aan, en
elke distro hieronder verpak hulle almal.

**1. Installeer die programme wat dit aanstuur.** Een reël, vir u distro:

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian en Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

U het ook `python3` en `git` nodig.

**Op openSUSE en Fedora kan die distro se eie ffmpeg nie die video skryf
nie.** Dit laat die H.264-enkodeerder, libx264, weg. Kry ffmpeg van Packman op
openSUSE, of van RPM Fusion op Fedora:

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

Die eerste keer vra zypper of dit Packman se ondertekeningsleutel moet
vertrou. Kies die antwoord wat dit altyd vertrou.

**2. Kry demoreel, en sit dit op u PATH.**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

As die dop dan sê dat dit die opdrag `demoreel` nie kan vind nie, is
`~/.local/bin` nog nie op u PATH nie. Voeg hierdie reël by `~/.bashrc` en maak
'n nuwe terminaal oop:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. Toets dit.**

```sh
demoreel check
```

Dit neem niks op nie. Dit sê `gereed`, of noem wat ontbreek en die opdrag wat
dit installeer.

**Vir toeps wat die grafiese kaart nodig het**, het `--gpu` nog vier programme
nodig:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian en Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

## Vinnige begin

Laat loop `demoreel` vanuit enige gids. Sonder `-o` beland die video in die
gids waaruit u dit laat loop, vernoem na die toep en die tyd.

```sh
# neem Kate 30 sekondes lank op, in 'n lêer wat na die toep vernoem is
demoreel record -- kate

# kies die lêernaam en hoe lank om op te neem
demoreel record -o demo.mp4 -d 20 -- kate

# kyk daarna, in u gewone videospeler
xdg-open demo.mp4

# wys hoe die toep gebruik word, nie net hoe dit daar sit nie
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# neem op totdat u stop sê, eerder as vir 'n vaste tyd
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...dan, in dieselfde of 'n ander terminaal:
demoreel stop mydemo
```

`stop` werk dadelik, selfs op die heel volgende reël van 'n skrip. As die
lopie nog besig is om te begin, wag `stop` totdat dit opneem en stop dit dan,
sodat u altyd 'n video kry. `stop` wag dan totdat die video klaar en
gekontroleer is, en druk sy pad. As die lopie misluk, voordat dit opneem of
nadat dit gestop is, druk `stop` geen pad nie en sluit met 'n fout af.

**Ctrl+C doen dieselfde vir 'n lopie op die voorgrond.** Laat die `&` weg,
druk Ctrl+C wanneer u genoeg het, en die video word klaargemaak, gekontroleer
en sy pad gedruk, presies soos met `stop`.

Alles ná `--` is die opdrag wat u toep begin, presies soos u dit self sou
tik. demoreel weet niks van enige spesifieke toep nie.

Wanneer dit klaar is, druk dit een reël: die pad na u video. Niks anders kom
op daardie reël nie, so u kan dit veilig in 'n skrip opvang. Enigiets wat die
toep self druk, gaan apart na die terminaal, of na 'n lêer met `--app-log`.

By 'n terminaal sien u ook hoe lank oorbly, of by 'n `-d 0`-lopie hoe lank dit
al loop, op een reël wat ter plaatse bygewerk word. Dit eindig met die video
se lengte en grootte. Niks hiervan word gedruk wanneer die uitvoer na 'n skrip
of 'n lêer gaan nie.

---

Volledige dokumentasie, in Engels: [README.md](../../README.md). Hierdie
vertaling is 'n konsep. Om 'n beter bewoording voor te stel, sien
[CONTRIBUTING.md](../../CONTRIBUTING.md).

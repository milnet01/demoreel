# demoreel — Snel aan de slag

**Neem een video op van een app die draait, zonder uw bureaublad te filmen.**

Deze pagina laat zien hoe u demoreel installeert en een eerste opname maakt.
De volledige handleiding, in het Engels, is [README.md](../../README.md).

## Installeren

Vanaf 0.9.0 heeft elke release een pakket voor Debian, Ubuntu, Fedora,
openSUSE en Arch. Het pakket haalt de programma's die demoreel aanstuurt uit
de eigen softwarebronnen van uw distributie. Het installeert ook de
handleidingpagina en het aanvullen met Tab. Voor een andere distributie, zie
[Installeren vanaf de broncode](../../README.md#install-from-source) (in het
Engels).

**1. Download het pakket voor uw distributie** van de
[nieuwste release](https://github.com/milnet01/demoreel/releases/latest): de
`.deb` voor Debian en Ubuntu, de `.rpm` voor Fedora en openSUSE, of de
`PKGBUILD` voor Arch.

**2. Installeer het.** In de map waarin u het hebt gedownload, één regel voor
uw distributie:

```sh
# Debian en Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

Het pakket is niet ondertekend. Daarom heeft openSUSE
`--allow-unsigned-rpm` nodig.

**Op openSUSE en Fedora kan de eigen ffmpeg van de distributie de video niet
schrijven.** Daar ontbreekt de H.264-encoder, libx264. Neem ffmpeg van Packman
op openSUSE, of van RPM Fusion op Fedora:

```sh
# openSUSE Tumbleweed
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# openSUSE Leap 16.0
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_16.0/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

De eerste keer vraagt zypper of u de ondertekeningssleutel van Packman
vertrouwt. Kies het antwoord dat de sleutel altijd vertrouwt.

**3. Controleer het.**

```sh
demoreel check
```

Dit neemt niets op. Het meldt `gereed`, of noemt wat er ontbreekt en de
opdracht die het installeert.

**Om het te verwijderen** gebruikt u uw pakketbeheerder:

```sh
# Debian en Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**Voor apps die de grafische kaart nodig hebben** heeft `--gpu` nog vier
programma's nodig. De pakketten voor Debian, Ubuntu, Fedora en openSUSE
brengen ze mee. Op Arch, of na een installatie vanaf de broncode, installeert
u ze zelf:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
sudo zypper install --from packman --allow-vendor-change libavcodec62
# Debian en Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
# Mageia, dat geen pakket heeft voor cage, wlr-randr of wf-recorder
sudo dnf install x11-server-xwayland
```

**Voer op openSUSE de regel met `libavcodec62` uit, hoe u ook installeerde.**
Die haalt de videobibliotheek van wf-recorder uit Packman, hierboven voor
ffmpeg toegevoegd. De eigen versie van openSUSE heeft geen libx264. Laadt
wf-recorder een nieuwere bibliotheek, dan noemt `demoreel check` in plaats
daarvan het pakket om te installeren.

**Voor geluid** heeft demoreel `pactl` nodig. Daarmee bereikt het geluid van een opgenomen app nooit uw luidsprekers, en kan `--audio` dat geluid in de video zetten:

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian en Ubuntu
sudo apt install pulseaudio-utils
# Fedora en Mageia
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
```

## Snel aan de slag

Start `demoreel` vanuit elke map. Zonder `-o` komt de video in de map waar u
het start, met de naam van de app en de tijd.

```sh
# neem Kate 30 seconden op, in een bestand met de naam van de app
demoreel record -- kate

# kies de bestandsnaam en hoe lang er wordt opgenomen
demoreel record -o demo.mp4 -d 20 -- kate

# bekijk het in uw gewone videospeler
xdg-open demo.mp4

# laat zien hoe de app wordt gebruikt, niet alleen hoe hij stilstaat
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# opnemen tot u stop zegt, in plaats van een vaste tijd
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...en dan, in dezelfde of een andere terminal:
demoreel stop mydemo
```

`stop` werkt meteen, zelfs op de eerstvolgende regel van een script. Is de
opname nog aan het opstarten, dan wacht `stop` tot er wordt opgenomen en stopt
de opname dan, zodat u altijd een video krijgt. Daarna wacht `stop` tot de
video klaar en gecontroleerd is, en toont het pad ervan. Mislukt de opname,
voordat er wordt opgenomen of nadat ze is gestopt, dan toont `stop` geen pad
en eindigt het met een fout.

**Ctrl+C doet hetzelfde voor een opname op de voorgrond.** Laat de `&` weg,
druk op Ctrl+C als u genoeg hebt, en de video wordt afgemaakt en
gecontroleerd en het pad wordt getoond, precies zoals met `stop`.

Alles na `--` is de opdracht die uw app start, precies zoals u die zelf zou
typen. demoreel weet niets over een bepaalde app.

Als het klaar is, toont het één regel: het pad naar uw video. Verder staat er
niets op die regel, dus u kunt hem veilig in een script opvangen. Alles wat de
app zelf toont, gaat apart naar de terminal, of naar een bestand met
`--app-log`.

In een terminal ziet u ook hoe lang het nog duurt, of bij een opname met
`-d 0` hoe lang ze al loopt, op één regel die zichzelf bijwerkt. Die eindigt
met de lengte en de grootte van de video. Niets hiervan wordt getoond als de
uitvoer naar een script of een bestand gaat.

---

Volledige documentatie, in het Engels: [README.md](../../README.md). Deze
vertaling is een concept. Wilt u een betere formulering voorstellen, zie dan
[CONTRIBUTING.md](../../CONTRIBUTING.md).

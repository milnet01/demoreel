# demoreel — Szybki start

**Nagrywanie filmu z działającego programu bez filmowania pulpitu.**

Ta strona pokazuje, jak zainstalować demoreel i wykonać pierwsze nagranie.
Pełny przewodnik, po angielsku, to [README.md](../../README.md).

## Instalacja

Od wersji 0.9.0 każde wydanie zawiera pakiet dla Debiana, Ubuntu, Fedory,
openSUSE i Archa. Pakiet pobiera programy, z których korzysta demoreel, z
własnych repozytoriów dystrybucji. Instaluje też stronę podręcznika man i
uzupełnianie klawiszem Tab. Dla innych dystrybucji zobacz
[Instalacja ze źródeł](../../README.md#install-from-source) (po angielsku).

**1. Pobranie pakietu dla danej dystrybucji** z
[najnowszego wydania](https://github.com/milnet01/demoreel/releases/latest):
`.deb` dla Debiana i Ubuntu, `.rpm` dla Fedory i openSUSE albo `PKGBUILD`
dla Archa.

**2. Instalacja.** W folderze, do którego pobrano pakiet, jeden wiersz dla
danej dystrybucji:

```sh
# Debian i Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

Pakiet nie jest podpisany. Dlatego openSUSE wymaga
`--allow-unsigned-rpm`.

**W openSUSE i Fedorze własny ffmpeg dystrybucji nie potrafi zapisać filmu.**
Brakuje w nim kodera H.264, czyli libx264. ffmpeg należy wziąć z Packman w
openSUSE albo z RPM Fusion w Fedorze:

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

Za pierwszym razem zypper zapyta, czy ufać kluczowi podpisu Packman. Należy
wybrać odpowiedź, która ufa mu zawsze.

**3. Sprawdzenie.**

```sh
demoreel check
```

Niczego nie nagrywa. Wypisuje `gotowe` albo podaje, czego brakuje, i
polecenie, które to instaluje.

**Aby go usunąć**, należy użyć menedżera pakietów:

```sh
# Debian i Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**Dla programów, które potrzebują karty graficznej**, `--gpu` wymaga
czterech dodatkowych programów. Pakiety dla Debiana, Ubuntu, Fedory i
openSUSE instalują je same. W Archu albo po instalacji ze źródeł należy
zainstalować je samodzielnie:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
sudo zypper install --from packman --allow-vendor-change libavcodec62
# Debian i Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

**W openSUSE należy uruchomić wiersz z `libavcodec62`, niezależnie od sposobu
instalacji.** Pobiera on bibliotekę wideo wf-recordera z Packmana, dodanego
wyżej dla ffmpeg. Własna wersja openSUSE nie ma libx264. Jeśli wf-recorder
wczytuje nowszą bibliotekę, `demoreel check` poda zamiast tego pakiet do
zainstalowania.

**Do dźwięku** demoreel potrzebuje `pactl`. Dzięki niemu dźwięk nagrywanej aplikacji nigdy nie trafia do twoich głośników, a `--audio` może umieścić ten dźwięk w filmie:

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian i Ubuntu
sudo apt install pulseaudio-utils
# Fedora
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
```

## Szybki start

`demoreel` można uruchomić z dowolnego katalogu. Bez `-o` film trafia do
katalogu, z którego go uruchomiono, i otrzymuje nazwę od programu i godziny.

```sh
# nagraj Kate przez 30 sekund, do pliku nazwanego od programu
demoreel record -- kate

# wybierz nazwę pliku i czas nagrania
demoreel record -o demo.mp4 -d 20 -- kate

# obejrzyj go w zwykłym odtwarzaczu wideo
xdg-open demo.mp4

# pokaż program w użyciu, a nie tylko bezczynny
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# nagrywaj aż do polecenia stop, a nie przez ustalony czas
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...potem, w tym samym albo innym terminalu:
demoreel stop mydemo
```

`stop` działa od razu, nawet w następnym wierszu skryptu. Jeśli
uruchomienie jeszcze się rozpoczyna, `stop` czeka, aż zacznie nagrywać, i
dopiero wtedy je zatrzymuje, więc film powstaje zawsze. Następnie `stop`
czeka, aż film zostanie dokończony i sprawdzony, i wypisuje jego ścieżkę.
Jeśli uruchomienie się nie powiedzie,
przed nagrywaniem albo po zatrzymaniu, `stop` nie wypisuje ścieżki i kończy
się błędem.

**Ctrl+C działa tak samo dla uruchomienia na pierwszym planie.** Wystarczy
pominąć `&` i nacisnąć Ctrl+C, gdy nagrania jest dość: film zostanie
dokończony i sprawdzony, a jego ścieżka wypisana, dokładnie jak przy `stop`.

Wszystko po `--` to polecenie uruchamiające program, dokładnie tak, jak
wpisuje się je samodzielnie. demoreel nie wie nic o żadnym konkretnym
programie.

Na koniec demoreel wypisuje jeden wiersz: ścieżkę do filmu. Nic innego nie
trafia do tego wiersza, więc można go bezpiecznie przechwycić w skrypcie.
Wszystko, co wypisuje sam program, trafia osobno do terminala albo, z
`--app-log`, do pliku.

W terminalu widać też, ile czasu zostało, a przy uruchomieniu z `-d 0` — jak
długo już trwa, w jednym wierszu, który odświeża się w miejscu. Na końcu
pojawia się długość i rozmiar filmu. Nic z tego nie jest wypisywane, gdy
wyjście trafia do skryptu albo do pliku.

---

Pełna dokumentacja, po angielsku: [README.md](../../README.md). To
tłumaczenie jest wersją roboczą. Aby zaproponować lepsze sformułowanie,
proszę zajrzeć do [CONTRIBUTING.md](../../CONTRIBUTING.md).

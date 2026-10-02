# demoreel — Szybki start

**Nagrywanie filmu z działającego programu bez filmowania pulpitu.**

Ta strona pokazuje, jak zainstalować demoreel i wykonać pierwsze nagranie.
Pełny przewodnik, po angielsku, to [README.md](../../README.md).

## Instalacja

demoreel to jeden skrypt w Pythonie 3. Korzysta z kilku popularnych
programów, a każda z poniższych dystrybucji udostępnia je wszystkie w
pakietach.

**1. Instalacja programów, z których korzysta.** Jeden wiersz dla danej
dystrybucji:

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian i Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

Potrzebne są też `python3` i `git`.

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

**2. Pobranie demoreel i dodanie go do PATH.**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

Jeśli powłoka odpowie potem, że nie może znaleźć polecenia `demoreel`, to
`~/.local/bin` nie jest jeszcze w PATH. Należy dodać ten wiersz do
`~/.bashrc` i otworzyć nowy terminal:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. Sprawdzenie.**

```sh
demoreel check
```

Niczego nie nagrywa. Wypisuje `gotowe` albo podaje, czego brakuje, i
polecenie, które to instaluje.

**Dla programów, które potrzebują karty graficznej**, `--gpu` wymaga
czterech dodatkowych programów:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian i Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
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

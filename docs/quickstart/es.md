# demoreel — Inicio rápido

**Grabe un vídeo de una aplicación en marcha, sin filmar su escritorio.**

Esta página explica cómo instalar demoreel y hacer una primera grabación. La
guía completa, en inglés, es [README.md](../../README.md).

## Instalación

Desde la 0.9.0, cada versión trae un paquete para Debian, Ubuntu, Fedora,
openSUSE y Arch. El paquete trae los programas que usa demoreel desde los
repositorios de su propia distribución. También instala la página de manual y
el autocompletado con el tabulador. Para cualquier otra distribución, vea
[Instalar desde el código fuente](../../README.md#install-from-source) (en
inglés).

**1. Descargue el paquete para su distribución** desde la
[última versión](https://github.com/milnet01/demoreel/releases/latest): el
`.deb` para Debian y Ubuntu, el `.rpm` para Fedora y openSUSE, o el
`PKGBUILD` para Arch.

**2. Instálelo.** En la carpeta donde lo descargó, una línea para su
distribución:

```sh
# Debian y Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

El paquete no está firmado. Por eso openSUSE necesita
`--allow-unsigned-rpm`.

**En openSUSE y Fedora, el ffmpeg de la propia distribución no puede escribir
el vídeo.** Le falta el codificador H.264, libx264. Instale ffmpeg desde
Packman en openSUSE, o desde RPM Fusion en Fedora:

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

La primera vez, zypper pregunta si debe confiar en la clave de firma de
Packman. Elija la opción que confía en ella siempre.

**3. Compruébelo.**

```sh
demoreel check
```

No graba nada. Dice `listo`, o indica qué falta y la orden que lo instala.

**Para quitarlo**, use su gestor de paquetes:

```sh
# Debian y Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**Para aplicaciones que necesitan la tarjeta gráfica**, `--gpu` necesita
cuatro programas más. Los paquetes de Debian, Ubuntu, Fedora y openSUSE los
traen. En Arch, o tras instalar desde el código fuente, instálelos usted
mismo:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
sudo zypper install --from packman --allow-vendor-change libavcodec62
# Debian y Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
# Mageia, que no tiene paquete para cage, wlr-randr ni wf-recorder
sudo dnf install x11-server-xwayland
```

**En openSUSE, ejecute la línea de `libavcodec62` sea cual sea la forma en que
instaló.** Toma la biblioteca de vídeo de wf-recorder de Packman, añadido
arriba para ffmpeg. La versión propia de openSUSE no tiene libx264. Si
wf-recorder carga una biblioteca más nueva, `demoreel check` indica en su lugar
el paquete que hay que instalar.

**Para el sonido**, demoreel necesita `pactl`. Con él, el sonido de una app grabada nunca llega a sus altavoces, y `--audio` puede poner ese sonido en el vídeo:

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian y Ubuntu
sudo apt install pulseaudio-utils
# Fedora y Mageia
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
```

## Inicio rápido

Ejecute `demoreel` desde cualquier carpeta. Sin `-o`, el vídeo se guarda en la
carpeta desde la que lo ejecuta, con el nombre de la aplicación y la hora.

```sh
# grabar Kate durante 30 segundos, en un archivo con el nombre de la aplicación
demoreel record -- kate

# elegir el nombre del archivo y cuánto tiempo grabar
demoreel record -o demo.mp4 -d 20 -- kate

# verlo en su reproductor de vídeo habitual
xdg-open demo.mp4

# mostrar la aplicación en uso, no solo abierta
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# grabar hasta que usted diga basta, en lugar de un tiempo fijo
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...y después, en el mismo terminal o en otro:
demoreel stop mydemo
```

`stop` funciona de inmediato, incluso en la línea siguiente de un script. Si la
grabación aún se está iniciando, `stop` espera a que esté grabando y entonces
la detiene, así que siempre obtiene un vídeo. Después `stop` espera a que el
vídeo esté terminado y comprobado, e imprime su ruta. Si la grabación falla,
antes de grabar o después de detenerse, `stop` no imprime ninguna ruta y
termina con un error.

**Ctrl+C hace lo mismo con una grabación en primer plano.** Omita el `&`, pulse
Ctrl+C cuando tenga suficiente, y el vídeo se termina, se comprueba y se
imprime su ruta, igual que con `stop`.

Todo lo que va después de `--` es la orden que inicia su aplicación, tal como
la escribiría usted. demoreel no sabe nada de ninguna aplicación concreta.

Al terminar imprime una línea: la ruta de su vídeo. En esa línea no va nada
más, así que puede capturarla sin problema en un script. Lo que imprima la
propia aplicación va al terminal por separado, o a un archivo con `--app-log`.

En un terminal también ve cuánto tiempo queda, o, en una grabación con `-d 0`,
cuánto tiempo lleva, en una línea que se actualiza en su sitio. Termina con la
duración y el tamaño del vídeo. Nada de esto se imprime cuando la salida va a
un script o a un archivo.

---

Documentación completa, en inglés: [README.md](../../README.md). Esta
traducción es un borrador. Para proponer una redacción mejor, consulte
[CONTRIBUTING.md](../../CONTRIBUTING.md).

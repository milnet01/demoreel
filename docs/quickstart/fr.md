# demoreel — Démarrage rapide

**Enregistrer une vidéo d'une application en cours d'exécution, sans filmer votre bureau.**

Cette page explique comment installer demoreel et faire un premier
enregistrement. Le guide complet, en anglais, est [README.md](../../README.md).

## Installation

À partir de la version 0.9.0, chaque version fournit un paquet pour Debian,
Ubuntu, Fedora, openSUSE et Arch. Le paquet installe les programmes que
demoreel pilote, depuis les dépôts de votre distribution. Il installe aussi la
page de manuel et la complétion par tabulation. Pour toute autre distribution,
voir [Installer depuis les sources](../../README.md#install-from-source) (en
anglais).

**1. Téléchargez le paquet pour votre distribution** depuis la
[dernière version](https://github.com/milnet01/demoreel/releases/latest) : le
`.deb` pour Debian et Ubuntu, le `.rpm` pour Fedora et openSUSE, ou le
`PKGBUILD` pour Arch.

**2. Installez-le.** Dans le dossier où vous l'avez téléchargé, une ligne pour
votre distribution :

```sh
# Debian et Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

Le paquet n'est pas signé. C'est pourquoi openSUSE a besoin de
`--allow-unsigned-rpm`.

**Sur openSUSE et Fedora, le ffmpeg de la distribution ne peut pas écrire la
vidéo.** Il ne contient pas l'encodeur H.264, libx264. Prenez ffmpeg chez
Packman sur openSUSE, ou chez RPM Fusion sur Fedora :

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

La première fois, zypper demande s'il faut faire confiance à la clé de
signature de Packman. Répondez par le choix qui lui fait toujours confiance.

**3. Vérifiez.**

```sh
demoreel check
```

Cette commande n'enregistre rien. Elle affiche `prêt`, ou indique ce qui
manque et la commande qui l'installe.

**Pour le désinstaller**, utilisez votre gestionnaire de paquets :

```sh
# Debian et Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**Pour les applications qui ont besoin de la carte graphique**, `--gpu`
nécessite quatre programmes de plus. Les paquets Debian, Ubuntu, Fedora et
openSUSE les installent. Sur Arch, ou après une installation depuis les
sources, installez-les vous-même :

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
sudo zypper install --from packman --allow-vendor-change libavcodec62
# Debian et Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

**Sur openSUSE, exécutez la ligne `libavcodec62`, quelle que soit la façon dont
vous avez installé.** Elle prend chez Packman, ajouté plus haut pour ffmpeg, la
bibliothèque vidéo de wf-recorder. La version d'openSUSE n'a pas libx264. Si
wf-recorder charge une bibliothèque plus récente, `demoreel check` nomme à la
place le paquet à installer.

**Pour le son**, demoreel a besoin de `pactl`. Avec lui, le son d'une app enregistrée n'atteint jamais vos haut-parleurs, et `--audio` peut mettre ce son dans la vidéo :

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian et Ubuntu
sudo apt install pulseaudio-utils
# Fedora
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
```

## Démarrage rapide

Lancez `demoreel` depuis n'importe quel dossier. Sans `-o`, la vidéo arrive
dans le dossier d'où vous le lancez, nommée d'après l'application et l'heure.

```sh
# enregistrer Kate pendant 30 secondes, dans un fichier nommé d'après l'application
demoreel record -- kate

# choisir le nom du fichier et la durée de l'enregistrement
demoreel record -o demo.mp4 -d 20 -- kate

# la regarder, dans votre lecteur vidéo habituel
xdg-open demo.mp4

# montrer l'application en cours d'utilisation, pas seulement à l'arrêt
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# enregistrer jusqu'à ce que vous disiez stop, plutôt que pendant une durée fixe
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...puis, dans le même terminal ou un autre :
demoreel stop mydemo
```

`stop` fonctionne tout de suite, même à la ligne suivante d'un script. Si la
session est encore en train de démarrer, `stop` attend qu'elle enregistre, puis
l'arrête : vous obtenez donc toujours une vidéo. `stop` attend ensuite que la
vidéo soit terminée et vérifiée, et affiche son chemin. Si la session échoue,
avant d'enregistrer ou après avoir été arrêtée, `stop` n'affiche aucun chemin
et se termine avec une erreur.

**Ctrl+C fait la même chose pour une session au premier plan.** Omettez le
`&`, appuyez sur Ctrl+C quand vous en avez assez, et la vidéo est terminée,
vérifiée et son chemin affiché, exactement comme avec `stop`.

Tout ce qui suit `--` est la commande qui lance votre application, exactement
comme vous la taperiez vous-même. demoreel ne sait rien d'aucune application
en particulier.

Quand il a fini, il affiche une seule ligne : le chemin de votre vidéo. Rien
d'autre ne figure sur cette ligne, vous pouvez donc la récupérer sans risque
dans un script. Tout ce que l'application affiche elle-même va séparément au
terminal, ou dans un fichier avec `--app-log`.

Dans un terminal, vous voyez aussi le temps restant, ou, pour une session
`-d 0`, depuis combien de temps elle tourne, sur une ligne qui se met à jour
sur place. Elle se termine par la durée et la taille de la vidéo. Rien de tout
cela n'est affiché quand la sortie va vers un script ou un fichier.

---

Documentation complète, en anglais : [README.md](../../README.md). Cette
traduction est un brouillon. Pour proposer une meilleure formulation, consultez
[CONTRIBUTING.md](../../CONTRIBUTING.md).

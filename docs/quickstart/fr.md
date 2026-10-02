# demoreel — Démarrage rapide

**Enregistrer une vidéo d'une application en cours d'exécution, sans filmer votre bureau.**

Cette page explique comment installer demoreel et faire un premier
enregistrement. Le guide complet, en anglais, est [README.md](../../README.md).

## Installation

demoreel est un seul script Python 3. Il pilote quelques programmes courants,
et chaque distribution ci-dessous les fournit tous.

**1. Installez les programmes qu'il pilote.** Une ligne, pour votre
distribution :

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian et Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

Il vous faut aussi `python3` et `git`.

**Sur openSUSE et Fedora, le ffmpeg de la distribution ne peut pas écrire la
vidéo.** Il ne contient pas l'encodeur H.264, libx264. Prenez ffmpeg chez
Packman sur openSUSE, ou chez RPM Fusion sur Fedora :

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

La première fois, zypper demande s'il faut faire confiance à la clé de
signature de Packman. Répondez par le choix qui lui fait toujours confiance.

**2. Récupérez demoreel et placez-le dans votre PATH.**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

Si le shell indique ensuite qu'il ne trouve pas la commande `demoreel`,
`~/.local/bin` n'est pas encore dans votre PATH. Ajoutez cette ligne à
`~/.bashrc` et ouvrez un nouveau terminal :

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. Vérifiez.**

```sh
demoreel check
```

Cette commande n'enregistre rien. Elle affiche `prêt`, ou indique ce qui
manque et la commande qui l'installe.

**Pour les applications qui ont besoin de la carte graphique**, `--gpu`
nécessite quatre programmes de plus :

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian et Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
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

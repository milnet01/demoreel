# demoreel — Guida rapida

**Registrare un video di un'app in esecuzione, senza filmare il proprio desktop.**

Questa pagina mostra come installare demoreel e fare una prima registrazione.
La guida completa, in inglese, è [README.md](../../README.md).

## Installazione

Dalla 0.9.0 in poi, ogni versione offre un pacchetto per Debian, Ubuntu,
Fedora, openSUSE e Arch. Il pacchetto porta i programmi a cui demoreel si
appoggia, dai repository della propria distribuzione. Installa anche la pagina
di manuale e il completamento con il tasto Tab. Per ogni altra distribuzione,
vedere [Installare dai sorgenti](../../README.md#install-from-source) (in
inglese).

**1. Scaricare il pacchetto per la propria distribuzione** dall'[ultima
versione](https://github.com/milnet01/demoreel/releases/latest): il `.deb` per
Debian e Ubuntu, l'`.rpm` per Fedora e openSUSE, oppure il `PKGBUILD` per Arch.

**2. Installarlo.** Nella cartella in cui è stato scaricato, una riga per la
propria distribuzione:

```sh
# Debian e Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

Il pacchetto non è firmato. Per questo openSUSE ha bisogno di
`--allow-unsigned-rpm`.

**Su openSUSE e Fedora, l'ffmpeg della distribuzione non può scrivere il
video.** Gli manca il codificatore H.264, libx264. Si prenda ffmpeg da Packman
su openSUSE, oppure da RPM Fusion su Fedora:

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

La prima volta zypper chiede se fidarsi della chiave di firma di Packman.
Rispondere con la scelta che la considera sempre affidabile.

**3. Verificarlo.**

```sh
demoreel check
```

Non registra nulla. Dice `pronto`, oppure indica cosa manca e il comando che
lo installa.

**Per rimuoverlo**, usare il proprio gestore di pacchetti:

```sh
# Debian e Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**Per le app che hanno bisogno della scheda grafica**, `--gpu` richiede altri
quattro programmi. I pacchetti per Debian, Ubuntu, Fedora e openSUSE li
portano. Su Arch, o dopo un'installazione dai sorgenti, installarli a mano:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian e Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

**Su openSUSE, `record --gpu` non può ancora scrivere il video.** Il
wf-recorder di openSUSE carica la libreria video di openSUSE, che non ha
libx264. `demoreel check` lo segnala, e dice che `--gpu` non è pronto.

**Per il suono** demoreel ha bisogno di `pactl`. Con esso il suono di un'app registrata non arriva mai agli altoparlanti, e `--audio` può mettere quel suono nel video:

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian e Ubuntu
sudo apt install pulseaudio-utils
# Fedora
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
```

## Guida rapida

`demoreel` si può avviare da qualsiasi cartella. Senza `-o`, il video finisce
nella cartella da cui lo si avvia, con un nome fatto dall'app e dall'ora.

```sh
# registrare Kate per 30 secondi, in un file con il nome dell'app
demoreel record -- kate

# scegliere il nome del file e quanto a lungo registrare
demoreel record -o demo.mp4 -d 20 -- kate

# guardarlo, nel solito lettore video
xdg-open demo.mp4

# mostrare l'app mentre viene usata, non solo ferma lì
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# registrare finché non la si ferma, invece che per un tempo fisso
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...poi, nello stesso terminale o in un altro:
demoreel stop mydemo
```

`stop` funziona subito, anche sulla riga immediatamente successiva di uno
script. Se l'esecuzione si sta ancora avviando, `stop` aspetta che stia
registrando e poi la ferma, così si ottiene sempre un video. Poi `stop` aspetta
che il video sia finito e controllato, e ne stampa il percorso. Se l'esecuzione
non riesce, prima di registrare o dopo essere stata fermata, `stop` non stampa
alcun percorso ed esce con un errore.

**Ctrl+C fa lo stesso per un'esecuzione in primo piano.** Si tolga la `&`, si
prema Ctrl+C quando basta, e il video viene finito, controllato e il suo
percorso stampato, esattamente come con `stop`.

Tutto ciò che segue `--` è il comando che avvia la propria app, esattamente come
lo si scriverebbe a mano. demoreel non sa nulla di nessuna app in particolare.

Alla fine stampa una sola riga: il percorso del video. Su quella riga non c'è
nient'altro, quindi la si può catturare senza rischi in uno script. Tutto ciò
che stampa l'app stessa va al terminale separatamente, oppure in un file con
`--app-log`.

In un terminale si vede anche quanto tempo manca, o in un'esecuzione con `-d 0`
da quanto tempo è in corso, su una riga che si aggiorna sul posto. Termina con
la durata e la dimensione del video. Niente di tutto questo viene stampato
quando l'output va a uno script o a un file.

---

Documentazione completa, in inglese: [README.md](../../README.md). Questa
traduzione è una bozza. Per suggerire una formulazione migliore, vedere
[CONTRIBUTING.md](../../CONTRIBUTING.md).

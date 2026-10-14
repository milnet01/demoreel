# demoreel — Primeiros passos

**Grave um vídeo de um aplicativo em execução, sem filmar a sua área de trabalho.**

Esta página mostra como instalar o demoreel e fazer a primeira gravação. O guia completo, em inglês, é o [README.md](../../README.md).

## Instalação

A partir da 0.9.0, cada versão traz um pacote para Debian, Ubuntu, Fedora,
openSUSE e Arch. O pacote traz os programas que o demoreel comanda dos
repositórios da própria distribuição. Ele também instala a página de manual e
o completamento com Tab. Para outras distribuições, veja
[Instalar a partir do código-fonte](../../README.md#install-from-source) (em
inglês).

**1. Baixe o pacote para a sua distribuição** na
[versão mais recente](https://github.com/milnet01/demoreel/releases/latest): o
`.deb` para Debian e Ubuntu, o `.rpm` para Fedora e openSUSE, ou o
`PKGBUILD` para Arch.

**2. Instale-o.** Na pasta onde você o baixou, uma linha para a sua
distribuição:

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

O pacote não é assinado. Por isso o openSUSE precisa de
`--allow-unsigned-rpm`.

**No openSUSE e no Fedora, o ffmpeg da própria distribuição não consegue
gravar o vídeo.** Ele deixa de fora o codificador H.264, libx264. Instale o
ffmpeg do Packman no openSUSE, ou do RPM Fusion no Fedora:

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

Na primeira vez, o zypper pergunta se deve confiar na chave de assinatura do
Packman. Responda com a opção que confia nela sempre.

**3. Verifique.**

```sh
demoreel check
```

Ele não grava nada. Ele diz `pronto`, ou informa o que está faltando e o
comando que o instala.

**Para removê-lo**, use o seu gerenciador de pacotes:

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

**Para aplicativos que precisam da placa de vídeo**, o `--gpu` precisa de
mais quatro programas. Os pacotes para Debian, Ubuntu, Fedora e openSUSE os
trazem. No Arch, ou depois de uma instalação a partir do código-fonte,
instale-os você mesmo:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
sudo zypper install --from packman --allow-vendor-change libavcodec62
# Debian e Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
# Mageia, que não tem pacote para cage, wlr-randr nem wf-recorder
sudo dnf install x11-server-xwayland
```

**No openSUSE, execute a linha do `libavcodec62` seja qual for a forma de
instalação.** Ela pega a biblioteca de vídeo do wf-recorder do Packman,
adicionado acima para o ffmpeg. A versão do próprio openSUSE não tem libx264.
Se o wf-recorder carregar uma biblioteca mais nova, o `demoreel check` indica o
pacote a instalar no lugar dela.

**Para o som**, o demoreel precisa do `pactl`. Com ele, o som de um app gravado nunca chega aos seus alto-falantes, e `--audio` pode colocar esse som no vídeo:

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian e Ubuntu
sudo apt install pulseaudio-utils
# Fedora e Mageia
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
```

## Primeiros passos

Execute o `demoreel` a partir de qualquer pasta. Sem `-o`, o vídeo vai para a
pasta de onde você o executou, com o nome do aplicativo e a hora.

```sh
# grave o Kate por 30 segundos, num arquivo com o nome do aplicativo
demoreel record -- kate

# escolha o nome do arquivo e quanto tempo gravar
demoreel record -o demo.mp4 -d 20 -- kate

# assista, no seu reprodutor de vídeo de costume
xdg-open demo.mp4

# mostre o aplicativo sendo usado, não apenas parado
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# grave até você mandar parar, em vez de por um tempo fixo
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...depois, no mesmo terminal ou em outro:
demoreel stop mydemo
```

O `stop` funciona na hora, mesmo na linha seguinte de um script. Se a
execução ainda estiver começando, o `stop` espera até que ela esteja gravando
e então a para, para que você sempre receba um vídeo. Depois, o `stop` espera
o vídeo ser concluído e verificado, e mostra o caminho dele. Se a execução
falhar, antes de gravar ou depois de parada, o `stop` não mostra caminho
nenhum e termina com um erro.

**Ctrl+C faz o mesmo para uma execução em primeiro plano.** Deixe de fora o
`&`, pressione Ctrl+C quando tiver o suficiente, e o vídeo é concluído,
verificado e o caminho dele é mostrado, exatamente como com o `stop`.

Tudo o que vem depois de `--` é o comando que abre o seu aplicativo,
exatamente como você mesmo o digitaria. O demoreel não sabe nada sobre
nenhum aplicativo em particular.

Quando termina, ele mostra uma linha: o caminho do seu vídeo. Nada mais vai
nessa linha, então você pode capturá-la com segurança num script. O que o
próprio aplicativo mostrar vai para o terminal separadamente, ou para um
arquivo com `--app-log`.

Num terminal, você também vê quanto tempo falta, ou, numa execução com
`-d 0`, há quanto tempo ela está rodando, numa linha que se atualiza no
lugar. Ela termina com a duração e o tamanho do vídeo. Nada disso é mostrado
quando a saída vai para um script ou um arquivo.

---

Documentação completa, em inglês: [README.md](../../README.md). Esta
tradução é um rascunho. Para sugerir uma redação melhor, veja o
[CONTRIBUTING.md](../../CONTRIBUTING.md).

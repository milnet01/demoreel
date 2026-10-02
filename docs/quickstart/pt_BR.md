# demoreel — Primeiros passos

**Grave um vídeo de um aplicativo em execução, sem filmar a sua área de trabalho.**

Esta página mostra como instalar o demoreel e fazer a primeira gravação. O guia completo, em inglês, é o [README.md](../../README.md).

## Instalação

O demoreel é um único script em Python 3. Ele comanda alguns programas
comuns, e cada distribuição abaixo empacota todos eles.

**1. Instale os programas que ele comanda.** Uma linha, para a sua
distribuição:

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian e Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

Você também precisa de `python3` e `git`.

**No openSUSE e no Fedora, o ffmpeg da própria distribuição não consegue
gravar o vídeo.** Ele deixa de fora o codificador H.264, libx264. Instale o
ffmpeg do Packman no openSUSE, ou do RPM Fusion no Fedora:

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

Na primeira vez, o zypper pergunta se deve confiar na chave de assinatura do
Packman. Responda com a opção que confia nela sempre.

**2. Baixe o demoreel e coloque-o no seu PATH.**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

Se o shell disser em seguida que não encontra o comando `demoreel`,
`~/.local/bin` ainda não está no seu PATH. Acrescente esta linha ao
`~/.bashrc` e abra um novo terminal:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. Verifique.**

```sh
demoreel check
```

Ele não grava nada. Ele diz `pronto`, ou informa o que está faltando e o
comando que o instala.

**Para aplicativos que precisam da placa de vídeo**, o `--gpu` precisa de
mais quatro programas:

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

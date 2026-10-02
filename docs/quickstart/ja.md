# demoreel — クイックスタート

**デスクトップを映さずに、動いているアプリを動画に録画します。**

このページでは、demoreel をインストールして最初の録画をするまでを説明します。英語の詳しい説明は [README.md](../../README.md) にあります。

## インストール

demoreel は Python 3 のスクリプト 1 つでできています。いくつかの一般的なプログラムを動かして使い、それらはすべて下に挙げた各ディストリビューションのパッケージにあります。

**1. demoreel が使うプログラムをインストールします。** お使いのディストリビューションの 1 行を実行してください。

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian と Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

`python3` と `git` も必要です。

**openSUSE と Fedora では、ディストリビューション標準の ffmpeg では動画を書き出せません。** H.264 エンコーダーの libx264 が入っていないためです。openSUSE では Packman から、Fedora では RPM Fusion から ffmpeg を入れてください。

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

初回は、zypper が Packman の署名鍵を信頼するかどうかを尋ねます。常に信頼する選択肢を選んでください。

**2. demoreel を入手して、PATH の通った場所に置きます。**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

このあとシェルが `demoreel` というコマンドが見つからないと言う場合は、`~/.local/bin` がまだ PATH に入っていません。次の行を `~/.bashrc` に追加して、新しい端末を開いてください。

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. 確認します。**

```sh
demoreel check
```

これは何も録画しません。`準備完了` と表示するか、足りないものとそれをインストールするコマンドを示します。

**グラフィックカードが必要なアプリの場合**、`--gpu` にはさらに 4 つのプログラムが必要です。

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian と Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

## クイックスタート

`demoreel` はどのフォルダーからでも実行できます。`-o` を付けないと、動画は実行したフォルダーに、アプリ名と時刻の名前で保存されます。

```sh
# Kate を 30 秒間録画し、アプリ名のファイルに保存する
demoreel record -- kate

# ファイル名と録画する長さを指定する
demoreel record -o demo.mp4 -d 20 -- kate

# いつもの動画プレーヤーで見る
xdg-open demo.mp4

# 置いてあるだけでなく、アプリを操作する様子を見せる
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# 時間を決めずに、止めるまで録画する
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...そのあと、同じ端末か別の端末で:
demoreel stop mydemo
```

`stop` はすぐに使えます。スクリプトのすぐ次の行でもかまいません。録画がまだ起動中なら、`stop` は録画が始まるのを待ってから停止するので、必ず動画が得られます。そのあと `stop` は動画の仕上げと確認が終わるのを待ち、そのパスを表示します。録画の開始前でも停止後でも、録画が失敗した場合は、`stop` はパスを表示せず、エラーで終了します。

**前面で実行している録画では、Ctrl+C で同じことができます。** `&` を付けずに実行し、十分に録画できたら Ctrl+C を押してください。`stop` とまったく同じように、動画が仕上げられ、確認され、そのパスが表示されます。

`--` の後ろはすべて、アプリを起動するコマンドです。ご自分で入力するときとまったく同じに書いてください。demoreel は特定のアプリについて何も知りません。

終わると 1 行だけ表示します。動画のパスです。その行にはほかに何も出ないので、スクリプトで安全に受け取れます。アプリ自身が出力するものは、別に端末へ出るか、`--app-log` を使えばファイルに書かれます。

端末では、残り時間 (`-d 0` の録画では経過時間) も 1 行で表示され、その場で更新されます。最後に動画の長さとサイズが表示されます。出力がスクリプトやファイルに送られるときは、これらは何も表示されません。

---

英語の詳しい説明: [README.md](../../README.md)。この翻訳は下書きです。より良い言い回しの提案は [CONTRIBUTING.md](../../CONTRIBUTING.md) をご覧ください。

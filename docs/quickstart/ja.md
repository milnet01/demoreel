# demoreel — クイックスタート

**デスクトップを映さずに、動いているアプリを動画に録画します。**

このページでは、demoreel をインストールして最初の録画をするまでを説明します。英語の詳しい説明は [README.md](../../README.md) にあります。

## インストール

0.9.0 以降、どのリリースにも Debian、Ubuntu、Fedora、openSUSE、Arch 用のパッケージがあります。パッケージは、demoreel が動かすプログラムをお使いのディストリビューションのリポジトリから入れます。マニュアルページとタブ補完もインストールします。そのほかのディストリビューションでは、[ソースからのインストール](../../README.md#install-from-source)（英語）を見てください。

**1. お使いのディストリビューション用のパッケージを**[最新リリース](https://github.com/milnet01/demoreel/releases/latest)**からダウンロードします。** Debian と Ubuntu は `.deb`、Fedora と openSUSE は `.rpm`、Arch は `PKGBUILD` です。

**2. インストールします。** ダウンロードしたフォルダーで、お使いのディストリビューションの 1 行を実行してください。

```sh
# Debian と Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

パッケージには署名がありません。そのため openSUSE では `--allow-unsigned-rpm` が必要です。

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

**3. 確認します。**

```sh
demoreel check
```

これは何も録画しません。`準備完了` と表示するか、足りないものとそれをインストールするコマンドを示します。

**削除するには**、パッケージマネージャーを使います。

```sh
# Debian と Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**グラフィックカードが必要なアプリの場合**、`--gpu` にはさらに 4 つのプログラムが必要です。Debian、Ubuntu、Fedora、openSUSE のパッケージはそれらも入れます。Arch の場合や、ソースからインストールした場合は、自分でインストールしてください。

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

**openSUSE では、`record --gpu` はまだ動画を書き出せません。** openSUSE の wf-recorder は openSUSE 独自の動画ライブラリを読み込み、そこには libx264 がありません。`demoreel check` はそのことを伝え、`--gpu` は準備ができていないと示します。

**音声には** `pactl` が必要です。これがあれば、録画中のアプリの音がスピーカーから流れることはなく、`--audio` でその音を動画に入れられます。

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian と Ubuntu
sudo apt install pulseaudio-utils
# Fedora
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
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

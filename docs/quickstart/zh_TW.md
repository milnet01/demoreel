# demoreel — 快速入門

**錄下應用程式執行的影片，而不會拍到您的桌面。**

本頁說明如何安裝 demoreel 並完成第一次錄影。完整的英文說明請見 [README.md](../../README.md)。

## 安裝

demoreel 是一個 Python 3 腳本。它會呼叫幾個常見的程式，而下列每個發行版都有提供這些程式的套件。

**1. 安裝它所需的程式。** 依您的發行版執行其中一行：

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian 和 Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

您還需要 `python3` 和 `git`。

**在 openSUSE 和 Fedora 上，發行版本身的 ffmpeg 無法寫出影片。** 它少了 H.264 編碼器 libx264。請在 openSUSE 上改用 Packman 的 ffmpeg，在 Fedora 上改用 RPM Fusion 的 ffmpeg：

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

第一次執行時，zypper 會詢問是否信任 Packman 的簽署金鑰。請選擇「永遠信任」的那個選項。

**2. 取得 demoreel，並把它放進您的 PATH。**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

如果接著 shell 表示找不到 `demoreel` 這個指令，就表示 `~/.local/bin` 還不在您的 PATH 中。請把下面這一行加到 `~/.bashrc`，然後開啟一個新的終端機：

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. 檢查一下。**

```sh
demoreel check
```

它不會錄下任何東西。它會顯示 `就緒`，或指出缺少什麼，以及安裝它的指令。

**對於需要顯示卡的應用程式**，`--gpu` 還需要另外四個程式：

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian 和 Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

## 快速入門

您可以在任何資料夾中執行 `demoreel`。如果沒有加上 `-o`，影片會存放在您執行它的資料夾中，並以應用程式名稱和時間命名。

```sh
# 錄下 Kate 30 秒，存成以應用程式命名的檔案
demoreel record -- kate

# 自訂檔名和錄影長度
demoreel record -o demo.mp4 -d 20 -- kate

# 用您平常的影片播放器觀看
xdg-open demo.mp4

# 展示應用程式的操作，而不只是讓它停在那裡
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# 一直錄到您喊停為止，而不是錄固定的時間
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ……然後，在同一個或另一個終端機中：
demoreel stop mydemo
```

`stop` 會立即生效，即使寫在腳本的下一行也一樣。如果這次執行還在啟動中，`stop` 會等到它開始錄影後再停止它，所以您一定會得到一部影片。接著 `stop` 會等影片完成並檢查完畢，然後印出它的路徑。如果這次執行失敗了，無論是在開始錄影之前，還是在被停止之後，`stop` 都不會印出路徑，並以錯誤結束。

**在前景執行時，Ctrl+C 的作用相同。** 不要加上 `&`，錄夠了就按 Ctrl+C，影片就會完成、檢查完畢並印出路徑，和使用 `stop` 完全一樣。

`--` 後面的所有內容，就是啟動您的應用程式的指令，和您自己輸入時完全一樣。demoreel 不知道任何特定應用程式的細節。

完成時，它會印出一行：您的影片的路徑。那一行不會有其他內容，所以您可以放心在腳本中擷取它。應用程式自己印出的任何內容，會另外顯示在終端機上，或用 `--app-log` 寫入檔案。

在終端機中，您還會看到剩下多少時間；如果是 `-d 0` 的執行，則會看到已經錄了多久。這些資訊顯示在同一行，並且會原地更新。最後會顯示影片的長度和大小。當輸出是送到腳本或檔案時，這些都不會印出。

---

完整的英文說明文件：[README.md](../../README.md)。這份翻譯是草稿。如果您想建議更好的措辭，請參閱 [CONTRIBUTING.md](../../CONTRIBUTING.md)。

# demoreel — 快速入門

**錄下應用程式執行的影片，而不會拍到您的桌面。**

本頁說明如何安裝 demoreel 並完成第一次錄影。完整的英文說明請見 [README.md](../../README.md)。

## 安裝

從 0.9.0 起，每個版本都附有適用於 Debian、Ubuntu、Fedora、openSUSE 和 Arch 的套件。套件會從您發行版本身的軟體庫安裝 demoreel 所呼叫的程式。它也會安裝說明手冊頁和 Tab 自動完成。其他發行版請見英文的[從原始碼安裝](../../README.md#install-from-source)。

**1. 下載適合您發行版的套件**，在[最新版本](https://github.com/milnet01/demoreel/releases/latest)頁面：Debian 和 Ubuntu 用 `.deb`，Fedora 和 openSUSE 用 `.rpm`，Arch 用 `PKGBUILD`。

**2. 安裝它。** 在您下載它的資料夾中，依您的發行版執行其中一行：

```sh
# Debian 和 Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

套件沒有簽署。所以 openSUSE 需要 `--allow-unsigned-rpm`。

**在 openSUSE 和 Fedora 上，發行版本身的 ffmpeg 無法寫出影片。** 它少了 H.264 編碼器 libx264。請在 openSUSE 上改用 Packman 的 ffmpeg，在 Fedora 上改用 RPM Fusion 的 ffmpeg：

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

第一次執行時，zypper 會詢問是否信任 Packman 的簽署金鑰。請選擇「永遠信任」的那個選項。

**3. 檢查一下。**

```sh
demoreel check
```

它不會錄下任何東西。它會顯示 `就緒`，或指出缺少什麼，以及安裝它的指令。

**要移除它**，請使用您的套件管理員：

```sh
# Debian 和 Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**對於需要顯示卡的應用程式**，`--gpu` 還需要另外四個程式。Debian、Ubuntu、Fedora 和 openSUSE 的套件會一併安裝它們。在 Arch 上，或從原始碼安裝之後，請自行安裝：

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
sudo zypper install --from packman --allow-vendor-change libavcodec62
# Debian 和 Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
# Mageia（沒有 cage、wlr-randr 和 wf-recorder 的套件）
sudo dnf install x11-server-xwayland
```

**在 openSUSE 上，無論用哪種方式安裝，都請執行 `libavcodec62` 這一行。** 它從上面為 ffmpeg 加入的 Packman 取得 wf-recorder 的影片函式庫。openSUSE 自己建置的版本沒有 libx264。如果 wf-recorder 載入的是更新的函式庫，`demoreel check` 會改為指出要安裝的套件。

**聲音**需要 `pactl`。有了它，被錄製應用程式的聲音永遠不會傳到您的喇叭，`--audio` 還能把這聲音放進影片：

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian 和 Ubuntu
sudo apt install pulseaudio-utils
# Fedora 和 Mageia
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
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

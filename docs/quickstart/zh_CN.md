# demoreel — 快速入门

**录制应用运行时的视频，而不会拍到您的桌面。**

本页介绍如何安装 demoreel 并完成第一次录制。完整的英文指南见 [README.md](../../README.md)。

## 安装

从 0.9.0 起，每个版本都附带适用于 Debian、Ubuntu、Fedora、openSUSE 和 Arch 的软件包。软件包会从您发行版自己的软件源安装 demoreel 调用的程序。它还会安装手册页和 Tab 补全。其他发行版请见英文的[从源码安装](../../README.md#install-from-source)。

**1. 下载适合您发行版的软件包**，在[最新版本](https://github.com/milnet01/demoreel/releases/latest)页面：Debian 和 Ubuntu 用 `.deb`，Fedora 和 openSUSE 用 `.rpm`，Arch 用 `PKGBUILD`。

**2. 安装它。** 在您下载它的文件夹中，按您的发行版运行一行命令：

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

软件包没有签名。所以 openSUSE 需要 `--allow-unsigned-rpm`。

**在 openSUSE 和 Fedora 上，发行版自带的 ffmpeg 无法写出视频。** 它缺少 H.264 编码器 libx264。请在 openSUSE 上改用 Packman 的 ffmpeg，在 Fedora 上改用 RPM Fusion 的 ffmpeg：

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

第一次时，zypper 会询问是否信任 Packman 的签名密钥。请选择“始终信任”的那一项。

**3. 检查一下。**

```sh
demoreel check
```

它不会录制任何内容。它会显示 `就绪`，或者指出缺少什么，以及安装它的命令。

**要卸载它**，请使用您的软件包管理器：

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

**对于需要显卡的应用**，`--gpu` 还需要另外四个程序。Debian、Ubuntu、Fedora 和 openSUSE 的软件包会一并安装它们。在 Arch 上，或从源码安装之后，请自己安装：

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
# Mageia（没有 cage、wlr-randr 和 wf-recorder 的软件包）
sudo dnf install x11-server-xwayland
```

**在 openSUSE 上，无论用哪种方式安装，都请运行 `libavcodec62` 这一行。** 它从上面为 ffmpeg 添加的 Packman 获取 wf-recorder 的视频库。openSUSE 自己构建的版本没有 libx264。如果 wf-recorder 加载的是更新的库，`demoreel check` 会改为指出要安装的软件包。

**声音**需要 `pactl`。有了它，被录制应用的声音永远不会传到您的扬声器，`--audio` 还能把这声音放进视频：

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

## 快速入门

您可以在任何文件夹中运行 `demoreel`。不加 `-o` 时，视频会保存在您运行它的文件夹中，以应用名称和时间命名。

```sh
# 录制 Kate 30 秒，保存到以应用名称命名的文件中
demoreel record -- kate

# 自己选择文件名和录制时长
demoreel record -o demo.mp4 -d 20 -- kate

# 用您常用的视频播放器观看
xdg-open demo.mp4

# 展示应用被使用的过程，而不只是摆在那里
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# 一直录制到您喊停为止，而不是录制固定时长
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ……然后，在同一个或另一个终端中：
demoreel stop mydemo
```

`stop` 立即生效，哪怕是在脚本的下一行。如果这次运行还在启动，`stop` 会等到它开始录制后再停止它，所以您总能得到一段视频。之后 `stop` 会等视频写完并检查完毕，再打印它的路径。如果这次运行失败了，无论是在开始录制之前还是在停止之后，`stop` 都不打印路径，并以错误退出。

**对于在前台的运行，Ctrl+C 的作用相同。** 去掉 `&`，录够时按 Ctrl+C，视频就会写完、检查并打印路径，和 `stop` 完全一样。

`--` 之后的所有内容，都是启动您的应用的命令，和您自己输入时一模一样。demoreel 对任何具体的应用都一无所知。

录制结束时，它会打印一行：您的视频的路径。这一行没有其他内容，所以您可以放心地在脚本中获取它。应用自身打印的内容会单独输出到终端，或者用 `--app-log` 输出到文件。

在终端中，您还会看到剩余时间（在 `-d 0` 的运行中则是已录制的时间），显示在原地更新的一行里。最后会显示视频的时长和大小。当输出交给脚本或文件时，这些都不会打印。

---

完整的英文文档：[README.md](../../README.md)。本译文是草稿。如要建议更好的措辞，请参见 [CONTRIBUTING.md](../../CONTRIBUTING.md)。

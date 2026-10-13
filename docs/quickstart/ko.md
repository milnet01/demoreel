# demoreel — 빠른 시작

**실행 중인 앱을 동영상으로 녹화합니다. 바탕 화면은 찍히지 않습니다.**

이 페이지는 demoreel을 설치하고 처음으로 녹화하는 방법을 보여 줍니다. 영어로 된 전체 안내는 [README.md](../../README.md)에 있습니다.

## 설치

0.9.0부터 모든 릴리스에는 Debian, Ubuntu, Fedora, openSUSE, Arch용 패키지가
들어 있습니다. 패키지는 demoreel이 사용하는 프로그램을 배포판 자체의
저장소에서 가져옵니다. 매뉴얼 페이지와 탭 자동 완성도 설치합니다.
다른 배포판은 [소스에서 설치하기](../../README.md#install-from-source)(영어)를
보십시오.

**1. 사용하는 배포판에 맞는 패키지를 내려받습니다.**
[최신 릴리스](https://github.com/milnet01/demoreel/releases/latest)에서 받으십시오.
Debian과 Ubuntu는 `.deb`, Fedora와 openSUSE는 `.rpm`, Arch는 `PKGBUILD`입니다.

**2. 설치합니다.** 내려받은 폴더에서, 사용하는 배포판에 맞는 한 줄입니다.

```sh
# Debian 및 Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

패키지에는 서명이 없습니다. 그래서 openSUSE에는 `--allow-unsigned-rpm`이
필요합니다.

**openSUSE와 Fedora에서는 배포판 자체의 ffmpeg으로 동영상을 쓸 수 없습니다.**
H.264 인코더인 libx264가 빠져 있기 때문입니다. openSUSE에서는 Packman에서,
Fedora에서는 RPM Fusion에서 ffmpeg을 받으십시오.

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

처음에는 zypper가 Packman의 서명 키를 신뢰할지 묻습니다. 항상 신뢰하는
선택지로 답하십시오.

**3. 확인합니다.**

```sh
demoreel check
```

아무것도 녹화하지 않습니다. `준비됨`이라고 표시하거나, 빠진 것과 그것을
설치하는 명령을 알려 줍니다.

**제거하려면** 패키지 관리자를 사용하십시오.

```sh
# Debian 및 Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**그래픽 카드가 필요한 앱의 경우**, `--gpu`에는 프로그램 네 개가 더 필요합니다.
Debian, Ubuntu, Fedora, openSUSE 패키지는 이 프로그램들을 함께 설치합니다.
Arch에서, 또는 소스에서 설치한 뒤에는 직접 설치하십시오.

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
sudo zypper install --from packman --allow-vendor-change libavcodec62
# Debian 및 Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

**openSUSE에서는 어떻게 설치했든 `libavcodec62` 줄을 실행하세요.** 이 줄은 wf-recorder의 동영상 라이브러리를
위에서 ffmpeg용으로 추가한 Packman에서 가져옵니다. openSUSE 자체 빌드에는 libx264가 없습니다. wf-recorder가
더 새 라이브러리를 불러오면 `demoreel check`가 대신 설치할 패키지를 알려 줍니다.

**소리를 위해** demoreel에는 `pactl`이 필요합니다. 이것이 있으면 녹화하는 앱의 소리가 스피커로 나가지 않고, `--audio`로 그 소리를 영상에 넣을 수 있습니다.

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian 및 Ubuntu
sudo apt install pulseaudio-utils
# Fedora
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
```

## 빠른 시작

`demoreel`은 어느 폴더에서나 실행할 수 있습니다. `-o`를 주지 않으면 동영상은
실행한 폴더에 저장되며, 이름은 앱 이름과 시각으로 정해집니다.

```sh
# Kate를 30초 동안 녹화하여, 앱 이름을 딴 파일로 저장
demoreel record -- kate

# 파일 이름과 녹화 시간 정하기
demoreel record -o demo.mp4 -d 20 -- kate

# 평소 쓰는 동영상 플레이어로 보기
xdg-open demo.mp4

# 앱이 가만히 있는 모습이 아니라 사용되는 모습 보여 주기
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# 정해진 시간이 아니라 멈추라고 할 때까지 녹화
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...그런 다음, 같은 터미널이나 다른 터미널에서:
demoreel stop mydemo
```

`stop`은 스크립트의 바로 다음 줄에서도 곧바로 동작합니다. 녹화가 아직 시작
중이면 `stop`은 녹화가 시작될 때까지 기다렸다가 멈추므로, 언제나 동영상을
얻습니다. 그다음 `stop`은 동영상이 마무리되고 검사될 때까지 기다린 뒤 그
경로를 출력합니다. 녹화가 시작되기 전이든 멈춘 뒤든 녹화가 실패하면,
`stop`은 경로를 출력하지 않고 오류와 함께 종료합니다.

**앞에서 실행 중인 녹화에는 Ctrl+C가 같은 일을 합니다.** `&`를 빼고 실행한
뒤, 충분히 찍었을 때 Ctrl+C를 누르면 `stop`과 똑같이 동영상이 마무리되고
검사되며 그 경로가 출력됩니다.

`--` 뒤의 모든 것은 앱을 시작하는 명령이며, 직접 입력할 때와 똑같이 씁니다.
demoreel은 특정 앱에 대해 아무것도 알지 못합니다.

끝나면 한 줄을 출력합니다. 바로 동영상의 경로입니다. 그 줄에는 다른 것이
들어가지 않으므로 스크립트에서 안심하고 받아 쓸 수 있습니다. 앱 자체가
출력하는 내용은 터미널에 따로 나오거나, `--app-log`로 파일에 저장됩니다.

터미널에서는 남은 시간이, `-d 0` 녹화에서는 지금까지 지난 시간이 한 줄에
표시되며 그 자리에서 바뀝니다. 마지막에는 동영상의 길이와 크기가
표시됩니다. 출력이 스크립트나 파일로 갈 때는 이 내용이 하나도 출력되지 않습니다.

---

영어로 된 전체 문서: [README.md](../../README.md).
이 번역은 초안입니다. 더 나은 표현을 제안하려면
[CONTRIBUTING.md](../../CONTRIBUTING.md)를 보십시오.

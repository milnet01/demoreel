# demoreel — Швидкий старт

**Запис відео з роботою програми — без зйомки вашого робочого столу.**

На цій сторінці показано, як установити demoreel і зробити перший запис. Повний посібник, англійською, — [README.md](../../README.md).

## Встановлення

demoreel — це один скрипт на Python 3. Він керує кількома поширеними
програмами, і кожен дистрибутив нижче постачає їх усі.

**1. Установіть програми, якими він керує.** Один рядок для вашого дистрибутива:

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian та Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

Також потрібні `python3` і `git`.

**В openSUSE і Fedora власний ffmpeg дистрибутива не може записати відео.** У
ньому немає кодувальника H.264, libx264. Візьміть ffmpeg із Packman в openSUSE
або з RPM Fusion у Fedora:

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

Першого разу zypper запитає, чи довіряти ключу підпису Packman. Виберіть
варіант, який довіряє йому завжди.

**2. Отримайте demoreel і додайте його до PATH.**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

Якщо після цього оболонка повідомить, що не може знайти команду `demoreel`,
то `~/.local/bin` ще не входить до вашого PATH. Додайте цей рядок до
`~/.bashrc` і відкрийте новий термінал:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. Перевірте.**

```sh
demoreel check
```

Ця команда нічого не записує. Вона повідомляє `готово` або називає, чого
бракує, і команду, яка це встановить.

**Для програм, яким потрібна відеокарта**, `--gpu` потребує ще чотирьох програм:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian та Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

## Швидкий старт

Запускайте `demoreel` з будь-якої теки. Без `-o` відео з'явиться в теці, з
якої ви його запустили, і матиме назву за програмою та часом.

```sh
# записати Kate протягом 30 секунд у файл, названий за програмою
demoreel record -- kate

# вибрати назву файлу й тривалість запису
demoreel record -o demo.mp4 -d 20 -- kate

# переглянути його у вашому звичному відеопрогравачі
xdg-open demo.mp4

# показати програму в роботі, а не просто відкритою
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# записувати, доки ви не скажете зупинитися, а не заданий час
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...потім, у тому самому чи іншому терміналі:
demoreel stop mydemo
```

`stop` працює одразу, навіть у наступному ж рядку скрипта. Якщо запис ще
запускається, `stop` чекає, доки почнеться запис, і тоді зупиняє його, тож ви
завжди отримаєте відео. Потім `stop` чекає, доки відео буде завершено й
перевірено, і виводить його шлях. Якщо запис не вдасться — до початку запису
або після зупинки, — `stop` не виводить шляху й завершується з помилкою.

**Ctrl+C робить те саме для запису на передньому плані.** Не ставте `&`,
натисніть Ctrl+C, коли записано досить, і відео буде завершено, перевірено, а
його шлях виведено — так само, як зі `stop`.

Усе після `--` — це команда, яка запускає вашу програму, точно так, як ви
набрали б її самі. demoreel нічого не знає про жодну конкретну програму.

Наприкінці він виводить один рядок: шлях до вашого відео. Більше нічого в цьому
рядку немає, тож його можна безпечно перехопити у скрипті. Усе, що виводить
сама програма, іде до термінала окремо або до файлу через `--app-log`.

У терміналі ви також бачите, скільки часу залишилося, а для запису з `-d 0` —
скільки він уже триває, в одному рядку, що оновлюється на місці. Наприкінці
він показує тривалість і розмір відео. Нічого з цього не виводиться, коли
вивід іде до скрипта чи файлу.

---

Повна документація, англійською: [README.md](../../README.md).
Цей переклад — чернетка. Щоб запропонувати кращий варіант, див.
[CONTRIBUTING.md](../../CONTRIBUTING.md).

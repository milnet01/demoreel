# demoreel — Швидкий старт

**Запис відео з роботою програми — без зйомки вашого робочого столу.**

На цій сторінці показано, як установити demoreel і зробити перший запис. Повний посібник, англійською, — [README.md](../../README.md).

## Встановлення

Починаючи з версії 0.9.0, кожен випуск містить пакет для Debian, Ubuntu,
Fedora, openSUSE і Arch. Пакет установлює програми, якими керує demoreel, із
власних репозиторіїв вашого дистрибутива. Він також установлює сторінку
довідки й автодоповнення клавішею Tab. Для інших дистрибутивів див.
[Встановлення з вихідного коду](../../README.md#install-from-source)
(англійською).

**1. Завантажте пакет для вашого дистрибутива** зі сторінки
[останнього випуску](https://github.com/milnet01/demoreel/releases/latest):
`.deb` для Debian та Ubuntu, `.rpm` для Fedora та openSUSE або `PKGBUILD` для
Arch.

**2. Установіть його.** У теці, куди ви його завантажили, виконайте один рядок
для вашого дистрибутива:

```sh
# Debian та Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

Пакет не підписаний. Тому openSUSE потребує `--allow-unsigned-rpm`.

**В openSUSE і Fedora власний ffmpeg дистрибутива не може записати відео.** У
ньому немає кодувальника H.264, libx264. Візьміть ffmpeg із Packman в openSUSE
або з RPM Fusion у Fedora:

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

Першого разу zypper запитає, чи довіряти ключу підпису Packman. Виберіть
варіант, який довіряє йому завжди.

**3. Перевірте.**

```sh
demoreel check
```

Ця команда нічого не записує. Вона повідомляє `готово` або називає, чого
бракує, і команду, яка це встановить.

**Щоб вилучити його**, скористайтеся менеджером пакетів:

```sh
# Debian та Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**Для програм, яким потрібна відеокарта**, `--gpu` потребує ще чотирьох програм.
Пакети для Debian, Ubuntu, Fedora та openSUSE встановлюють їх. В Arch або після
встановлення з вихідного коду встановіть їх самі:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
sudo zypper install --from packman --allow-vendor-change libavcodec62
# Debian та Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
# Mageia, де немає пакетів для cage, wlr-randr і wf-recorder
sudo dnf install x11-server-xwayland
```

**В openSUSE виконайте рядок з `libavcodec62`, хоч би як ви встановлювали.**
Він бере відеобібліотеку wf-recorder із Packman, доданого вище для ffmpeg. У
власній збірці openSUSE немає libx264. Якщо wf-recorder завантажує новішу
бібліотеку, `demoreel check` назве пакет, який треба встановити замість неї.

**Для звуку** demoreel потрібен `pactl`. З ним звук застосунку, що записується, ніколи не потрапляє у ваші динаміки, а `--audio` може додати цей звук у відео:

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian та Ubuntu
sudo apt install pulseaudio-utils
# Fedora та Mageia
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
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

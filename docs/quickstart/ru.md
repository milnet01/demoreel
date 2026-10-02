# demoreel — Быстрый старт

**Записывайте видео работающего приложения, не снимая свой рабочий стол.**

На этой странице показано, как установить demoreel и сделать первую запись. Полное руководство, на английском, — в [README.md](../../README.md).

## Установка

demoreel — это один скрипт на Python 3. Он управляет несколькими
распространёнными программами, и в каждом из дистрибутивов ниже есть пакеты
для всех них.

**1. Установите программы, которыми он управляет.** Одна строка для вашего
дистрибутива:

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian и Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

Также нужны `python3` и `git`.

**В openSUSE и Fedora собственный ffmpeg дистрибутива не может записать
видео.** В нём нет кодировщика H.264, libx264. Возьмите ffmpeg из Packman в
openSUSE или из RPM Fusion в Fedora:

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

В первый раз zypper спросит, доверять ли ключу подписи Packman. Выберите
вариант, при котором ключу доверяют всегда.

**2. Скачайте demoreel и добавьте его в PATH.**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

Если после этого оболочка сообщит, что не может найти команду `demoreel`,
значит, `~/.local/bin` ещё не входит в ваш PATH. Добавьте эту строку в
`~/.bashrc` и откройте новый терминал:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. Проверьте.**

```sh
demoreel check
```

Эта команда ничего не записывает. Она сообщает `готово` или называет, чего не
хватает, и команду, которая это установит.

**Для приложений, которым нужна видеокарта**, режиму `--gpu` нужны ещё четыре
программы:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian и Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

## Быстрый старт

Запускайте `demoreel` из любой папки. Без `-o` видео попадёт в папку, из
которой вы его запустили, и получит имя по приложению и времени.

```sh
# записать Kate в течение 30 секунд, в файл с именем приложения
demoreel record -- kate

# выбрать имя файла и длительность записи
demoreel record -o demo.mp4 -d 20 -- kate

# посмотреть в вашем обычном видеоплеере
xdg-open demo.mp4

# показать, как приложением пользуются, а не как оно просто стоит
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# записывать, пока вы не скажете «стоп», а не заданное время
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...затем, в этом же или другом терминале:
demoreel stop mydemo
```

`stop` работает сразу, даже на следующей строке скрипта. Если запуск ещё не
начался, `stop` ждёт, пока пойдёт запись, и затем останавливает её, так что
видео вы получите всегда. Потом `stop` ждёт, пока видео будет дописано и
проверено, и выводит путь к нему. Если запуск не удался — до начала записи или
после остановки, — `stop` не выводит путь и завершается с ошибкой.

**Ctrl+C делает то же самое для запуска на переднем плане.** Не ставьте `&`,
нажмите Ctrl+C, когда записано достаточно, и видео будет дописано, проверено, а
путь к нему выведен — точно так же, как со `stop`.

Всё, что стоит после `--`, — это команда, которая запускает ваше приложение,
ровно так, как вы набрали бы её сами. demoreel ничего не знает ни о каком
конкретном приложении.

По завершении он выводит одну строку: путь к вашему видео. Больше в этой строке
ничего нет, поэтому её можно спокойно получить в скрипте. Всё, что выводит само
приложение, идёт в терминал отдельно или в файл, если указать `--app-log`.

В терминале вы также видите, сколько осталось, а при запуске с `-d 0` — сколько
уже идёт запись, в одной строке, которая обновляется на месте. В конце она
показывает длину и размер видео. Ничего из этого не выводится, когда вывод идёт
в скрипт или в файл.

---

Полная документация, на английском: [README.md](../../README.md). Этот перевод —
черновик. Чтобы предложить формулировку получше, см.
[CONTRIBUTING.md](../../CONTRIBUTING.md).

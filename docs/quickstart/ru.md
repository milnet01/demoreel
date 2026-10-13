# demoreel — Быстрый старт

**Записывайте видео работающего приложения, не снимая свой рабочий стол.**

На этой странице показано, как установить demoreel и сделать первую запись. Полное руководство, на английском, — в [README.md](../../README.md).

## Установка

Начиная с версии 0.9.0, у каждого выпуска есть пакет для Debian, Ubuntu,
Fedora, openSUSE и Arch. Пакет ставит программы, которыми управляет demoreel,
из собственных репозиториев вашего дистрибутива. Он также устанавливает
страницу руководства и автодополнение по Tab. Для других дистрибутивов см.
[Установку из исходного кода](../../README.md#install-from-source) (на
английском).

**1. Скачайте пакет для вашего дистрибутива** со страницы
[последнего выпуска](https://github.com/milnet01/demoreel/releases/latest):
`.deb` для Debian и Ubuntu, `.rpm` для Fedora и openSUSE или `PKGBUILD` для
Arch.

**2. Установите его.** В папке, куда вы его скачали, выполните одну строку для
вашего дистрибутива:

```sh
# Debian и Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

Пакет не подписан. Поэтому openSUSE нужен `--allow-unsigned-rpm`.

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

**3. Проверьте.**

```sh
demoreel check
```

Эта команда ничего не записывает. Она сообщает `готово` или называет, чего не
хватает, и команду, которая это установит.

**Чтобы удалить его**, используйте менеджер пакетов:

```sh
# Debian и Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**Для приложений, которым нужна видеокарта**, режиму `--gpu` нужны ещё четыре
программы. Пакеты для Debian, Ubuntu, Fedora и openSUSE устанавливают их. В
Arch или после установки из исходного кода установите их сами:

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

**В openSUSE `record --gpu` пока не может записать видео.** wf-recorder из
openSUSE загружает собственную видеобиблиотеку openSUSE, а в ней нет libx264.
`demoreel check` сообщает об этом и называет `--gpu` неготовым.

**Для звука** demoreel нужен `pactl`. С ним звук записываемого приложения никогда не попадает в ваши динамики, а `--audio` может добавить этот звук в видео:

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian и Ubuntu
sudo apt install pulseaudio-utils
# Fedora
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
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

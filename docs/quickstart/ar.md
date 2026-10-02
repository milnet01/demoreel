# demoreel — بدء سريع

**سجّل فيديو لتطبيق وهو يعمل، دون تصوير سطح المكتب.**

تشرح هذه الصفحة كيف تثبّت demoreel وتصنع أول تسجيل. الدليل الكامل، بالإنجليزية، موجود في [README.md](../../README.md).

## التثبيت

demoreel سكربت واحد مكتوب بلغة Python 3. يعتمد على بعض البرامج الشائعة،
وكل توزيعة مذكورة أدناه توفّرها جميعًا في حزمها.

**1. ثبّت البرامج التي يعتمد عليها.** سطر واحد، حسب توزيعتك:

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian و Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

تحتاج أيضًا إلى `python3` و`git`.

**على openSUSE و Fedora، لا يستطيع ffmpeg الخاص بالتوزيعة كتابة الفيديو.**
فهو لا يتضمّن مُرمِّز H.264، أي libx264. خذ ffmpeg من Packman على openSUSE،
أو من RPM Fusion على Fedora:

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

يسألك zypper في المرة الأولى هل تثق بمفتاح التوقيع الخاص بـ Packman. اختر
الإجابة التي تثق به دائمًا.

**2. نزّل demoreel، وضعه على PATH.**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

إذا قالت الصدفة بعد ذلك إنها لا تجد الأمر `demoreel`، فهذا يعني أن
`~/.local/bin` ليس على PATH بعد. أضف هذا السطر إلى `~/.bashrc` وافتح طرفية
جديدة:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. تحقّق منه.**

```sh
demoreel check
```

لا يسجّل شيئًا. يقول `جاهز`، أو يذكر ما ينقص والأمر الذي يثبّته.

**للتطبيقات التي تحتاج إلى بطاقة الرسوميات**، يحتاج `--gpu` إلى أربعة برامج أخرى:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian و Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

## بدء سريع

شغّل `demoreel` من أي مجلد. بدون `-o`، يُحفظ الفيديو في المجلد الذي تشغّله
منه، باسم التطبيق والوقت.

```sh
# سجّل Kate لمدة 30 ثانية، في ملف يحمل اسم التطبيق
demoreel record -- kate

# اختر اسم الملف ومدة التسجيل
demoreel record -o demo.mp4 -d 20 -- kate

# شاهده في مشغّل الفيديو المعتاد لديك
xdg-open demo.mp4

# أظهر التطبيق وهو يُستخدم، لا وهو ساكن فقط
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# سجّل حتى تطلب التوقف، بدل مدة محددة
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...ثم، في الطرفية نفسها أو في طرفية أخرى:
demoreel stop mydemo
```

يعمل `stop` فورًا، حتى في السطر التالي مباشرة من سكربت. إذا كان التشغيل لا
يزال يبدأ، ينتظر `stop` حتى يبدأ التسجيل ثم يوقفه، فتحصل دائمًا على فيديو.
بعد ذلك ينتظر `stop` حتى يكتمل الفيديو ويُفحص، ثم يطبع مساره. إذا فشل التشغيل،
قبل أن يسجّل أو بعد إيقافه، لا يطبع `stop` أي مسار ويخرج مع خطأ.

**يفعل Ctrl+C الشيء نفسه لتشغيل في المقدّمة.** احذف `&`، واضغط Ctrl+C حين
يكفيك ما سُجّل، فيكتمل الفيديو ويُفحص ويُطبع مساره، تمامًا كما مع `stop`.

كل ما بعد `--` هو الأمر الذي يشغّل تطبيقك، تمامًا كما تكتبه بنفسك. لا يعرف
demoreel شيئًا عن أي تطبيق بعينه.

عندما ينتهي يطبع سطرًا واحدًا: مسار الفيديو. لا يظهر شيء آخر في ذلك السطر،
لذا يمكنك التقاطه في سكربت بأمان. أي شيء يطبعه التطبيق نفسه يذهب إلى الطرفية
منفصلًا، أو إلى ملف مع `--app-log`.

في الطرفية ترى أيضًا كم بقي من الوقت، أو في تشغيل بـ `-d 0` كم مضى منذ البدء،
في سطر واحد يتحدّث في مكانه. ينتهي بطول الفيديو وحجمه. لا يُطبع شيء من هذا
عندما يذهب الناتج إلى سكربت أو إلى ملف.

---

التوثيق الكامل، بالإنجليزية: [README.md](../../README.md). هذه الترجمة مسودة.
لاقتراح صياغة أفضل، راجع [CONTRIBUTING.md](../../CONTRIBUTING.md).

# demoreel — התחלה מהירה

**הקלטת סרטון של יישום פועל, בלי לצלם את שולחן העבודה.**

הדף הזה מראה איך להתקין את demoreel ולבצע הקלטה ראשונה. המדריך המלא, באנגלית, נמצא ב־[README.md](../../README.md).

## התקנה

מגרסה 0.9.0 והלאה, כל גרסה מגיעה עם חבילה ל־Debian, ל־Ubuntu, ל־Fedora,
ל־openSUSE ול־Arch. החבילה מביאה את התוכניות ש־demoreel מפעיל מהמאגרים של
ההפצה עצמה. היא מתקינה גם את דף העזרה (man) ואת ההשלמה במקש Tab. להפצה אחרת,
ראו [התקנה מקוד המקור](../../README.md#install-from-source) (באנגלית).

**1. הורדת החבילה להפצה שלך** מתוך
[הגרסה האחרונה](https://github.com/milnet01/demoreel/releases/latest): קובץ
ה־`.deb` ל־Debian ול־Ubuntu, קובץ ה־`.rpm` ל־Fedora ול־openSUSE, או
ה־`PKGBUILD` ל־Arch.

**2. התקנה.** בתיקייה שאליה הורדת אותה, שורה אחת לפי ההפצה:

```sh
# Debian ו־Ubuntu
sudo apt install ./demoreel_*_all.deb
# Fedora
sudo dnf install ./demoreel-*.noarch.rpm
# openSUSE
sudo zypper install --allow-unsigned-rpm ./demoreel-*.noarch.rpm
# Arch
makepkg -si
```

החבילה לא חתומה. לכן openSUSE צריך את `--allow-unsigned-rpm`.

**ב־openSUSE וב־Fedora, ה־ffmpeg של ההפצה עצמה לא יכול לכתוב את הסרטון.** חסר
בו מקודד ה־H.264, libx264. יש לקחת את ffmpeg מ־Packman ב־openSUSE, או
מ־RPM Fusion ב־Fedora:

```sh
# openSUSE
sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper install --from packman --allow-vendor-change ffmpeg
# Fedora
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

בפעם הראשונה zypper שואל אם לסמוך על מפתח החתימה של Packman. יש לענות בבחירה
שסומכת עליו תמיד.

**3. בדיקה.**

```sh
demoreel check
```

הפקודה לא מקליטה כלום. היא אומרת `מוכן`, או מציינת מה חסר ואת הפקודה שמתקינה
אותו.

**כדי להסיר אותו**, יש להשתמש במנהל החבילות:

```sh
# Debian ו־Ubuntu
sudo apt remove demoreel
# Fedora
sudo dnf remove demoreel
# openSUSE
sudo zypper remove demoreel
# Arch
sudo pacman -R demoreel
```

**ליישומים שצריכים את כרטיס המסך**, `--gpu` דורש עוד ארבע תוכניות. החבילות
ל־Debian, ל־Ubuntu, ל־Fedora ול־openSUSE מביאות אותן. ב־Arch, או אחרי התקנה
מקוד המקור, יש להתקין אותן בעצמך:

```sh
# openSUSE
sudo zypper install cage xwayland wlr-randr wf-recorder
# Debian ו־Ubuntu
sudo apt install cage xwayland wlr-randr wf-recorder
# Fedora
sudo dnf install cage xorg-x11-server-Xwayland wlr-randr wf-recorder
# Arch
sudo pacman -S cage xorg-xwayland wlr-randr wf-recorder
```

**ב־openSUSE, `record --gpu` עדיין לא יכול לכתוב את הסרטון.** ה־wf-recorder
של openSUSE טוען את ספריית הווידאו של openSUSE עצמה, ואין בה libx264.
`demoreel check` מציין זאת, ואומר ש־`--gpu` לא מוכן.

**לקול** demoreel צריך את `pactl`. איתו הקול של אפליקציה מוקלטת לעולם לא מגיע לרמקולים שלך, ו־`--audio` יכול להכניס את הקול הזה לסרטון:

```sh
# openSUSE
sudo zypper install pulseaudio-utils
# Debian ו־Ubuntu
sudo apt install pulseaudio-utils
# Fedora
sudo dnf install pulseaudio-utils
# Arch
sudo pacman -S libpulse
```

## התחלה מהירה

אפשר להריץ את `demoreel` מכל תיקייה. בלי `-o`, הסרטון נשמר בתיקייה שממנה
מריצים אותו, בשם של היישום ושל השעה.

```sh
# הקלטת Kate למשך 30 שניות, לקובץ שנקרא על שם היישום
demoreel record -- kate

# בחירת שם הקובץ ומשך ההקלטה
demoreel record -o demo.mp4 -d 20 -- kate

# צפייה בסרטון, בנגן הווידאו הרגיל
xdg-open demo.mp4

# הצגת היישום בזמן שימוש, ולא רק כשהוא עומד במקום
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# הקלטה עד שאומרים לעצור, במקום לזמן קבוע
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &

# ...ואז, באותו מסוף או במסוף אחר:
demoreel stop mydemo
```

`stop` עובד מיד, אפילו בשורה הבאה ממש של סקריפט. אם ההרצה עדיין מתחילה,
`stop` מחכה עד שהיא מקליטה ואז עוצר אותה, כך שתמיד מתקבל סרטון. אחר כך
`stop` מחכה שהסרטון יושלם וייבדק, ומדפיס את הנתיב שלו. אם ההרצה נכשלת,
לפני שהיא מקליטה או אחרי שנעצרה, `stop` לא מדפיס נתיב ויוצא עם שגיאה.

**Ctrl+C עושה אותו דבר להרצה בחזית.** משמיטים את ה־`&`, לוחצים Ctrl+C כשיש
מספיק, והסרטון מושלם, נבדק והנתיב שלו מודפס, בדיוק כמו עם `stop`.

כל מה שאחרי `--` הוא הפקודה שמפעילה את היישום, בדיוק כפי שמקלידים אותה ביד.
demoreel לא יודע דבר על שום יישום מסוים.

בסיום הוא מדפיס שורה אחת: הנתיב לסרטון. שום דבר אחר לא מופיע בשורה הזו, כך
שאפשר ללכוד אותה בבטחה בסקריפט. כל מה שהיישום עצמו מדפיס נשלח למסוף בנפרד, או
לקובץ עם `--app-log`.

במסוף רואים גם כמה זמן נותר, או בהרצה עם `-d 0` כמה זמן היא כבר פועלת, בשורה
אחת שמתעדכנת במקומה. בסוף מופיעים בה אורך הסרטון וגודלו. שום דבר מזה לא מודפס
כשהפלט נשלח לסקריפט או לקובץ.

---

התיעוד המלא, באנגלית: [README.md](../../README.md). התרגום הזה הוא טיוטה. כדי
להציע ניסוח טוב יותר, ראו [CONTRIBUTING.md](../../CONTRIBUTING.md).

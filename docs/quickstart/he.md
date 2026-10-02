# demoreel — התחלה מהירה

**הקלטת סרטון של יישום פועל, בלי לצלם את שולחן העבודה.**

הדף הזה מראה איך להתקין את demoreel ולבצע הקלטה ראשונה. המדריך המלא, באנגלית, נמצא ב־[README.md](../../README.md).

## התקנה

demoreel הוא סקריפט Python 3 אחד. הוא מפעיל כמה תוכניות נפוצות, וכל אחת
מההפצות שלהלן אורזת את כולן.

**1. התקנת התוכניות שהוא מפעיל.** שורה אחת, לפי ההפצה:

```sh
# openSUSE
sudo zypper install ffmpeg xdotool xauth xorg-x11-server-Xvfb
# Debian ו־Ubuntu
sudo apt install ffmpeg xdotool xauth xvfb
# Fedora
sudo dnf install ffmpeg xdotool xorg-x11-xauth xorg-x11-server-Xvfb
# Arch
sudo pacman -S ffmpeg xdotool xorg-xauth xorg-server-xvfb
```

נדרשים גם `python3` ו־`git`.

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

**2. הורדת demoreel והוספתו ל־PATH.**

```sh
git clone https://github.com/milnet01/demoreel.git
mkdir -p ~/.local/bin
ln -s "$PWD/demoreel/demoreel" ~/.local/bin/demoreel
```

אם המעטפת (ה־shell) אומרת אחר כך שהיא לא מוצאת את הפקודה `demoreel`, התיקייה
`~/.local/bin` עדיין לא נמצאת ב־PATH. יש להוסיף את השורה הזו ל־`~/.bashrc`
ולפתוח מסוף חדש:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**3. בדיקה.**

```sh
demoreel check
```

הפקודה לא מקליטה כלום. היא אומרת `מוכן`, או מציינת מה חסר ואת הפקודה שמתקינה
אותו.

**ליישומים שצריכים את כרטיס המסך**, `--gpu` דורש עוד ארבע תוכניות:

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

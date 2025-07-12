#!/bin/bash

# تحديث الحزم وتثبيت البرامج المطلوبة
apt-get update

apt-get install -y \
  unclutter \
  xorg \
  firefox-esr \
  openbox \
  lightdm \
  locales \
  wget \
  cabextract \
  fontconfig \
  xfonts-utils \
  sudo

# تعيين المنطقة الزمنية واللغة
timedatectl set-timezone Asia/Baghdad
locale-gen ar_IQ.UTF-8
update-locale LANG=ar_IQ.UTF-8
export LANG=ar_IQ.UTF-8
export LANGUAGE=ar_IQ:ar
export LC_ALL=ar_IQ.UTF-8

# تثبيت خطوط Microsoft
mkdir -p /usr/share/fonts/truetype/msttcorefonts
cd /usr/share/fonts/truetype/msttcorefonts
wget -O arial32.exe https://downloads.sourceforge.net/corefonts/arial32.exe
wget -O times32.exe https://downloads.sourceforge.net/corefonts/times32.exe
cabextract -L -F '*.ttf' arial32.exe
cabextract -L -F '*.ttf' times32.exe
chmod 644 *.ttf
fc-cache -fv

echo "✅ تم تثبيت خطوط Microsoft (بما فيها Arial) بنجاح"

# إنشاء مستخدم kiosk إن لم يكن موجود
groupadd -f kiosk
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash
chown -R kiosk:kiosk /home/kiosk

# إعداد مجلد Openbox
mkdir -p /home/kiosk/.config/openbox

# إعداد xorg لمنع تبديل الشاشات
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# إعداد autologin لـ kiosk
cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
autologin-user=kiosk
user-session=openbox
EOF

# إعداد ملف autostart لتشغيل Firefox Kiosk
cat > /home/kiosk/.config/openbox/autostart << 'EOF'
#!/bin/bash

unclutter -idle 0.1 -grab -root &

# إعداد الشاشة
xrandr -o left
xset -dpms
xset s off
xset s noblank

# إعداد اللغة
export LANG=ar_IQ.UTF-8
export LANGUAGE=ar_IQ:ar
export LC_ALL=ar_IQ.UTF-8

# تشغيل Firefox مع ملف التعريف الخاص
firefox-esr \
  --kiosk \
  --private-window \
  --no-remote \
  --lang=ar-IQ \
  --profile /home/kiosk/.mozilla/kiosk-profile \
  "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv"
EOF

chmod +x /home/kiosk/.config/openbox/autostart
chown -R kiosk:kiosk /home/kiosk

# إنشاء ملف تعريف Firefox kiosk
sudo -u kiosk firefox-esr -CreateProfile "kiosk-profile /home/kiosk/.mozilla/kiosk-profile"

# إعدادات لمنع النوافذ المزعجة داخل Firefox
mkdir -p /home/kiosk/.mozilla/kiosk-profile
cat > /home/kiosk/.mozilla/kiosk-profile/user.js << EOF
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("app.update.enabled", false);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("browser.usedOnWindows10.introURL", "");
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
EOF

chown -R kiosk:kiosk /home/kiosk/.mozilla

echo "✅ تم الانتهاء من إعداد Kiosk باستخدام Firefox بدون تحقق أو نوافذ مزعجة!"

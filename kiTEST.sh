#!/bin/bash

# ✅ تحديث النظام وتثبيت البرامج المطلوبة
apt-get update
apt-get install -y \
  unclutter \
  xorg \
  firefox-esr \
  openbox \
  lightdm \
  wget \
  cabextract \
  fontconfig \
  xfonts-utils \
  

# ✅ تعيين المنطقة الزمنية فقط (بغداد)
timedatectl set-timezone Asia/Baghdad

# ✅ تثبيت خطوط Microsoft Arial و Times
mkdir -p /usr/share/fonts/truetype/msttcorefonts
cd /usr/share/fonts/truetype/msttcorefonts
wget -O arial32.exe https://downloads.sourceforge.net/corefonts/arial32.exe
wget -O times32.exe https://downloads.sourceforge.net/corefonts/times32.exe
cabextract -L -F '*.ttf' arial32.exe
cabextract -L -F '*.ttf' times32.exe
chmod 644 *.ttf
fc-cache -fv
echo "✅ تم تثبيت خطوط Microsoft (Arial, Times)"

# ✅ إنشاء مستخدم kiosk إن لم يكن موجود
groupadd -f kiosk
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash
chown -R kiosk:kiosk /home/kiosk

# ✅ إعداد xorg لمنع تبديل الشاشات
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# ✅ إعداد LightDM لتسجيل دخول تلقائي
cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
autologin-user=kiosk
user-session=openbox
EOF

# ✅ مجلد autostart لتشغيل Firefox
mkdir -p /home/kiosk/.config/openbox
cat > /home/kiosk/.config/openbox/autostart << 'EOF'
#!/bin/bash

unclutter -idle 0.1 -grab -root &

xrandr -o left
xset -dpms
xset s off
xset s noblank

firefox-esr \
  --kiosk \
  --private-window \
  --no-remote \
  --profile /home/kiosk/.mozilla/kiosk-profile \
  "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv"
EOF

chmod +x /home/kiosk/.config/openbox/autostart
chown -R kiosk:kiosk /home/kiosk

# ✅ إنشاء بروفايل Firefox kiosk
  -u kiosk firefox-esr -CreateProfile "kiosk-profile /home/kiosk/.mozilla/kiosk-profile"

# ✅ إعدادات منع النوافذ المزعجة في Firefox
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

echo "✅ تم الانتهاء من إعداد kiosk باستخدام Firefox بدون لغة عربية خاصة!"

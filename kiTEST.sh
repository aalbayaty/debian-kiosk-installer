#!/bin/bash

# ✅ تحديث النظام وتثبيت البرامج الأساسية
apt-get update

apt-get install -y \
  unclutter \
  xorg \
  chromium \
  openbox \
  lightdm \
  locales \
  wget \
  cabextract \
  fontconfig \
  xfonts-utils \
  sudo

# ✅ تعيين المنطقة الزمنية
timedatectl set-timezone Asia/Baghdad

# ✅ تثبيت خطوط Microsoft (Arial, Times)
mkdir -p /usr/share/fonts/truetype/msttcorefonts
cd /usr/share/fonts/truetype/msttcorefonts
wget -O times32.exe https://downloads.sourceforge.net/corefonts/times32.exe
wget -O arial32.exe https://downloads.sourceforge.net/corefonts/arial32.exe
cabextract -L -F '*.ttf' arial32.exe
cabextract -L -F '*.ttf' times32.exe
chmod 644 *.ttf
fc-cache -fv

echo "✅ تم تثبيت خطوط Microsoft (Arial, Times)"

# ✅ إعداد openbox autostart
mkdir -p /home/kiosk/.config/openbox

# ✅ إنشاء مجموعة ومستخدم kiosk إذا لم يكن موجود
groupadd -f kiosk
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash
chown -R kiosk:kiosk /home/kiosk

# ✅ إعداد X لمنع تبديل الشاشة
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# ✅ إعداد lightdm لتسجيل الدخول تلقائيًا
cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
autologin-user=kiosk
user-session=openbox
EOF

# ✅ autostart لتشغيل Chromium بخط Arial
cat > /home/kiosk/.config/openbox/autostart << 'EOF'
#!/bin/bash

unclutter -idle 0.1 -grab -root &

xrandr -o left
xset -dpms
xset s off
xset s noblank

while true
do
  chromium \
    --no-sandbox \
    --kiosk \
    --lang=ar \
    --disable-translate \
    --disable-infobars \
    --disable-suggestions-service \
    --disable-save-password-bubble \
    --disable-session-crashed-bubble \
    --autoplay-policy=no-user-gesture-required \
    --incognito \
    --font-family="Arial" \
    --sans-serif-font="Arial" \
    "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv"
  sleep 5
done &
EOF

chmod +x /home/kiosk/.config/openbox/autostart
chown -R kiosk:kiosk /home/kiosk

echo "✅ تم إعداد Kiosk باستخدام Chromium مع الخط الافتراضي Arial!"

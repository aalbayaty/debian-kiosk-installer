#!/bin/bash

# ✅ تحديث الحزم
apt-get update

# ✅ تثبيت البرامج الأساسية
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
  xfonts-utils

# ✅ تعيين المنطقة الزمنية
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

# ✅ إعداد مستخدم kiosk إذا لم يكن موجود
groupadd -f kiosk
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash
chown -R kiosk:kiosk /home/kiosk

# ✅ إعداد Arial كخط افتراضي للنظام بالكامل
mkdir -p /etc/fonts/conf.d

cat > /etc/fonts/conf.d/99-arial-default.conf << EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Arial</family>
    </prefer>
  </alias>
  <alias>
    <family>serif</family>
    <prefer>
      <family>Arial</family>
    </prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>Arial</family>
    </prefer>
  </alias>
</fontconfig>
EOF

fc-cache -fv

# ✅ إعداد X11 لمنع تبديل الشاشات
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# ✅ إعداد LightDM لتسجيل الدخول التلقائي
cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
autologin-user=kiosk
user-session=openbox
EOF

# ✅ إعداد autostart لتشغيل Chromium
mkdir -p /home/kiosk/.config/openbox

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
    --font-family-sans-serif="Arial" \
    --font-family-serif="Arial" \
    --font-family-monospace="Arial" \
    "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv"
  sleep 5
done &
EOF

chmod +x /home/kiosk/.config/openbox/autostart
chown -R kiosk:kiosk /home/kiosk/.config/openbox

echo "✅ تم إعداد Kiosk باستخدام Chromium والخط Arial كنظامي"

#!/bin/bash

# تحديث الحزم
apt-get update

# تثبيت البرامج المطلوبة
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

# تعيين المنطقة الزمنية إلى بغداد
timedatectl set-timezone Asia/Baghdad

# إعداد اللغة العربية - العراق
locale-gen ar_IQ.UTF-8
update-locale LANG=ar_IQ.UTF-8
export LANG=ar_IQ.UTF-8
export LANGUAGE=ar_IQ:ar
export LC_ALL=ar_IQ.UTF-8

# تثبيت خطوط Microsoft (Arial و Times)
mkdir -p /usr/share/fonts/truetype/msttcorefonts
cd /usr/share/fonts/truetype/msttcorefonts

wget -O arial32.exe https://downloads.sourceforge.net/corefonts/arial32.exe
wget -O times32.exe https://downloads.sourceforge.net/corefonts/times32.exe

cabextract -L -F '*.ttf' arial32.exe
cabextract -L -F '*.ttf' times32.exe

chmod 644 *.ttf
fc-cache -fv

echo "✅ تم تثبيت خطوط Microsoft (بما فيها Arial) بنجاح"

# إعداد مجلد تهيئة openbox
mkdir -p /home/kiosk/.config/openbox

# إنشاء المستخدم kiosk إن لم يكن موجودًا
groupadd -f kiosk
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash

# إعطاء الصلاحيات للمجلد
chown -R kiosk:kiosk /home/kiosk

# تعطيل تبديل الشاشات الافتراضية في X11
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi

cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# إعداد autologin لـ kiosk باستخدام openbox
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi

cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
autologin-user=kiosk
user-session=openbox
EOF

# إعداد autostart لتشغيل Chromium في kiosk mode
if [ -e "/home/kiosk/.config/openbox/autostart" ]; then
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
fi

cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

unclutter -idle 0.1 -grab -root &

while :
do
  xrandr -o left
  xset -dpms
  xset s off
  xset s noblank

  export LANG=ar_IQ.UTF-8
  export LANGUAGE=ar_IQ:ar
  export LC_ALL=ar_IQ.UTF-8

  chromium \
    --no-first-run \
    --kiosk \
    --lang=ar-IQ \
    --disable-translate \
    --disable-infobars \
    --disable-suggestions-service \
    --disable-save-password-bubble \
    --disable-session-crashed-bubble \
    --autoplay-policy=no-user-gesture-required \
    --incognito \
    "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv"

  sleep 5
done &
EOF

# تعديل الملكية للملفات النهائية
chown -R kiosk:kiosk /home/kiosk

echo "✅ تم الانتهاء من إعداد Kiosk بالكامل!"

#!/bin/bash

# ✅ تحديث النظام وتثبيت الحزم
apt-get update

# ✅ تثبيت البرامج الأساسية
apt-get install \
    unclutter \
    xorg \
    chromium \
    openbox \
    lightdm \
    locales \
    fonts-amiri \
    -y

# ✅ إعداد المنطقة الزمنية
timedatectl set-timezone Asia/Baghdad

# ✅ مستودعات إضافية وخطوط مايكروسوفت (اختياري)
add-apt-repository multiverse
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get install ttf-mscorefonts-installer -y

# ✅ إزالة خطوط DejaVu حتى لا تُستخدم افتراضيًا
apt-get purge fonts-dejavu* -y

# ✅ إنشاء مجلد إعدادات openbox
mkdir -p /home/kiosk/.config/openbox

# ✅ إنشاء مجموعة ومستخدم kiosk إن لم يكونا موجودين
if ! getent group kiosk > /dev/null; then
  groupadd kiosk
fi

if ! id -u kiosk > /dev/null 2>&1; then
  useradd -m kiosk -g kiosk -s /bin/bash
fi

chown -R kiosk:kiosk /home/kiosk

# ✅ إعداد X لمنع التحول بين TTY
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi

cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# ✅ إعداد LightDM لتسجيل الدخول التلقائي
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi

cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# ✅ إعداد Amiri كخط افتراضي للنظام
mkdir -p /etc/fonts/conf.d

cat > /etc/fonts/conf.d/60-amiri-prefer.conf << "EOF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Amiri</family>
    </prefer>
  </alias>
  <alias>
    <family>serif</family>
    <prefer>
      <family>Amiri</family>
    </prefer>
  </alias>
</fontconfig>
EOF

fc-cache -f -v

# ✅ إعداد بدء التشغيل التلقائي لـ openbox
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

  chromium \
    --no-first-run \
    --start-maximized \
    --disable \
    --disable-translate \
    --disable-infobars \
    --disable-suggestions-service \
    --disable-save-password-bubble \
    --disable-session-crashed-bubble \
    --incognito \
    --kiosk "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv"

  sleep 5
done &
EOF

echo "✅ تم الإعداد بنجاح: Kiosk يعمل وخط Amiri مفعل!"

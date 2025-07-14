#!/bin/bash
set -e

# ✅ تحديث النظام وتثبيت الحزم الأساسية
apt-get update
apt-get install -y \
  wget \
  unzip \
  fontconfig \
  xorg \
  unclutter \
  chromium \
  openbox \
  lightdm \
  locales

# ✅ ضبط المنطقة الزمنية
timedatectl set-timezone Asia/Baghdad

# ✅ حذف خطوط DejaVu
apt-get purge -y fonts-dejavu*

# ✅ تنزيل وتثبيت خط Arial يدوياً من GitHub
mkdir -p /usr/share/fonts/truetype/arial
cd /usr/share/fonts/truetype/arial

# استخدم رابط مباشر من مستودع موثوق
wget -qO arial.ttf \
  https://raw.githubusercontent.com/kavin808/arial.ttf/master/arial.ttf
chmod 644 arial.ttf

# ✅ تحديث كاش الخطوط
fc-cache -f -v

# ✅ تعيين Arial كخط النظام الافتراضي
mkdir -p /etc/fonts/conf.d
cat > /etc/fonts/conf.d/60-arial-prefer.conf << "EOF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias><family>sans-serif</family><prefer><family>Arial</family></prefer></alias>
  <alias><family>serif</family><prefer><family>Arial</family></prefer></alias>
  <alias><family>monospace</family><prefer><family>Arial</family></prefer></alias>
</fontconfig>
EOF
fc-cache -f -v

# ✅ إنشاء مستخدم kiosk إذا لم يكن موجودًا
getent group kiosk >/dev/null || groupadd kiosk
id -u kiosk &>/dev/null || useradd -m -g kiosk -s /bin/bash kiosk
chown -R kiosk:kiosk /home/kiosk

# ✅ تعطيل تبديل TTY الفعلي
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# ✅ إعداد LightDM لتسجيل الدخول التلقائي
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# ✅ إعداد autostart لـ openbox
mkdir -p /home/kiosk/.config/openbox
cat > /home/kiosk/.config/openbox/autostart << 'EOF'
#!/bin/bash
unclutter -idle 0.1 -grab -root &
while true; do
  xrandr -o left
  xset -dpms && xset s off && xset s noblank
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
chmod +x /home/kiosk/.config/openbox/autostart
chown -R kiosk:kiosk /home/kiosk

echo "✅ تم التثبيت: Arial هو الخط الافتراضي والنظام يعمل بوضع Kiosk على Chromium."

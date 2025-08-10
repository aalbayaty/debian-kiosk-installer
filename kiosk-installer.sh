#!/bin/bash

# be new
apt-get update

# get software
apt-get install \
	unclutter \
    xorg \
    chromium \
    openbox \
    lightdm \
    locales \
    -y

# timedatectl set-timezone America/Guyana
  add-apt-repository multiverse

 
# dir
mkdir -p /home/kiosk/.config/openbox

# ✅ حذف خطوط DejaVu
apt-get purge -y fonts-dejavu*

# ✅ تنزيل وتثبيت خط Amiri-Regular يدوياً من GitHub
mkdir -p /usr/share/fonts/truetype/Amiri-Regular
cd /usr/share/fonts/truetype/Amiri-Regular

# استخدم رابط مباشر من مستودع موثوق
wget -qO Amiri-Regular.ttf \
 https://github.com/aalbayaty/debian-kiosk-installer/raw/refs/heads/master/amiri_font/Amiri-Regular.ttf
chmod 644 Amiri-Regular.ttf

# ✅ تحديث كاش الخطوط
fc-cache -f -v

# ✅ تعيين Amiri-Regular كخط النظام الافتراضي
mkdir -p /etc/fonts/conf.d
cat > /etc/fonts/conf.d/60-Amiri-Regular-prefer.conf << "EOF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias><family>sans-serif</family><prefer><family>Amiri-Regular</family></prefer></alias>
  <alias><family>serif</family><prefer><family>Amiri-Regular</family></prefer></alias>
  <alias><family>monospace</family><prefer><family>Amiri-Regular</family></prefer></alias>
</fontconfig>
EOF
fc-cache -f -v


# create group


# create group
getent group kiosk >/dev/null || groupadd kiosk
id -u kiosk &>/dev/null || useradd -m -g kiosk -s /bin/bash kiosk
chown -R kiosk:kiosk /home/kiosk

# create user if not exists
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash 

# rights
chown -R kiosk:kiosk /home/kiosk

# remove virtual consoles
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# create config
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# create autostart
if [ -e "/home/kiosk/.config/openbox/autostart" ]; then
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
fi
cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

unclutter -idle 0.1 -grab -root &

while :
do
# the screen will be to the left
 xrandr -o left 
# the screen will be Normal
# xrandr --auto
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
    --autoplay-policy=no-user-gesture-required \
    --incognito \
    --kiosk "https://muslimhub.net/public/location/StThomas/?Settings=tv"
  sleep 5
done &
EOF

echo "Done!"

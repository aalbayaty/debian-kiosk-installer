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

timedatectl set-timezone America/Guyana
  add-apt-repository multiverse

  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
  apt-get install ttf-mscorefonts-installer -y

# dir
mkdir -p /home/kiosk/.config/openbox

# create group
if ! getent group kiosk > /dev/null; then
  groupadd kiosk
fi

if ! id -u kiosk > /dev/null 2>&1; then
  useradd -m kiosk -g kiosk -s /bin/bash
fi

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

# ✅ إعداد Arial كخط افتراضي للنظام
mkdir -p /etc/fonts/conf.d

cat > /etc/fonts/conf.d/60-arial-prefer.conf << "EOF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Arial</family>
    </prefer>
  </alias>
</fontconfig>
EOF

fc-cache -f -v




# create autostart
if [ -e "/home/kiosk/.config/openbox/autostart" ]; then
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
fi
cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

unclutter -idle 0.1 -grab -root &

while :
do
# xrandr -o left the screen will be to the left
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
    --kiosk "https://muslimhub.net/public/location/Guyana331/?Settings=tv"
  sleep 5
done &
EOF

echo "Done!"

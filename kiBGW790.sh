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
 timedatectl set-timezone Asia/Baghdad
 
 # install fonts
 
apt-get install -y wget cabextract fontconfig

# intiate a folde
mkdir -p /usr/share/fonts/truetype/msttcorefonts
cd /usr/share/fonts/truetype/msttcorefonts

# uploading fonts 
wget -O times32.exe https://downloads.sourceforge.net/corefonts/times32.exe
wget -O arial32.exe https://downloads.sourceforge.net/corefonts/arial32.exe
 

# get the fonts
cabextract -L -F '*.ttf' arial32.exe
cabextract -L -F '*.ttf' times32.exe
 

# checking
chmod 644 *.ttf

# updating
fc-cache -fv

echo "New fonts are added"
 

# dir
mkdir -p /home/kiosk/.config/openbox

# create group
groupadd kiosk

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
    --kiosk "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv"
  sleep 5
done &
EOF

echo "Done!"

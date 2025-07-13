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

<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <description>Replace preferable fonts for Latin</description>
   <alias>
      <family>serif</family>
      <prefer>
         <family>Times New Roman</family>
         <family>DejaVu Serif</family>
         <family>Noto Serif</family>
         <family>Thorndale AMT</family>
         <family>Luxi Serif</family>
         <family>Nimbus Roman No9 L</family>
         <family>Nimbus Roman</family>
         <family>Times</family>
      </prefer>
   </alias>
   <alias>
      <family>sans-serif</family>
      <prefer>
         <family>DejaVu Sans</family>
         <family>Noto Sans</family>
         <family>Verdana</family>
         <family>Arial</family>
         <family>Albany AMT</family>
         <family>Luxi Sans</family>
         <family>Nimbus Sans L</family>
         <family>Nimbus Sans</family>
         <family>Helvetica</family>
         <family>Lucida Sans Unicode</family>
         <family>BPG Glaho International</family> <!-- lat,cyr,arab,geor -->
         <family>Tahoma</family> <!-- lat,cyr,greek,heb,arab,thai -->
      </prefer>
   </alias>
   <alias>
      <family>monospace</family>
      <prefer>
         <family>DejaVu Sans Mono</family>
         <family>Noto Mono</family>
         <family>Noto Sans Mono</family>
         <family>Inconsolata</family>
         <family>Andale Mono</family>
         <family>Courier New</family>
         <family>Cumberland AMT</family>
         <family>Luxi Mono</family>
         <family>Nimbus Mono L</family>
         <family>Nimbus Mono</family>
         <family>Nimbus Mono PS</family>
         <family>Courier</family>
      </prefer>
   </alias>
</fontconfig>





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

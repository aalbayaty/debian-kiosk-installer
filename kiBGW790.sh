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
  add-apt-repository multiverse

 # echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
 # apt-get install ttf-mscorefonts-installer -y

 # echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" |  debconf-set-selections
 # apt-get install -y ttf-mscorefonts-installer

set -e


# Define font directory
FONT_DIR="$HOME/.fonts/amiri"

# Create font directory if it doesn't exist
mkdir -p "$FONT_DIR"

# Download and extract Amiri font
# (Replace with actual download URL if needed)
# You might need to adapt this part based on how you download the font.
# Example using curl:
# curl -L "https://example.com/amiri.zip" -o "$FONT_DIR/amiri.zip"
# unzip "$FONT_DIR/amiri.zip" -d "$FONT_DIR"

# Alternatively, use wget if curl is not available
wget -O "$FONT_DIR/amiri.zip" "https://github.com/googlefonts/amiri/archive/refs/heads/main.zip"
unzip "$FONT_DIR/amiri.zip" -d "$FONT_DIR"

# Remove the zip file after extraction
rm "$FONT_DIR/amiri.zip"

# Move extracted files to system font directory
 cp "$FONT_DIR"/*.ttf /usr/share/fonts/truetype/
cp "$FONT_DIR"/*.otf /usr/share/fonts/truetype/

# Refresh font cache
fc-cache -fv
   

# Done
echo "Fonts installed successfully!"


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
    --kiosk "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv"
  sleep 5
done &
EOF
echo "Done!"

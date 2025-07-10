#!/bin/bash

# Update system
apt-get update

# Install necessary software
apt-get install \
    unclutter \
    xorg \
    firefox-esr \
    openbox \
    lightdm \
    locales \
    wget \
    unzip \
    -y

# Set timezone
timedatectl set-timezone Asia/Baghdad

# Set up Google Fonts
set -e

FONT_DIR="/usr/local/share/fonts/googlefonts"
TEMP_DIR="/tmp/googlefonts"
mkdir -p "$TEMP_DIR"
mkdir -p "$FONT_DIR"

echo "Downloading fonts..."
cd "$TEMP_DIR"
wget -q https://fonts.google.com/download?family=Amiri -O Amiri.zip
wget -q "https://fonts.google.com/download?family=Playfair+Display" -O PlayfairDisplay.zip

echo "Extracting fonts..."
unzip -o Amiri.zip "*.ttf" -d "$TEMP_DIR/Amiri"
unzip -o PlayfairDisplay.zip "*.ttf" -d "$TEMP_DIR/PlayfairDisplay"

echo "Installing fonts..."
cp "$TEMP_DIR/Amiri/"*.ttf "$FONT_DIR/"
cp "$TEMP_DIR/PlayfairDisplay/"*.ttf "$FONT_DIR/"
chmod 644 "$FONT_DIR/"*.ttf

echo "Updating font cache..."
fc-cache -fv
echo "Fonts installed successfully!"

# Setup Openbox for kiosk
mkdir -p /home/kiosk/.config/openbox

# Create group and user
groupadd kiosk
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash 
chown -R kiosk:kiosk /home/kiosk

# Disable virtual console switching
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi

cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# Configure LightDM for autologin
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi

cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# Create Openbox autostart file
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

  firefox-esr \
    --kiosk "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv" \
    --private-window \
    --no-remote

  sleep 5
done &
EOF

# Set permissions
chown kiosk:kiosk /home/kiosk/.config/openbox/autostart
chmod +x /home/kiosk/.config/openbox/autostart

echo "Done!"

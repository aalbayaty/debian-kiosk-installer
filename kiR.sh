#!/bin/bash

# Update package lists
apt-get update

# Install required packages
apt-get install -y \
    unclutter \
    xorg \
    chromium \
    openbox \
    lightdm \
    locales \
    software-properties-common  # for add-apt-repository

# Add multiverse repository (needed for some fonts)
add-apt-repository multiverse

# Create Openbox config directory for kiosk user
mkdir -p /home/kiosk/.config/openbox

# Manually download and install Taha font from GitHub
#mkdir -p /usr/share/fonts/truetype/Taha
#cd /usr/share/fonts/truetype/Taha || exit

#wget -qO Taha.ttf \
#    https://github.com/aalbayaty/debian-kiosk-installer/raw/refs/heads/master/amiri_font/Taha.ttf
#chmod 644 Taha.ttf

# Create kiosk group if it doesn't exist
getent group kiosk >/dev/null || groupadd kiosk

# Create kiosk user if it doesn't exist
id -u kiosk &>/dev/null || useradd -m -g kiosk -s /bin/bash kiosk

# Set ownership of kiosk home
chown -R kiosk:kiosk /home/kiosk

# Backup existing Xorg config if present and disable virtual console switching
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi

cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# Backup and create LightDM config for auto-login to kiosk user and openbox session
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi

cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# Backup and create Openbox autostart script
if [ -e "/home/kiosk/.config/openbox/autostart" ]; then
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
fi

################# ARABIC ###################
apt-get install -y unzip curl

curl http://dub.sh/kifont.zip -LO
mkdir /home/kiosk/.fonts
unzip kifont.zip -d /home/kiosk/.fonts
chown kiosk:kiosk /home/kiosk/.fonts -R
fc-cache -f -v

################ END OF ARABIC ################

cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

# Hide mouse cursor after 0.1 seconds of inactivity
unclutter -idle 0.1 -grab -root &

while :
do
  # Rotate screen to left orientation
  xrandr -o right

  # Disable power management and screen blanking
  xset -dpms
  xset s off
  xset s noblank

  # Launch Chromium in kiosk mode with recommended flags
  chromium \
    --no-first-run \
    --start-maximized \
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

# Make autostart script executable
chmod +x /home/kiosk/.config/openbox/autostart

echo "Setup complete!"

fc-match

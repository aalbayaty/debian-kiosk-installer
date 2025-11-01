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
    fontconfig

# Create Openbox config directory for kiosk user
mkdir -p /home/kiosk/.config/openbox

# Remove DejaVu fonts to avoid conflicts
apt-get purge -y fonts-dejavu*

# ✅ Download and install Arial font manually from GitHub
mkdir -p /usr/share/fonts/truetype/arial
cd /usr/share/fonts/truetype/arial
wget -qO arial.ttf \
  https://raw.githubusercontent.com/kavin808/arial.ttf/master/arial.ttf
chmod 644 arial.ttf

# ✅ Update font cache
fc-cache -f -v

# ✅ Set Arial as the system default font
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

# Create kiosk group if it doesn't exist
getent group kiosk >/dev/null || groupadd kiosk

# Create kiosk user if it doesn't exist
id -u kiosk &>/dev/null || useradd -m -g kiosk -s /bin/bash kiosk

# Set ownership of kiosk home
chown -R kiosk:kiosk /home/kiosk

# Backup existing Xorg config if present and disable virtual-console switching
[ -e "/etc/X11/xorg.conf" ] && mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# Backup and create LightDM config for auto-login
[ -e "/etc/lightdm/lightdm.conf" ] && mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
mkdir -p /etc/lightdm
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
# xrandr -o left 
# the screen will be Normal
  xrandr --auto
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
    --kiosk "https://muslimhub.net/public/location/wide/hyatt/?Settings=TVh"
  sleep 5
done &
EOF

echo "Done!"

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

# Manually download and install Taha font from GitHub
mkdir -p /usr/share/fonts/truetype/Taha
cd /usr/share/fonts/truetype/Taha || exit

wget -qO Taha.ttf \
    https://github.com/aalbayaty/debian-kiosk-installer/raw/refs/heads/master/amiri_font/Taha.ttf
chmod 644 Taha.ttf

# Update font cache
fc-cache -f -v

# Set Taha as the preferred default font for sans-serif, serif, and monospace families
mkdir -p /etc/fonts/conf.d
cat > /etc/fonts/conf.d/60-Taha-prefer.conf << EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family" compare="contains">
      <string>sans-serif</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>Taha</string>
    </edit>
  </match>
  <match target="pattern">
    <test name="family" compare="contains">
      <string>serif</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>Taha</string>
    </edit>
  </match>
  <match target="pattern">
    <test name="family" compare="contains">
      <string>monospace</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>Taha</string>
    </edit>
  </match>
</fontconfig>
EOF

# Update font cache again after config change
fc-cache -f -v

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
else
  mkdir -p /etc/lightdm/
  touch /etc/lightdm/lightdm.conf
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

cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

# Hide mouse cursor after 0.1 seconds of inactivity
unclutter -idle 0.1 -grab -root &

while :
do
  # Rotate screen to left orientation
  xrandr -o left

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

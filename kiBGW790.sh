#!/bin/bash
set -e

# ✅ Update the system and install essential packages
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

# ✅ Set the time zone
timedatectl set-timezone Asia/Baghdad

# ✅ Remove DejaVu fonts
apt-get purge -y fonts-dejavu*

# ✅ Download and manually install the Arial font from GitHub
mkdir -p /usr/share/fonts/truetype/arial
cd /usr/share/fonts/truetype/arial

# Use a direct link from a trusted repository
wget -qO arial.ttf \
  https://raw.githubusercontent.com/kavin808/arial.ttf/master/arial.ttf
chmod 644 arial.ttf

# ✅ Update the font cache
fc-cache -f -v

# ✅ Set Arial as the default system font
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

# ✅ Create the kiosk user if it doesn't exist
getent group kiosk >/dev/null || groupadd kiosk
id -u kiosk &>/dev/null || useradd -m -g kiosk -s /bin/bash kiosk
chown -R kiosk:kiosk /home/kiosk

# ✅ Disable actual TTY switching
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# ✅ Set up LightDM for auto-login
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# ✅ Set up autostart for openbox
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

echo "✅ Installation complete: Arial is the default font, and the system is running in Kiosk mode on Chromium."

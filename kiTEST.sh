#!/bin/bash

# ✅ Update system packages
apt-get update

# ✅ Install required packages
apt-get install -y \
  unclutter \
  xorg \
  chromium \
  openbox \
  lightdm \
  locales \
  dialog \
  network-manager \
  xterm \
  ttf-mscorefonts-installer

# ✅ Accept Microsoft fonts license
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

# ✅ Remove DejaVu fonts
apt-get purge -y fonts-dejavu*

# ✅ Download and install Arial font
mkdir -p /usr/share/fonts/truetype/arial
cd /usr/share/fonts/truetype/arial
wget -qO arial.ttf https://raw.githubusercontent.com/kavin808/arial.ttf/master/arial.ttf
chmod 644 arial.ttf
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

# ✅ Create kiosk user and group if not exist
getent group kiosk >/dev/null || groupadd kiosk
id -u kiosk &>/dev/null || useradd -m -g kiosk -s /bin/bash kiosk
chown -R kiosk:kiosk /home/kiosk

# ✅ Prevent switching virtual consoles (X11)
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# ✅ Configure LightDM for auto-login with Openbox
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# ✅ Create Openbox autostart with Wi-Fi prompt
mkdir -p /home/kiosk/.config/openbox
cat > /home/kiosk/.config/openbox/autostart << 'EOF'
#!/bin/bash

# Hide mouse cursor
unclutter -idle 0.1 -grab -root &

# Show 5-second dialog to ask if user wants to configure Wi-Fi
(
  dialog --timeout 5 --stdout --yesno "Do you want to change your Wi-Fi name and password?" 7 60
  if [ $? -eq 0 ]; then
    # User selected "Yes"
    xterm -e nmtui-connect
  fi
) &

# Wait for dialog before launching browser
sleep 6

# Disable screen blanking
xrandr -o right
xset -dpms
xset s off
xset s noblank

# Launch Chromium in kiosk mode
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
EOF

# ✅ Set permissions
# chown -R kiosk:kiosk /home/kiosk
# chmod +x /home/kiosk/.config/openbox/autostart

# ✅ OPTIONAL: Auto-connect to predefined Wi-Fi (uncomment and edit if needed)
# nmcli device wifi rescan
# nmcli connection delete id "MyWiFi" &>/dev/null || true
# nmcli device wifi connect "MyWiFi" password "MyPassword123" name "MyWiFi"
# nmcli connection modify "MyWiFi" connection.autoconnect yes

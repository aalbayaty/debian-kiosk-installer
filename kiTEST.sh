#!/bin/bash
# This script must be run as root or with sudo.

echo "--- Starting Kiosk Setup for Debian 12 ---"

# --- 1. System Update and Prerequisities ---
apt-get update
# software-properties-common is needed for 'add-apt-repository' functionality
apt-get install software-properties-common -y

# --- 2. Enable 'contrib' and 'non-free' for extra packages ---
# This is the correct way to add repositories in Debian
echo "--> Enabling contrib and non-free repositories..."
add-apt-repository "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware"
apt-get update

# --- 3. Install Software ---
echo "--> Installing required packages..."
# Auto-accept the EULA for Microsoft fonts
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

apt-get install \
	unclutter \
    xorg \
    chromium \
    openbox \
    lightdm \
    locales \
    ttf-mscorefonts-installer \
    -y

# --- 4. System Configuration ---
echo "--> Setting timezone..."
timedatectl set-timezone Asia/Baghdad

# --- 5. Create Kiosk User and Group Safely ---
echo "--> Creating kiosk user and group..."
# Create group only if it doesn't exist
if ! getent group kiosk > /dev/null; then
    groupadd kiosk
fi
# Create user only if it doesn't exist
if ! id -u kiosk &>/dev/null; then
    useradd -m kiosk -g kiosk -s /bin/bash
fi

# --- 6. Configure Xorg (Disable VT Switching) ---
echo "--> Configuring Xorg..."
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# --- 7. Configure LightDM for Autologin ---
echo "--> Configuring LightDM for autologin..."
# Create the directory just in case
mkdir -p /etc/lightdm/
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# --- 8. Configure System Fonts ---
echo "--> Configuring system fonts..."
# This XML data now goes into its own correct file.
cat > /etc/fonts/local.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <description>Replace preferable fonts for Latin</description>
   <alias>
      <family>serif</family>
      <prefer>
         <family>Times New Roman</family>
         <family>DejaVu Serif</family>
      </prefer>
   </alias>
   <alias>
      <family>sans-serif</family>
      <prefer>
         <family>DejaVu Sans</family>
         <family>Verdana</family>
         <family>Arial</family>
      </prefer>
   </alias>
   <alias>
      <family>monospace</family>
      <prefer>
         <family>DejaVu Sans Mono</family>
         <family>Inconsolata</family>
         <family>Courier New</family>
      </prefer>
   </alias>
</fontconfig>
EOF
# Update the font cache
fc-cache -fv

# --- 9. Create Openbox Autostart Script ---
echo "--> Creating Openbox autostart script..."
# Create config directory for the kiosk user
mkdir -p /home/kiosk/.config/openbox

cat > /home/kiosk/.config/openbox/autostart << 'EOF'
#!/bin/bash

# Hide the mouse cursor
unclutter -idle 0.1 -grab -root &

# Loop to ensure the browser restarts if it crashes
while :
do
  # Screen and power configuration
  xrandr -o left
  xset -dpms
  xset s off
  xset s noblank

  # Launch Chromium in kiosk mode
  chromium \
    --no-first-run \
    --start-maximized \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --incognito \
    --kiosk "https://muslimhub.net/public/Ar/location/BGW790/?Settings=tv"
  
  # Wait before restarting the browser if it closes
  sleep 5
done &
EOF

# --- 10. Set Final Permissions ---
echo "--> Setting final permissions..."
chown -R kiosk:kiosk /home/kiosk
chmod +x /home/kiosk/.config/openbox/autostart

echo ""
echo "✅ Done! Reboot the system to start the kiosk."

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
    software-properties-common \
    curl \
    unzip \
    network-manager \
    zenity # <--- ADDED Wi-Fi packages

# --- MODIFIED: Use correct Debian repos instead of Ubuntu's "multiverse" ---
add-apt-repository "deb http://deb.debian.org/debian/ bookworm main contrib non-free-firmware"
apt-get update # Run update again after adding repo

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

# <--- ADDED: Give kiosk user permission to manage networks --->
echo "Giving kiosk user network permissions..."
usermod -aG netdev kiosk

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
# This section was already in your script
mkdir /home/kiosk/.fonts
curl http://dub.sh/kifont.zip -LO
unzip kifont.zip -d /home/kiosk/.fonts
chown kiosk:kiosk /home/kiosk/.fonts -R
fc-cache -f -v

################ END OF ARABIC ################


# <--- ADDED: Create the Wi-Fi setup helper script --->
echo "Creating Wi-Fi setup script..."
cat > /usr/local/bin/kiosk-wifi-setup.sh << 'EOF'
#!/bin/bash
# This script is run by Openbox to configure Wi-Fi at startup.
# It requires zenity and network-manager.

# 1. Ask user if they want to configure Wi-Fi, with a 10-second timeout
zenity --question --title="Network Setup" --text="Do you want to change Wi-Fi settings?" --timeout=10

# $? is the exit code. 0 = Yes, 1 = No, 5 = Timeout.
if [ $? -ne 0 ]; then
  # User selected "No" or timed out, so we exit.
  exit 0
fi

# 2. User said "Yes". Scan for networks and show a list.
# We rescan, get the SSID, filter out duplicates, and show in Zenity.
SSID=$(nmcli --colors no -f SSID dev wifi list --rescan yes | sed '/^--/d' | uniq | zenity --list --title="Select Wi-Net Network" --column="Network")

if [ -z "$SSID" ]; then
  # User pressed "Cancel"
  exit 0
fi

# 3. Ask for the password
PASSWORD=$(zenity --password --title="Password for $SSID")

if [ $? -ne 0 ]; then
  # User pressed "Cancel"
  exit 0
fi

# 4. Try to connect
# We pipe the output to zenity to show a "Connecting..." progress bar
nmcli dev wifi connect "$SSID" password "$PASSWORD" | zenity --progress \
    --title="Connecting..." \
    --text="Attempting to connect to $SSID" \
    --pulsate --auto-close --no-cancel

# 5. Check if connection was successful
# We check for the new connection name in the list of active connections.
if nmcli -t -f NAME con show --active | grep -q "$SSID"; then
  zenity --info --text="Successfully connected to $SSID" --timeout=3
else
  zenity --error --text="Failed to connect. Please try again on next reboot."
fi

exit 0
EOF
# Make the helper script executable
chmod +x /usr/local/bin/kiosk-wifi-setup.sh
# <--- END ADDED --->


cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

# <--- ADDED: Run the Wi-Fi helper script *before* anything else --->
# The script will pause here for 10 seconds (or until user interaction)
/usr/local/bin/kiosk-wifi-setup.sh

# Hide mouse cursor after 0.1 seconds of inactivity
unclutter -idle 0.1 -grab -root &

while :
do
  # Rotate screen to right orientation (as in your original script)
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

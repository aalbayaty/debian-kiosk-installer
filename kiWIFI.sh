#!/bin/bash
set -e

echo "🚀 Starting Debian 12 Kiosk setup..."

# --- Update packages ---
apt-get update

# --- Install required packages ---
apt-get install -y \
  xorg \
  openbox \
  lightdm \
  chromium \
  unclutter \
  curl \
  unzip \
  zenity \
  network-manager \
  locales

# --- Enable LightDM to start automatically ---
systemctl enable lightdm

# --- Configure locales for Arabic ---
echo "Configuring Arabic locale..."
sed -i 's/# ar_EG.UTF-8 UTF-8/ar_EG.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=ar_EG.UTF-8

# --- Create kiosk user if not exists ---
if ! id "kiosk" &>/dev/null; then
  echo "Creating kiosk user..."
  useradd -m -G netdev -s /bin/bash kiosk
fi

# --- Make sure ownership is correct ---
chown -R kiosk:kiosk /home/kiosk

# --- Configure LightDM for auto-login ---
echo "Setting up LightDM autologin..."
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-kiosk.conf <<EOF
[Seat:*]
autologin-user=kiosk
user-session=openbox
EOF

# --- Configure Xorg (disable VT switching) ---
cat > /etc/X11/xorg.conf <<EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# --- Install Arabic fonts (custom) ---
echo "Installing Arabic fonts..."
mkdir -p /home/kiosk/.fonts
curl -L http://dub.sh/kifont.zip -o /tmp/kifont.zip
unzip -o /tmp/kifont.zip -d /home/kiosk/.fonts
chown -R kiosk:kiosk /home/kiosk/.fonts
fc-cache -fv

# --- Create Wi-Fi setup script ---
echo "Creating Wi-Fi setup helper..."
cat > /usr/local/bin/kiosk-wifi-setup.sh <<'EOF'
#!/bin/bash

# Run inside X session only
if [ -z "$DISPLAY" ]; then
  echo "No display detected; skipping Wi-Fi setup."
  exit 0
fi

# Ask user to configure Wi-Fi
zenity --question --title="Network Setup" --text="Do you want to change Wi-Fi settings?" --timeout=10
if [ $? -ne 0 ]; then exit 0; fi

# Show available SSIDs
SSID=$(nmcli -f SSID dev wifi list --rescan yes | sed '/^--/d;/^$/d' | uniq | zenity --list --title="Select Wi-Fi Network" --column="Network")
if [ -z "$SSID" ]; then exit 0; fi

# Ask for password
PASSWORD=$(zenity --password --title="Password for $SSID")
if [ $? -ne 0 ]; then exit 0; fi

# Try to connect
nmcli dev wifi connect "$SSID" password "$PASSWORD" | zenity --progress \
  --title="Connecting..." \
  --text="Attempting to connect to $SSID" \
  --pulsate --auto-close --no-cancel

# Verify connection
if nmcli -t -f NAME con show --active | grep -q "$SSID"; then
  zenity --info --text="✅ Connected successfully to $SSID" --timeout=3
else
  zenity --error --text="❌ Failed to connect. Try again after reboot."
fi
EOF

chmod +x /usr/local/bin/kiosk-wifi-setup.sh

# --- Create Openbox autostart script ---
echo "Setting up Openbox autostart..."
mkdir -p /home/kiosk/.config/openbox
cat > /home/kiosk/.config/openbox/autostart <<'EOF'
#!/bin/bash

# Run Wi-Fi setup before starting kiosk
/usr/local/bin/kiosk-wifi-setup.sh

# Hide mouse cursor after 0.1s
unclutter -idle 0.1 -grab -root &

# Keep kiosk loop running
while true; do
  xrandr -o right
  xset -dpms
  xset s off
  xset s noblank

  chromium \
    --no-first-run \
    --start-maximized \
    --disable-translate \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --autoplay-policy=no-user-gesture-required \
    --incognito \
    --kiosk "https://muslimhub.net/public/location/StThomas/?Settings=tv"

  sleep 5
done &
EOF

chmod +x /home/kiosk/.config/openbox/autostart
chown -R kiosk:kiosk /home/kiosk/.config

echo "✅ Setup complete! Reboot to start kiosk mode."

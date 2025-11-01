#!/bin/bash

# ── Check and install curl if needed ──────────────────────────────────────────
if ! command -v curl &> /dev/null; then
    apt-get update > /dev/null 2>&1
    apt-get install -y curl > /dev/null 2>&1
    
    if ! command -v curl &> /dev/null; then
        zenity --error --text="Failed to install curl" --width=300
        exit 1
    fi
fi

# ── Check and install zenity if needed ────────────────────────────────────────
if ! command -v zenity &> /dev/null; then
    apt-get update > /dev/null 2>&1
    apt-get install -y zenity > /dev/null 2>&1
    
    if ! command -v zenity &> /dev/null; then
        echo "Error: Failed to install zenity"
        exit 1
    fi
fi

# ── Pick the kiosk location using location code ──────────────────────────────
location_code=$(zenity --entry \
  --title="MuslimHub Kiosk Setup" \
  --text="Enter the location code for the muslimhub application:" \
  --width=400)

# Check if user cancelled
if [ $? -ne 0 ]; then
    zenity --info --text="Setup cancelled" --width=300
    exit 0
fi

# Validate that a code was entered
if [[ -z "$location_code" ]]; then
  zenity --error --text="Location code cannot be empty" --width=300
  exit 1
fi

# Validate the location code by checking the URL
CHECK_URL="https://muslimhub.net/location/${location_code}"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$CHECK_URL")

if [[ "$HTTP_STATUS" == "200" ]]; then
  zenity --info --text="✓ Location code validated successfully" --timeout=2 --width=300
elif [[ "$HTTP_STATUS" == "204" ]]; then
  zenity --error --text="Location not found (HTTP 204)\n\nThe location code '$location_code' does not exist." --width=400
  exit 1
elif [[ "$HTTP_STATUS" == "000" ]]; then
  zenity --error --text="Unable to connect to muslimhub.net\n\nPlease check your internet connection." --width=400
  exit 1
else
  zenity --error --text="Invalid location code (HTTP $HTTP_STATUS)\n\nThe location code '$location_code' is not valid." --width=400
  exit 1
fi

# ── Select display type ───────────────────────────────────────────────────────
display_input=$(zenity --list \
  --title="Display Type" \
  --text="Select display type:" \
  --column="Option" \
  --column="Description" \
  "tv" "TV display (default)" \
  "tvh" "TV display horizontal mode" \
  "custom" "Enter custom display code" \
  --width=500 \
  --height=300)

# Check if user cancelled
if [ $? -ne 0 ]; then
    zenity --info --text="Setup cancelled" --width=300
    exit 0
fi

# Set default to 'tv' if empty
if [[ -z "$display_input" ]]; then
  DISPLAY_CODE="tv"
elif [[ "$display_input" == "custom" ]]; then
  custom_display=$(zenity --entry \
    --title="Custom Display Code" \
    --text="Enter custom display code:" \
    --width=400)
  
  if [[ -z "$custom_display" ]]; then
    zenity --error --text="Custom display code cannot be empty" --width=300
    exit 1
  fi
  DISPLAY_CODE="$custom_display"
else
  DISPLAY_CODE="$display_input"
fi

# Build URL using the code and display type
KIOSK_URL="https://muslimhub.net/public/location/${location_code}/?Settings=${DISPLAY_CODE}"

# ── Select screen rotation ────────────────────────────────────────────────────
ROTATION=$(zenity --list \
  --title="Screen Rotation" \
  --text="Select screen rotation:" \
  --column="Option" \
  --column="Description" \
  "normal" "Landscape (no rotation)" \
  "left" "Portrait (counter-clockwise)" \
  "right" "Portrait (clockwise)" \
  --width=500 \
  --height=300)

# Check if user cancelled
if [ $? -ne 0 ]; then
    zenity --info --text="Setup cancelled" --width=300
    exit 0
fi

# Validate rotation
case "$ROTATION" in
  left|right|normal)
    ;;
  *)
    zenity --error --text="Invalid rotation '$ROTATION'" --width=300
    exit 1
    ;;
esac

# Show configuration summary
zenity --info \
  --title="Configuration Summary" \
  --text="<b>Selected Configuration:</b>\n\n<b>URL:</b> $KIOSK_URL\n\n<b>Display Type:</b> $DISPLAY_CODE\n\n<b>Rotation:</b> $ROTATION" \
  --width=500 \
  --height=250

# ───────────────────────────────────────────────────────────────────────────────
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
    fontconfig \
    zenity \
    network-manager \
    network-manager-gnome \
    xterm

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

# Backup and create Openbox autostart script
[ -e "/home/kiosk/.config/openbox/autostart" ] && \
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash
# Hide mouse cursor after 0.1 seconds of inactivity
unclutter -idle 0.1 -grab -root &

# Network configuration prompt
timeout 10 zenity --question \
  --title="Network Setup" \
  --text="Click OK to configure network connection\n\nAuto-continuing in 10 seconds..." \
  --ok-label="Configure Network" \
  --cancel-label="Skip" \
  --width=400 \
  --height=150

if [ \$? -eq 0 ]; then
  # User clicked OK - ask which type of network
  NETWORK_TYPE=\$(zenity --list \
    --title="Network Type" \
    --text="Select your network connection type:" \
    --column="Option" \
    "WiFi" \
    "Ethernet" \
    --width=400 \
    --height=250)
  
  if [ "\$NETWORK_TYPE" = "WiFi" ] || [ "\$NETWORK_TYPE" = "Ethernet" ]; then
    # Launch GUI network manager
    nm-connection-editor &
    
    # Wait for network manager window to close or timeout
    zenity --info \
      --title="Network Configuration" \
      --text="Click OK when finished configuring network" \
      --timeout=120 \
      --width=400
  fi
fi

while :
do
  # Rotate screen to selected orientation
  xrandr -o $ROTATION
  
  # Disable power management and screen blanking
  xset -dpms
  xset s off
  xset s noblank
  
  # Launch Chromium in kiosk mode
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
    --kiosk "$KIOSK_URL"
  
  sleep 5
done &
EOF

chmod +x /home/kiosk/.config/openbox/autostart

echo ""
echo "Setup complete!"
echo "URL: $KIOSK_URL"
echo "Rotation: $ROTATION"
echo ""
fc-match    

# Countdown with cancel option using zenity
(
for i in {10..1}; do
  echo "# Restarting in $i seconds..."
  echo $((100 - i * 10))
  sleep 1
done
) | zenity --progress \
  --title="Setup Complete" \
  --text="System will restart soon...\nURL: $KIOSK_URL" \
  --percentage=0 \
  --auto-close \
  --width=400

echo "Restarting now..."
reboot

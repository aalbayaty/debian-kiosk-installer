#!/bin/bash


# ── Pick the kiosk location using location code ──────────────────────────────
echo "Enter the location code for the muslimhub application."
echo ""
read -p "Enter location code: " location_code

# Validate that a code was entered
if [[ -z "$location_code" ]]; then
  echo "Error: Location code cannot be empty"
  exit 1
fi

# Validate the location code by checking the URL
echo "Validating location code..."
CHECK_URL="https://muslimhub.net/location/${location_code}"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$CHECK_URL")

if [[ "$HTTP_STATUS" == "200" ]]; then
  echo "✓ Location code validated successfully."
elif [[ "$HTTP_STATUS" == "204" ]]; then
  echo "Error: Location not found (HTTP 204)"
  echo "The location code '$location_code' does not exist."
  exit 1
elif [[ "$HTTP_STATUS" == "000" ]]; then
  echo "Error: Unable to connect to muslimhub.net"
  echo "Please check your internet connection."
  exit 1
else
  echo "Error: Invalid location code (HTTP $HTTP_STATUS)"
  echo "The location code '$location_code' is not valid."
  exit 1
fi

# ── Select display type ───────────────────────────────────────────────────────
echo ""
echo "Display type options (press enter if you're not sure):"
echo "  tv      - TV display (default)"
echo "  tvh     - TV display horizontal mode"
echo ""
read -p "Enter display type [tv]: " display_input

# Set default to 'tv' if empty
if [[ -z "$display_input" ]]; then
  DISPLAY_CODE="tv"
elif [[ "$display_input" == "custom" ]]; then
  read -p "Enter custom display code: " custom_display
  if [[ -z "$custom_display" ]]; then
    echo "Error: Custom display code cannot be empty"
    exit 1
  fi
  DISPLAY_CODE="$custom_display"
else
  DISPLAY_CODE="$display_input"
fi

# Build URL using the code and display type
KIOSK_URL="https://muslimhub.net/public/location/${location_code}/?Settings=${DISPLAY_CODE}"

# ── Select screen rotation ────────────────────────────────────────────────────
echo ""
echo "Screen rotation options:"
echo "  left   - Portrait (counter-clockwise)"
echo "  right  - Portrait (clockwise)"
echo "  normal - Landscape (no rotation)"
echo ""
read -p "Enter rotation (left/right/normal): " rotation_input

case "$rotation_input" in
  left|right|normal)
    ROTATION="$rotation_input"
    ;;
  *)
    echo "Error: Invalid rotation '$rotation_input'"
    exit 1
    ;;
esac

echo ""
echo "Selected Location Code: $location_code"
echo "Selected Display Type: $DISPLAY_CODE"
echo "Selected URL: $KIOSK_URL"
echo "Selected Rotation: $ROTATION"
echo ""

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

# Backup and create Openbox autostart script
[ -e "/home/kiosk/.config/openbox/autostart" ] && \
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash
# Hide mouse cursor after 0.1 seconds of inactivity
unclutter -idle 0.1 -grab -root &

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
echo "Configuration:"
echo "  Location Code: $location_code"
echo "  Display Type: $DISPLAY_CODE"
echo "  URL: $KIOSK_URL"
echo "  Rotation: $ROTATION"
echo ""
fc-match    

# Countdown with cancel option
for i in {10..1}; do
  echo -ne "Restarting in $i seconds... Press Ctrl+C to cancel\r"
  sleep 1
done

echo ""
echo "Restarting now..."
reboot

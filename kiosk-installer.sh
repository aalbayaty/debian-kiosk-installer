#!/bin/bash

# ── Pick the kiosk URL ───────────────────────────────────────────────────────
PS3="Select the kiosk location (1-5): "
options=(
  "Location 1|https://muslimhub.net/public/location/StThomas/?Settings=tv"
  "Location 2|https://muslimhub.net/public/location/StThomas2/?Settings=tv"
  "Location 3|https://muslimhub.net/public/location/StThomas3/?Settings=tv"
  "Location 4|https://muslimhub.net/public/location/StThomas4/?Settings=tv"
  "Location 5|https://muslimhub.net/public/location/StThomas5/?Settings=tv"
)

# Display options with short names
for i in "${!options[@]}"; do
  echo "$((i+1))) ${options[$i]%%|*}"
done

read -p "Select the kiosk location (1-5): " selection
KIOSK_URL=$(echo "${options[$((selection-1))]}" | cut -d'|' -f2)

# ── Select screen rotation ────────────────────────────────────────────────────
PS3="Select screen rotation (1-3): "
rotation_options=(
  "Left (portrait - counter-clockwise)"
  "Right (portrait - clockwise)"
  "Normal (landscape - no rotation)"
)

select rot_opt in "${rotation_options[@]}"; do
  case $REPLY in
    1) ROTATION="left"; break ;;
    2) ROTATION="right"; break ;;
    3) ROTATION="normal"; break ;;
    *) echo "Invalid selection. Please try again." ;;
  esac
done

echo ""
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
echo "  URL: $KIOSK_URL"
echo "  Rotation: $ROTATION"
echo ""
fc-match

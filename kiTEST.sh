
#!/bin/bash

# --- 1. CONFIGURATION AND INITIAL SETUP ---
set -e
# Ensure commands fail immediately if any command returns a non-zero exit status
export DEBIAN_FRONTEND=noninteractive
# Prevents interactive configuration prompts during installation

readonly KIOSK_USER="kiosk"
readonly KIOSK_URL="https://muslimhub.net/public/location/StThomas/?Settings=tv"
readonly FONT_NAME="Taha"
readonly FONT_URL="https://github.com/aalbayaty/debian-kiosk-installer/raw/refs/heads/master/amiri_font/Taha.ttf"
readonly FONT_DIR="/usr/share/fonts/truetype/${FONT_NAME}"
readonly OPENBOX_CONFIG_DIR="/home/${KIOSK_USER}/.config/openbox"

echo "Starting Kiosk setup for user: ${KIOSK_USER}..."

# --- 2. PACKAGE INSTALLATION ---
echo "Updating package lists and installing core packages..."
apt update

# Install software-properties-common first if needed for add-apt-repository
apt install -y software-properties-common

# Add multiverse repository (needed for some fonts/packages if standard repos are limited)
if ! grep -q "multiverse" /etc/apt/sources.list; then
   echo "Adding multiverse repository..."
   add-apt-repository -y multiverse
   apt update
fi

apt install -y \
   unclutter \
   xserver-xorg \
   chromium \
   openbox \
   lightdm \
   locales \
   xrandr \
   fontconfig \
   wget \
   x11-xserver-utils # for xset

# Remove DejaVu fonts to avoid potential conflicts/overrides
echo "Purging conflicting fonts (fonts-dejavu*)..."
apt purge -y fonts-dejavu*

# --- 3. FONT INSTALLATION AND CONFIGURATION ---
echo "Downloading and installing custom font (${FONT_NAME})..."
# 3.1 Download and install font
mkdir -p "${FONT_DIR}"
if command -v wget >/dev/null; then
   wget -qO "${FONT_DIR}/${FONT_NAME}.ttf" "${FONT_URL}"
else
   echo "Error: wget is required but was not found. Please install it manually." >&2
   exit 1
fi
chmod 644 "${FONT_DIR}/${FONT_NAME}.ttf"

# 3.2 Create font configuration to prioritize Taha
echo "Creating font configuration file..."
cat > /etc/fonts/conf.d/60-${FONT_NAME}-prefer.conf << EOL
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
 <match target="pattern">
   <test name="family" compare="contains"><string>sans-serif</string></test>
   <edit name="family" mode="assign" binding="strong"><string>${FONT_NAME}</string></edit>
 </match>
 <match target="pattern">
   <test name="family" compare="contains"><string>serif</string></test>
   <edit name="family" mode="assign" binding="strong"><string>${FONT_NAME}</string></edit>
 </match>
 <match target="pattern">
   <test name="family" compare="contains"><string>monospace</string></test>
   <edit name="family" mode="assign" binding="strong"><string>${FONT_NAME}</string></edit>
 </match>
</fontconfig>
EOL

# 3.3 Update font cache
echo "Updating font cache..."
fc-cache -f -v

# --- 4. KIOSK USER SETUP ---
echo "Creating/verifying kiosk user and configuration directories..."
# Create kiosk group if it doesn't exist
getent group "${KIOSK_USER}" >/dev/null || groupadd "${KIOSK_USER}"
# Create kiosk user if it doesn't exist
id -u "${KIOSK_USER}" &>/dev/null || useradd -m -g "${KIOSK_USER}" -s /bin/bash "${KIOSK_USER}"
# Create openbox config directory
mkdir -p "${OPENBOX_CONFIG_DIR}"

# Set ownership of kiosk home
chown -R "${KIOSK_USER}":"${KIOSK_USER}" "/home/${KIOSK_USER}"

# --- 5. SYSTEM CONFIGURATION FILES ---

# 5.1 Xorg Configuration (Disable Virtual Terminal Switching)
echo "Configuring Xorg to disable VT switching..."
# Simple replacement/creation of xorg.conf (backing up previous version)
mv -f /etc/X11/xorg.conf /etc/X11/xorg.conf.backup 2>/dev/null || : # Ignore if no file exists
cat > /etc/X11/xorg.conf << EOF_XORG
Section "ServerFlags"
   Option "DontVTSwitch" "true"
EndSection
EOF_XORG

# 5.2 LightDM Configuration (Auto-login)
echo "Configuring LightDM for auto-login to Openbox session..."
# Simple replacement/creation of lightdm.conf (backing up previous version)
mv -f /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup 2>/dev/null || : # Ignore if no file exists
cat > /etc/lightdm/lightdm.conf << EOF_LIGHTDM
[SeatDefaults]
autologin-user=${KIOSK_USER}
user-session=openbox
# Optional: Set the greeter timeout to 0 for faster boot
autologin-user-timeout=0
EOF_LIGHTDM

# 5.3 Openbox Autostart Script
echo "Creating Openbox autostart script..."
OPENBOX_AUTORUN="${OPENBOX_CONFIG_DIR}/autostart"
mv -f "${OPENBOX_AUTORUN}" "${OPENBOX_AUTORUN}.backup" 2>/dev/null || : # Ignore if no file exists

cat > "${OPENBOX_AUTORUN}" << EOF_AUTOSTART
#!/bin/bash

# Hide mouse cursor after 0.1 seconds of inactivity
unclutter -idle 0.1 -grab -root &

# Permanent loop to restart Chromium if it closes
while true; do
 # --- Display/Power Management Settings ---
 # Rotate screen (change 'left' to 'normal', 'right', or 'inverted' as needed)
 xrandr -o left

 # Disable power management and screen blanking/screensaver
 xset -dpms
 xset s off
 xset s noblank

 # --- Launch Chromium Kiosk ---
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
   --kiosk "${KIOSK_URL}"

 # Sleep for a short time before restarting Chromium if it crashes/exits
 # This prevents a rapid restart loop from locking the system if the crash is immediate.
 sleep 5
done &
EOF_AUTOSTART

# Make autostart script executable
chmod +x "${OPENBOX_AUTORUN}"

echo "--- Kiosk Setup Complete! ---"
echo "The system is configured to auto-login to the '${KIOSK_USER}' user and launch Chromium."
echo "Please reboot the system now to apply all changes."

fc-match "${FONT_NAME}"

#!/bin/bash

# dir
mkdir -p /target/home/kiosk/.config/openbox
mkdir -p /target/etc/X11
mkdir -p /target/etc/lightdm



# remove virtual consoles
if [ -e "/target/etc/X11/xorg.conf" ]; then
  mv /target/etc/X11/xorg.conf /target/etc/X11/xorg.conf.backup
fi
cat > /target/etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# create config
if [ -e "/target/etc/lightdm/lightdm.conf" ]; then
  mv /target/etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi
cat > /target/etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# create autostart
if [ -e "/target/home/kiosk/.config/openbox/autostart" ]; then
  mv /target/home/kiosk/.config/openbox/autostart /target/home/kiosk/.config/openbox/autostart.backup
fi
cat > /target/home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

unclutter -idle 0.1 -grab -root &

while :
do
# xrandr -o left the screen will be to the left
xrandr -o left
xset -dpms
xset s off
xset s noblank
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
    --kiosk "https://muslimhub.net/public/location/Guyana331/?Settings=tv"
  sleep 5
done &
EOF

chmod 777 /target/home/kiosk/.config/openbox -R

echo "Done!"

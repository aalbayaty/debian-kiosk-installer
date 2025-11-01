#!/bin'bash
# This is the script at /usr/local/bin/kiosk-wifi-setup.sh

# 1. This is the "ask to chose" part (with a 10-second timeout)
zenity --question --title="Network Setup" --text="Do you want to change Wi-Fi settings?" --timeout=10

# $? is the exit code. 0 = Yes, 1 = No, 5 = Timeout.
if [ $? -ne 0 ]; then
  # User selected "No" or timed out, so we exit.
  exit 0
fi

# 2. This is the "shows the available ssid to chose one" part
# It scans, filters duplicates, and shows a list you can click.

SSID=$(nmcli --colors no -f SSID dev wifi list --rescan yes | sed '/^--/d' | uniq | zenity --list --title="Select Wi-Net Network" --column="Network")

if [ -z "$SSID" ]; then
  # User pressed "Cancel"
  exit 0
fi

# 3. This asks for the password for the network you selected
PASSWORD=$(zenity --password --title="Password for $SSID")

if [ $? -ne 0 ]; then
  # User pressed "Cancel"
  exit 0
fi

# 4. This connects to the network
nmcli dev wifi connect "$SSID" password "$PASSWORD" | zenity --progress \
    --title="Connecting..." \
    --text="Attempting to connect to $SSID" \
    --pulsate --auto-close --no-cancel

# ... (rest of the script) ...

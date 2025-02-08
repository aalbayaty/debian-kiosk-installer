#!/bin/bash

# Ensure NetworkManager is installed
if ! command -v nmcli &> /dev/null; then
  echo "NetworkManager (nmcli) is required. Installing now..."
  sudo apt update && sudo apt install -y network-manager
fi

# Initial delay with prompt
echo "Waiting for 10 seconds... Press 'Y' to change Wi-Fi settings. Otherwise, the kiosk will start automatically."
read -t 10 -n 1 -r user_input

# Check if RJ45 (Ethernet) connection is active
wired_connection=$(nmcli device status | grep ethernet | grep connected)

if [ "$wired_connection" ]; then
  echo "Wired connection detected. Using it by default."
else
  echo "No wired connection detected. Checking Wi-Fi settings..."
fi

# If user pressed 'Y' or 'y', proceed to configure Wi-Fi
if [[ $user_input == [Yy] ]]; then
  echo "Scanning for available Wi-Fi networks..."
  nmcli device wifi rescan
  sleep 2
  echo "Available Wi-Fi Networks:"
  nmcli device wifi list

  # Ask for the Wi-Fi SSID
  echo "Enter the SSID you want to connect to:"
  read ssid

  # Ask for the Wi-Fi password
  echo "Enter the Wi-Fi password:"
  read -s password

  # Ask for the Security Type
  echo "Select Security Type (WPA, WPA2, WEP, or leave empty for open):"
  read security_type

  # Connect to the chosen Wi-Fi network
  echo "Attempting to connect to $ssid..."
  if [[ -z $security_type ]]; then
    nmcli dev wifi connect "$ssid" password "$password" ifname wlan0
  else
    nmcli dev wifi connect "$ssid" password "$password" ifname wlan0 --security "$security_type"
  fi

  if [ $? -eq 0 ]; then
    echo "Connected successfully to $ssid!"
  else
    echo "Failed to connect. Please check the SSID, password, or security type."
    exit 1
  fi
else
  echo "Proceeding with saved network configuration..."
fi

# Start your kiosk application
echo "Starting kiosk application..."
/path/to/your/application &

exit 0

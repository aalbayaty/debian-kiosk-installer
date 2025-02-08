#!/bin/bash

# Function to check for wired connection (eth0 or similar)
check_wired_connection() {
  echo "Checking for RJ45 wired connection..."
  if ip link show | grep -q "eth0: <.*state UP.*>"; then
    echo "Wired connection detected. Using RJ45."
    dhclient eth0
    exit 0
  else
    echo "No wired connection detected."
  fi
}

# Function to list available Wi-Fi networks
list_wifi_networks() {
  echo "Scanning for available Wi-Fi networks..."
  nmcli device wifi list
}

# Function to configure Wi-Fi
configure_wifi() {
  echo "Available Wi-Fi Networks:"
  list_wifi_networks
  
  read -p "Enter the SSID: " ssid
  read -p "Enter the password: " wifi_password
  read -p "Enter security type (e.g., WPA-PSK, WPA2-PSK, NONE): " security_type
  
  echo "Connecting to $ssid with security $security_type..."
  nmcli dev wifi connect "$ssid" password "$wifi_password" ifname wlan0
}

# Main script logic
check_wired_connection

echo "Do you want to change Wi-Fi settings? (yes/no)"
read -t 10 user_response

if [ "$user_response" == "yes" ]; then
  configure_wifi
else
  echo "Proceeding with saved Wi-Fi settings..."
  nmcli networking on
fi

# Launch your kiosk application after network setup
echo "Starting kiosk application..."
# Replace with your application launch command
sleep 2

#!/bin/bash

# Ensure nmcli is available
if ! command -v nmcli &> /dev/null; then
    echo "Error: nmcli is not installed. Please install it to use this script."
    exit 1
fi

# Function to get available SSIDs
get_available_ssids() {
    echo "Scanning for available Wi-Fi networks..."
    nmcli -t -f SSID dev wifi | awk 'NF > 0' # Ensure no empty lines are listed
}

# Function to change Wi-Fi settings
change_wifi_settings() {
    ssids=$(get_available_ssids)
    if [ -z "$ssids" ]; then
        echo "No SSIDs found."
        return
    fi

    echo "Available SSIDs:"
    echo "$ssids" | nl

    read -p "Select the SSID number you want to connect to: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$(echo "$ssids" | wc -l)" ]; then
        echo "Invalid selection. Please enter a valid number."
        return
    fi

    selected_ssid=$(echo "$ssids" | sed -n "${choice}p")

    read -s -p "Enter the password for $selected_ssid: " password
    echo

    # Attempt connection without asking for security type
    nmcli dev wifi connect "$selected_ssid" password "$password"
    if [ $? -eq 0 ]; then
        echo "Connected to $selected_ssid."
    else
        echo "Failed to connect to $selected_ssid. Please check your password."
    fi
}

# Function to detect connection type
detect_connection_type() {
    connection_type=$(nmcli -t -f TYPE,STATE dev | grep 'connected' | awk -F':' '{print $1}' | head -n 1)
    case "$connection_type" in
        "ethernet") echo "RJ45" ;;
        "wifi") echo "Wi-Fi" ;;
        *) echo "Unknown" ;;
    esac
}

# Function to detect wired (RJ45) connection details
detect_wired_connection() {
    echo "Detecting wired (RJ45) connection details..."
    ip_addr=$(ip -o -4 addr show | grep -m 1 -E 'en|eth|wlan' | awk '{print $4}')
    gateway=$(ip route | grep default | awk '{print $3}')
    dns=$(grep nameserver /etc/resolv.conf | awk '{print $2}')

    echo "IP Address: ${ip_addr:-Not available}"
    echo "Gateway: ${gateway:-Not available}"
    echo "DNS Servers: ${dns:-Not available}"
}

# Main function
main() {
    echo "Waiting for 10 seconds... Press 'y' if you want to change Wi-Fi settings."
    read -t 10 -p "Press 'y' to change Wi-Fi settings (or wait to continue): " user_input

    # Detect connection type
    connection_type=$(detect_connection_type)
    echo "Detected connection type: $connection_type"

    if [ "$connection_type" == "Wi-Fi" ]; then
        if [ "$user_input" == "y" ]; then
            change_wifi_settings
        else
            echo "Using saved Wi-Fi settings."
        fi
    elif [ "$connection_type" == "RJ45" ]; then
        echo "Wired (RJ45) connection detected."
        detect_wired_connection
    else
        echo "Unknown connection type. Please check your network settings."
    fi

    # Continue with the application
    echo "Starting the application..."
    # Add your application logic here
}

# Run the main function
main
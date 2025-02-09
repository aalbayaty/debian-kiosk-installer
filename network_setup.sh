#!/bin/bash

# Function to get available SSIDs
get_available_ssids() {
    echo "Scanning for available Wi-Fi networks..."
    nmcli -t -f SSID dev wifi
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
    selected_ssid=$(echo "$ssids" | sed -n "${choice}p")

    if [ -z "$selected_ssid" ]; then
        echo "Invalid selection."
        return
    fi

    read -p "Enter the password for $selected_ssid: " password
    read -p "Enter the security type (e.g., WPA, WPA2): " security_type

    # Configure the new Wi-Fi connection
    nmcli dev wifi connect "$selected_ssid" password "$password" wifi-sec.key-mgmt "$security_type"
    echo "Connected to $selected_ssid."
}

# Function to detect connection type
detect_connection_type() {
    connection_type=$(nmcli -t -f DEVICE,TYPE,STATE dev | grep -E 'ethernet|wifi' | grep 'connected')
    if echo "$connection_type" | grep -q 'ethernet'; then
        echo "RJ45"
    elif echo "$connection_type" | grep -q 'wifi'; then
        echo "Wi-Fi"
    else
        echo "Unknown"
    fi
}

# Function to detect wired (RJ45) connection details
detect_wired_connection() {
    echo "Detecting wired (RJ45) connection details..."
    ip_addr=$(ip -o -4 addr show | awk '{print $4}')
    gateway=$(ip route | grep default | awk '{print $3}')
    dns=$(grep nameserver /etc/resolv.conf | awk '{print $2}')

    echo "IP Address: $ip_addr"
    echo "Gateway: $gateway"
    echo "DNS: $dns"
}

# Main function
main() {
    echo "Waiting for 10 seconds... Press 'y' if you want to change Wi-Fi settings."
    sleep 10

    # Detect connection type
    connection_type=$(detect_connection_type)
    echo "Detected connection type: $connection_type"

    if [ "$connection_type" == "Wi-Fi" ]; then
        read -p "Do you want to change Wi-Fi settings? (y/n): " user_input
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

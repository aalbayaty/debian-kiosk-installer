#!/bin/bash

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
    selected_ssid=$(echo "$ssids" | sed -n "${choice}p")

    if [ -z "$selected_ssid" ]; then
        echo "Invalid selection."
        return
    fi

    read -s -p "Enter the password for $selected_ssid: " password
    echo
    read -p "Enter the security type (WPA/WPA2/None): " security_type

    # Map security type to key management
    case "$security_type" in
        "WPA" | "WPA2") key_mgmt="wpa-psk" ;;
        "None") key_mgmt="none" ;;
        *) echo "Invalid security type." && return ;;
    esac

    # Configure the new Wi-Fi connection
    nmcli dev wifi connect "$selected_ssid" password "$password" wifi-sec.key-mgmt "$key_mgmt"
    if [ $? -eq 0 ]; then
        echo "Connected to $selected_ssid."
    else
        echo "Failed to connect to $selected_ssid. Please check your password or security type."
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
    ip_addr=$(ip -o -4 addr show eth0 | awk '{print $4}')
    gateway=$(ip route | grep default | awk '{print $3}')
    dns=$(grep nameserver /etc/resolv.conf | awk '{print $2}')

    echo "IP Address: ${ip_addr:-Not Found}"
    echo "Gateway: ${gateway:-Not Found}"
    echo "DNS: ${dns:-Not Found}"
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

#!/bin/bash

# Check if the user is root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Function to check network connectivity
check_network() {
    ping -c 1 8.8.8.8 &> /dev/null
    if [ $? -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

# Function to fix ethernet problems
fix_ethernet() {
    echo "Attempting to restart network service..."
    systemctl restart NetworkManager

    # Wait for a few seconds
    sleep 5

    check_network
    if [ $? -eq 0 ]; then
        echo "Network is now up!"
    else
        echo "Failed to fix the network issue. Starting the setup wizard..."
        setup_wizard
    fi
}

setup_wizard() {
    echo "---------------------------------"
    echo "Network Setup Wizard"
    echo "---------------------------------"
    read -p "Enter connection name (e.g., MyConnection): " conn_name
    read -p "Enter interface name (usually like eth0, enp2s0): " if_name
    read -p "Enter IP Address (e.g., 192.168.1.10): " ip_addr
    read -p "Enter Gateway (e.g., 192.168.1.1): " gateway
    read -p "Enter DNS (e.g., 8.8.8.8,8.8.4.4): " dns

    # Configure the connection
    nmcli con add type ethernet con-name "$conn_name" ifname "$if_name" ip4 "$ip_addr" gw4 "$gateway"
    nmcli con mod "$conn_name" ipv4.dns "$dns"

    # Activate the connection
    nmcli con up "$conn_name"

    # Test the new connection
    check_network
    if [ $? -eq 0 ]; then
        echo "Network setup successful and now up!"
    else
        echo "Failed to establish the network connection. Please check your settings."
    fi
}

# Main script execution

echo "Checking network connectivity..."
check_network

if [ $? -eq 1 ]; then
    echo "Network is down. Attempting to fix..."
    fix_ethernet
else
    echo "Network is up. No issues detected."
fi

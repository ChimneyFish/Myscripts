#!/bin/bash

# Function to display available drives
display_drives() {
  echo "Available drives:"
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk *$'
}

# Function to create a swap partition
create_swap_partition() {
  local drive="$1"
  local swap_size="$2"

  # Check if the drive exists
  if [ ! -e "/dev/$drive" ]; then
    echo "Drive /dev/$drive does not exist."
    return 1
  fi

  # Check if the drive is already partitioned
  if [ -e "/dev/${drive}1" ]; then
    echo "Drive /dev/$drive is already partitioned. Skipping."
    return 1
  fi

  # Create the swap partition
  echo "Creating swap partition on /dev/$drive"
  sudo parted /dev/"$drive" mklabel gpt
  sudo parted /dev/"$drive" mkpart primary linux-swap 0% "$swap_size"
  sudo mkswap /dev/"$drive"1
  sudo swapon /dev/"$drive"1

  # Add entry to /etc/fstab
  echo "/dev/$drive"1 none swap sw 0 0 | sudo tee -a /etc/fstab

  echo "Swap partition created and activated on /dev/$drive."
}

# Display available drives
display_drives

# Ask the user to select a drive
read -p "Enter the drive where you want to create the swap partition (e.g., sda, nvme0n1): " selected_drive

# Ask for the swap size
read -p "Enter the swap size (e.g., 2G, 4G): " swap_size

# Confirm with the user before proceeding
echo "You are about to create a swap partition on /dev/$selected_drive with a size of $swap_size."
read -p "Do you want to continue? (y/n): " confirm
if [ "$confirm" != "y" ]; then
  echo "Operation canceled."
  exit 1
fi

# Create the swap partition
create_swap_partition "$selected_drive" "$swap_size"

echo "Swap configuration complete."

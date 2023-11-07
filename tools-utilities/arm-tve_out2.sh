#!/bin/bash

echo "Initializing Script"
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if the script is running with root privileges
if [ "$(id -u)" != "0" ]; then
  echo "This script requires root privileges. Please run it with sudo."
  exit 1
fi

# Define file paths
FILE_PATH1="/root"
FILE_PATH2="/boot"
FILE1="script.bin"
FILE2="script.fex"



# Check if required commands are available
required_commands=("bin2fex" "sed" "gcc" "git")
for command in "${required_commands[@]}"; do
  if ! command -v "$command" &>/dev/null; then
    echo "Required command '$command' not found. Please install it."
    exit 1
  fi
done

echo "WARNING: This script will reboot your device. Make sure you have everything closed and saved to prevent data loss."
read -p "Press Enter to continue or Ctrl+C to exit" -n 1

echo "Initial execution of the script"
sleep 1
clear

# Convert bin to fex
sudo bin2fex "$FILE_PATH2/$FILE1" "$FILE_PATH1/$FILE2"

# Modify the script.fex file
sed -i 's/fb0_width = 0/fb0_width = 680/' "$FILE_PATH1/script.fex"
sed -i 's/fb0_height = 0/fb0_height = 536/' "$FILE_PATH1/script.fex"

# Convert fex back to bin
sudo fex2bin "$FILE_PATH1/$FILE2" "$FILE_PATH1/$FILE1"
sudo cp "$FILE_PATH1/$FILE1" "$FILE_PATH2"

# Download and compile devmem2
sudo wget --no-check-certificate http://free-electrons.com/pub/mirror/devmem2.c
sudo gcc -o /usr/local/bin/devmem2 devmem2.c

# Clone and compile tvout
sudo git clone https://github.com/VCTLabs/allwinner-tvout.git
cd allwinner-tvout/src
sudo make release
sudo cp bin/Release/tvout /usr/local/bin/tvout

# Display instructions for TV picture offset
clear
echo "To calculate your TV picture offset by pixels, you will need to perform measurements and calculations based on a reference point. Here's a summerized guide on how to do it:

    Identify a Reference Point:
    Choose a distinct point on your TV screen to serve as a reference. This point should be easily identifiable, such as a corner or an edge of the screen.

    Measure the Expected Position:
    Determine the expected or ideal position of the reference point based on the TV's specifications or guidelines. This position is typically defined by the manufacturer and should be the point where the reference should appear on the screen.

    Measure the Actual Position:
    Using a ruler or a measuring tool, measure the actual position of the reference point. Measure the distance in pixels from the reference point to the nearest edge or a reference point on your TV screen.

    Calculate the Offset:
    To calculate the offset in pixels, subtract the expected position from the actual position. The formula for calculating the offset is as follows:

    Offset (in pixels) = Actual Position - Expected Position

    If the actual position is to the right or below the expected position, you'll get a positive offset value. If the actual position is to the left or above the expected position, you'll get a negative offset value.

    Record the Offset:
    Make a note of the calculated offset value for future reference or adjustment.


It's important to note that not all TVs offer fine-grained pixel-level adjustments for screen positioning. Some may only provide general options like "center" or "fit to screen." The availability of adjustment options can vary based on the make and model of your TV.

Consult your TV's user manual or contact the manufacturer's support for specific guidance on how to measure and adjust the pixel offset for your particular TV model."
read -p "Press Enter to continue"

# Gather user input for vertical and horizontal offsets
read -p "What would you like your Vertical offset to be? " V
read -p "What would you like your Horizontal offset to be? " H

# Adjust TV picture offset
tvout -m -x "$V" -y "$H"

# Cleanup
sudo rm -rf "$script_dir/allwinner-tvout"
sudo rm "$FILE_PATH1/$FILE2"

echo "If the screen is still not correct, please use the command 'tvout -m -x (value) -y (value)' to make further adjustments."
read -p "Press Enter to exit to reboot"
sudo reboot

#!/bin/bash

# Function to display the script's usage instructions
display_usage() {
  echo "Usage: $0 -s SSID -p PASSWORD -i IMG_FILE"
  echo "   or: $0 --help"
  echo
  echo "Options:"
  echo "  -s, --ssid      SSID of the WiFi network"
  echo "  -p, --password  Password of the WiFi network"
  echo "  -i, --img       Name and location of the IMG file"
  echo "  --help          Display this help and exit"
}

# Check if kpartx is installed
if ! [ -x "$(command -v kpartx)" ]; then
  echo "Error: kpartx is not installed. Please install it and try again."
  exit 1
fi

# Parse the command-line arguments
while getopts ":s:p:i:h" opt; do
  case $opt in
    s)
      ssid="$OPTARG"
      ;;
    p)
      password="$OPTARG"
      ;;
    i)
      img_file="$OPTARG"
      ;;
    h)
      display_usage
      exit
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument."
      display_usage
      exit 1
      ;;
    \?)
      echo "Error: Invalid option -$OPTARG"
      display_usage
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

# Check if the required arguments were provided
if [ -z "$ssid" ] || [ -z "$password" ] || [ -z "$img_file" ]; then
  echo "Error: SSID, password, and IMG file must be provided."
  display_usage
  exit 1
fi

# Create a temporary directory and use kpartx to mount the IMG file to it
mkdir temp
kpartx -av "$img_file"
mount /dev/mapper/loop0p2 temp

# Remove any existing WiFi configurations
sudo sed -i '/^network={/,/^}/d' temp/etc/wpa_supplicant/wpa_supplicant.conf

# Add the new WiFi configuration
echo "network={
ssid=\"$ssid\"
psk=\"$password\"
scan_ssid=1
key_mgmt=WPA-PSK
}" | sudo tee -a temp/etc/wpa_supplicant/wpa_supplicant.conf

# Unmount the partitions and remove the loop device created by kpartx
umount temp
kpartx -dv "$img_file"

# Check if the IMG file is still mounted
if mount | grep -q "$img_file"; then
  echo "Error: Failed to unmount IMG file."
  exit 1
fi

# Delete the temporary directory
rmdir temp

#!/bin/bash

# Display usage information
display_usage() {
  echo "Usage: $0 -d [DEVICE] -i [IMG FILE]"
  echo ""
  echo "Options:"
  echo "  -d, --device  Block device name of the SD card (e.g. /dev/mmcblk0)"
  echo "  -i, --img     Desired name and location of the IMG file (e.g. ~/rpi.img)"
  echo "  -h, --help    Display this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -d|--device)
      device="$2"
      shift
      shift
      ;;
    -i|--img)
      img_file="$2"
      shift
      shift
      ;;
    -h|--help)
      display_usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option $key"
      display_usage
      exit 1
      ;;
  esac
done

# Check if all required arguments have been provided
if [[ -z "$device" || -z "$img_file" ]]; then
  echo "Error: Device and IMG file must be provided"
  display_usage
  exit 1
fi

# Unmount the SD card
umount $device

# Create a disk image from the SD card
dd if=$device | pv | dd of=tempfile.img

# Check if the dd command completed successfully
if [[ $? -eq 0 ]]; then
  # Download the pishrink script
  wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh

  # Make the pishrink script executable
  chmod +x pishrink.sh

  # Optimize the disk image using pishrink
  ./pishrink.sh tempfile.img $img_file
else
  echo "Error: Failed to create disk image"
  exit 1
fi

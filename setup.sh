#!/bin/bash
set -e

echo "Starting USB HID gadget setup..."

# Constants
GADGET="/sys/kernel/config/usb_gadget/hidpi"

# Cleanup old gadget if exists
if [ -d "$GADGET" ]; then
  echo "Cleaning previous setup..."
  echo "" > "$GADGET/UDC" || true
  rm -rf "$GADGET"
fi

# Create gadget directory
mkdir -p "$GADGET"
cd "$GADGET"

# Basic device info
echo "0x1d6b" > idVendor  # Linux Foundation
echo "0x0104" > idProduct # Multifunction Composite Gadget
echo "0x0100" > bcdDevice
echo "0x0200" > bcdUSB

# Strings
mkdir -p strings/0x409
echo "123456789" > strings/0x409/serialnumber
echo "Copilot Inc." > strings/0x409/manufacturer
echo "Raspberry Pi HID Gadget" > strings/0x409/product

# Configuration
mkdir -p configs/c.1/strings/0x409
echo "HID Configuration" > configs/c.1/strings/0x409/configuration
echo 120 > configs/c.1/MaxPower

# HID Function Setup
mkdir -p functions/hid.usb0
echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length

# HID Report Descriptor for a standard keyboard
echo -ne \
'\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02' \
> functions/hid.usb0/report_desc

# Link the HID function to the config
ln -s functions/hid.usb0 configs/c.1/

# Bind gadget to UDC
UDC=$(ls /sys/class/udc | head -n 1)
echo "$UDC" > UDC

echo "HID gadget configured successfully!"
echo "You can now send HID reports to /dev/hidg0 (e.g., echo -ne '\\x00\\x00\\x04\\x00\\x00\\x00\\x00\\x00' > /dev/hidg0 for 'a' key)"

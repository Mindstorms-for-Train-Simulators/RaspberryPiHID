#!/bin/bash
set -e

echo "Starting USB HID setup..."

GADGET="/sys/kernel/config/usb_gadget/hidpi"

# Function to check UDC availability
check_udc() {
  local udc=$(ls /sys/class/udc | head -n 1)
  if [ -z "$udc" ]; then
    echo "ERROR: No USB Device Controller found. Is dwc2 enabled?"
    exit 1
  fi
  echo "$udc"
}

# Cleanup old gadget
if [ -d "$GADGET" ]; then
  echo "Cleaning old gadget setup..."
  echo "" > "$GADGET/UDC" || echo "Could not unbind previous UDC (might already be unbound)"
  rm -rf "$GADGET"
fi

# Create new gadget
mkdir -p "$GADGET"
cd "$GADGET"

# Basic device config
echo "0x1d6b" > idVendor
echo "0x0104" > idProduct
echo "0x0100" > bcdDevice
echo "0x0200" > bcdUSB

# Strings
mkdir -p strings/0x409
echo "123456789" > strings/0x409/serialnumber
echo "Copilot Inc." > strings/0x409/manufacturer
echo "Raspberry Pi HID Gadget" > strings/0x409/product

# Configuration setup
mkdir -p configs/c.1/strings/0x409
echo "HID Configuration" > configs/c.1/strings/0x409/configuration
echo 120 > configs/c.1/MaxPower

# HID function
mkdir -p functions/hid.usb0
echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length

# HID report descriptor (keyboard)
echo -ne \
'\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02' \
> functions/hid.usb0/report_desc

# Link function to configuration
ln -s functions/hid.usb0 configs/c.1/

# Bind to UDC (with validation)
UDC=$(check_udc)
echo "Binding to UDC: $UDC"
echo "$UDC" > UDC || {
  echo "ERROR: Failed to bind to UDC. Check permissions and UDC availability."
  exit 1
}

echo "Setup complete! HID gadget ready at /dev/hidg0"
echo "Try: echo -ne '\\x00\\x00\\x04\\x00\\x00\\x00\\x00\\x00' > /dev/hidg0 (sends 'a' key)"

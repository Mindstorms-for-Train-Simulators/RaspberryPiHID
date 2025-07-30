#!/bin/bash
set -e

echo "Starting EV3 HID setup..."

G="/sys/kernel/config/usb_gadget/ev3hid"

# Clean up if already exists
if [ -d "$G" ]; then
  echo "Cleaning previous gadget..."
  echo "" > "$G/UDC" || true
  rm -rf "$G"
fi

# Create gadget
mkdir -p "$G"
cd "$G"

echo "0x1d6b" > idVendor
echo "0x0104" > idProduct
echo "0x0100" > bcdDevice
echo "0x0200" > bcdUSB

mkdir -p strings/0x409
echo "EV3-123456" > strings/0x409/serialnumber
echo "EV3 Corp" > strings/0x409/manufacturer
echo "EV3 Dual HID" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Dual HID Config" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# HID Keyboard
mkdir -p functions/hid.keyboard
echo 8 > functions/hid.keyboard/report_length
echo -ne \
'\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02'\
'\x95\x01\x75\x08\x81\x01'\
'\x95\x05\x75\x08\x15\x00\x25\x65\x19\x00\x29\x65\x81\x00'\
'\x95\x01\x75\x08\x81\x01'\
'\xc0' > functions/hid.keyboard/report_desc

# HID Joystick
mkdir -p functions/hid.joystick
echo 4 > functions/hid.joystick/report_length
echo -ne \
'\x05\x01\x09\x04\xa1\x01'\
'\x15\x00\x26\xff\x00\x75\x08\x95\x02\x09\x30\x09\x31\x81\x02'\
'\x05\x09\x19\x01\x29\x04\x15\x00\x25\x01\x75\x01\x95\x04\x81\x02'\
'\x75\x04\x95\x01\x81\x03'\
'\xc0' > functions/hid.joystick/report_desc

# Link functions
ln -s functions/hid.keyboard configs/c.1/
ln -s functions/hid.joystick configs/c.1/

# Bind to UDC
UDC=$(ls /sys/class/udc | head -n 1)
if [ -z "$UDC" ]; then
  echo "ERROR: No UDC found. Is dwc2 enabled?"
  exit 1
fi

echo "$UDC" > UDC
echo "HID gadget bound to $UDC"

echo "Setup complete!"

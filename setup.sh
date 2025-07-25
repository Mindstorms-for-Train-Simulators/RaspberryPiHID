#!/bin/bash

echo "🔧 Configuring boot files..."

# Paths
CONFIG_PATH="/boot/firmware/config.txt"
CMDLINE_PATH="/boot/firmware/cmdline.txt"

# Update config.txt
CONFIG_LINE="dtoverlay=dwc2,dr_mode=peripheral"
grep -qxF "$CONFIG_LINE" "$CONFIG_PATH" || echo "$CONFIG_LINE" >> "$CONFIG_PATH"

# Update cmdline.txt
CMDLINE=$(cat "$CMDLINE_PATH")
if [[ "$CMDLINE" != *"modules-load=dwc2,libcomposite"* ]]; then
    CMDLINE=$(echo "$CMDLINE" | sed 's/\brootwait\b/& modules-load=dwc2,libcomposite/')
    echo "$CMDLINE" > "$CMDLINE_PATH"
    echo "cmdline.txt updated."
else
    echo "modules-load already present."
fi

echo "Setting up USB gadget logic..."

# Create the gadget setup script
GADGET_SCRIPT="/usr/bin/setup_usb_gadget.sh"
cat << 'EOF' > "$GADGET_SCRIPT"
#!/bin/bash
GADGET_DIR="/sys/kernel/config/usb_gadget/g1"

mkdir -p $GADGET_DIR
cd $GADGET_DIR

echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "1234567890" > strings/0x409/serialnumber
echo "YourName" > strings/0x409/manufacturer
echo "USB Gadget" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1" > configs/c.1/strings/0x409/configuration

mkdir -p functions/hid.usb0
echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length

# Example HID report descriptor
echo -ne \\x05\\x01\\x09\\x02\\xa1\\x01\\x09\\x01\\xa1\\x00\\x05\\x09\\x19\\x01\\x29\\x03\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x03\\x81\\x02\\x95\\x01\\x75\\x05\\x81\\x03\\x05\\x01\\x09\\x30\\x09\\x31\\x15\\x81\\x25\\x7f\\x75\\x08\\x95\\x02\\x81\\x06\\xc0\\xc0 > functions/hid.usb0/report_desc

ln -s functions/hid.usb0 configs/c.1/

echo "USB HID gadget setup complete."
EOF

chmod +x "$GADGET_SCRIPT"

# Add to rc.local for auto-run
if ! grep -q "$GADGET_SCRIPT" /etc/rc.local; then
    sed -i -e '$i\\n'$GADGET_SCRIPT'\n' /etc/rc.local
fi

echo "Configuration complete! Reboot to activate USB gadget mode."

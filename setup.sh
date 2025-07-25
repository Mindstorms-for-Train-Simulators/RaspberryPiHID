#!/bin/bash

echo "🔧 Step 1: Update boot configuration files..."

CONFIG_PATH="/boot/firmware/config.txt"
CMDLINE_PATH="/boot/firmware/cmdline.txt"

# Ensure gadget overlay is present
CONFIG_LINE="dtoverlay=dwc2,dr_mode=peripheral"
grep -qxF "$CONFIG_LINE" "$CONFIG_PATH" || echo "$CONFIG_LINE" >> "$CONFIG_PATH"

# Inject module loading into cmdline
CMDLINE=$(cat "$CMDLINE_PATH")
if [[ "$CMDLINE" != *"modules-load=dwc2,libcomposite"* ]]; then
  CMDLINE=$(echo "$CMDLINE" | sed 's/\brootwait\b/& modules-load=dwc2,libcomposite/')
  echo "$CMDLINE" > "$CMDLINE_PATH"
  echo "✅ Updated cmdline.txt"
else
  echo "⚠️ modules-load already present in cmdline.txt"
fi

echo "🧠 Step 2: Create USB gadget setup script..."

GADGET_SCRIPT="/usr/bin/setup_usb_gadget.sh"
cat << 'EOF' > "$GADGET_SCRIPT"
#!/bin/bash
G="/sys/kernel/config/usb_gadget/g1"
mkdir -p "$G"
cd "$G"

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "1234567890" > strings/0x409/serialnumber
echo "EV3 Corporation" > strings/0x409/manufacturer
echo "EV3 HID Joystick" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

mkdir -p functions/hid.usb0
echo 0 > functions/hid.usb0/protocol
echo 0 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length

# Sample HID report descriptor (2 axes, 5 buttons)
echo -ne \
'\x05\x01\x09\x04\xA1\x01\x15\x00\x26\xFF\x00\x75\x08\x95\x02\x09\x30\x09\x31\x81\x02'\
'\x05\x09\x19\x01\x29\x05\x15\x00\x25\x01\x75\x01\x95\x05\x81\x02\x75\x03\x95\x01\x81\x03\xC0' \
> functions/hid.usb0/report_desc

ln -s functions/hid.usb0 configs/c.1/
echo "$(ls /sys/class/udc)" > UDC
echo "✅ USB HID gadget initialized."
EOF

chmod +x "$GADGET_SCRIPT"

echo "🛠️ Step 3: Register systemd service..."

SERVICE_FILE="/etc/systemd/system/usb-gadget.service"
cat << EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=EV3 USB Gadget Setup
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$GADGET_SCRIPT
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable usb-gadget.service

echo "🎉 Setup complete! Please reboot to activate gadget mode:"
echo "👉 sudo reboot"

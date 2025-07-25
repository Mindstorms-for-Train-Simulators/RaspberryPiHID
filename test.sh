#!/bin/bash
# Throttle: 128, Modifier: none, Key: 'w' (0x1A)

echo -ne '\x80\x00\x1A' > /dev/hidg0
sleep 0.1
echo -ne '\x80\x00\x00' > /dev/hidg0  # release

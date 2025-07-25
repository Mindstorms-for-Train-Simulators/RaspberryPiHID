#!/bin/bash

# Throttle: 128, No modifier, 'W' (usage ID 0x1A)
echo -ne '\x80\x00\x1A' > /dev/hidg0
sleep 0.1
# Release
echo -ne '\x80\x00\x00' > /dev/hidg0

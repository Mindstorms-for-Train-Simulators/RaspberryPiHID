#!/bin/bash

# Write "Throttle 128 + 'w' key"
echo -ne '\x80\x1A' > /dev/hidg0
sleep 0.1

# Release key
echo -ne '\x80\x00' > /dev/hidg0

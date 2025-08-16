#!/bin/sh

# W1 and DS2482S Module Loading Script
# This script loads the 1-Wire framework and DS2482S I2C-to-1Wire bridge driver

echo "Loading 1-Wire framework..."
modprobe wire

echo "Loading DS2482S I2C-to-1Wire bridge driver..."
modprobe ds2482

echo "Loading 1-Wire thermal sensor driver..."
modprobe w1_therm

echo "Loading 1-Wire simple memory driver..."
modprobe w1_smem

echo "Checking loaded W1 modules..."
lsmod | grep -E "(wire|ds2482|w1_)"

echo ""
echo "Creating DS2482S device on I2C bus..."
echo "To create the DS2482S device, run:"
echo "echo ds2482 0x18 > /sys/bus/i2c/devices/i2c-0/new_device"
echo ""
echo "Replace 'i2c-0' with your actual I2C bus number and '0x18' with your DS2482S I2C address."
echo ""
echo "After creating the device, 1-Wire devices should appear in /sys/bus/w1/devices/"

#!/bin/bash

# Script to check kernel support for gpio-leds, gpio-keys, and gpio-export
# Usage: ./check_gpio_support.sh

CONFIG_FILE="/home/andresc/v85x-sdk/device/config/chips/v851se/configs/sc1725v/linux/config-4.9"
KERNEL_SRC="/home/andresc/v85x-sdk/lichee/linux-4.9"

echo "=== Checking GPIO Support in Kernel Configuration ==="
echo

# Check basic GPIO support
echo "1. Basic GPIO Support:"
if grep -q "^CONFIG_GPIOLIB=y" "$CONFIG_FILE"; then
    echo "   ✓ GPIOLIB is enabled"
else
    echo "   ✗ GPIOLIB is NOT enabled"
fi

if grep -q "^CONFIG_GPIO_SYSFS=y" "$CONFIG_FILE"; then
    echo "   ✓ GPIO_SYSFS is enabled (allows /sys/class/gpio access)"
else
    echo "   ✗ GPIO_SYSFS is NOT enabled"
fi

echo

# Check LED support
echo "2. LED Support:"
if grep -q "^CONFIG_NEW_LEDS=y" "$CONFIG_FILE"; then
    echo "   ✓ NEW_LEDS is enabled"
else
    echo "   ✗ NEW_LEDS is NOT enabled - LEDs support disabled"
fi

if grep -q "^CONFIG_LEDS_CLASS=y" "$CONFIG_FILE"; then
    echo "   ✓ LEDS_CLASS is enabled"
else
    echo "   ✗ LEDS_CLASS is NOT enabled"
fi

if grep -q "^CONFIG_LEDS_GPIO=y" "$CONFIG_FILE"; then
    echo "   ✓ LEDS_GPIO is enabled"
else
    echo "   ✗ LEDS_GPIO is NOT enabled - gpio-leds not supported"
fi

echo

# Check Input/Keys support
echo "3. Input/Keys Support:"
if grep -q "^CONFIG_INPUT=y" "$CONFIG_FILE"; then
    echo "   ✓ INPUT is enabled"
else
    echo "   ✗ INPUT is NOT enabled"
fi

if grep -q "^CONFIG_INPUT_KEYBOARD=y" "$CONFIG_FILE"; then
    echo "   ✓ INPUT_KEYBOARD is enabled"
else
    echo "   ✗ INPUT_KEYBOARD is NOT enabled"
fi

if grep -q "^CONFIG_KEYBOARD_GPIO=y" "$CONFIG_FILE"; then
    echo "   ✓ KEYBOARD_GPIO is enabled"
else
    echo "   ✗ KEYBOARD_GPIO is NOT enabled - gpio-keys not supported"
fi

echo

# Check available drivers in kernel source
echo "4. Available Drivers in Kernel Source:"

if [ -f "$KERNEL_SRC/drivers/leds/leds-gpio.c" ]; then
    echo "   ✓ GPIO LEDs driver source available"
else
    echo "   ✗ GPIO LEDs driver source NOT found"
fi

if [ -f "$KERNEL_SRC/drivers/input/keyboard/gpio_keys.c" ]; then
    echo "   ✓ GPIO Keys driver source available"
else
    echo "   ✗ GPIO Keys driver source NOT found"
fi

echo

# Check for gpio-export alternative
echo "5. GPIO Export Alternatives:"
echo "   Note: gpio-export is not a standard kernel driver."
echo "   Alternatives for GPIO control:"
echo "   - Use GPIO_SYSFS (/sys/class/gpio/export)"
echo "   - Use libgpiod utilities (gpioset, gpioget)"
echo "   - Use device tree GPIO hogs"

echo

# Recommendations
echo "=== RECOMMENDATIONS ==="
echo

# Check what needs to be enabled
missing_configs=()

if ! grep -q "^CONFIG_NEW_LEDS=y" "$CONFIG_FILE"; then
    missing_configs+=("CONFIG_NEW_LEDS=y")
fi

if ! grep -q "^CONFIG_LEDS_CLASS=y" "$CONFIG_FILE"; then
    missing_configs+=("CONFIG_LEDS_CLASS=y")
fi

if ! grep -q "^CONFIG_LEDS_GPIO=y" "$CONFIG_FILE"; then
    missing_configs+=("CONFIG_LEDS_GPIO=y")
fi

if ! grep -q "^CONFIG_INPUT_KEYBOARD=y" "$CONFIG_FILE"; then
    missing_configs+=("CONFIG_INPUT_KEYBOARD=y")
fi

if ! grep -q "^CONFIG_KEYBOARD_GPIO=y" "$CONFIG_FILE"; then
    missing_configs+=("CONFIG_KEYBOARD_GPIO=y")
fi

if [ ${#missing_configs[@]} -gt 0 ]; then
    echo "To enable gpio-leds and gpio-keys support, add these to your kernel config:"
    echo
    for config in "${missing_configs[@]}"; do
        echo "   $config"
    done
    echo
    echo "Location: $CONFIG_FILE"
else
    echo "✓ All required configurations are present!"
fi

echo
echo "=== GPIO EXPORT ALTERNATIVES ==="
echo
echo "Since gpio-export is not a standard driver, use these alternatives:"
echo
echo "1. GPIO SYSFS (if CONFIG_GPIO_SYSFS=y):"
echo "   echo <gpio_num> > /sys/class/gpio/export"
echo "   echo out > /sys/class/gpio/gpio<num>/direction"
echo "   echo 1 > /sys/class/gpio/gpio<num>/value"
echo
echo "2. Device Tree GPIO Hogs:"
echo "   Add gpio-hog properties to your device tree"
echo
echo "3. Custom GPIO driver or modify existing pinctrl"

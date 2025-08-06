# GPIO Support Analysis and Configuration Guide

## Summary of Kernel Support

### ✅ **Currently Supported (After Configuration Updates)**

1. **GPIO LEDs** (`gpio-leds`)
   - ✅ Driver source available: `/drivers/leds/leds-gpio.c`
   - ✅ Kernel config enabled: `CONFIG_NEW_LEDS=y`, `CONFIG_LEDS_CLASS=y`, `CONFIG_LEDS_GPIO=y`
   - ✅ Device tree support: `gpio-leds` compatible

2. **GPIO Keys** (`gpio-keys`) 
   - ✅ Driver source available: `/drivers/input/keyboard/gpio_keys.c`
   - ✅ Kernel config enabled: `CONFIG_INPUT_KEYBOARD=y`, `CONFIG_KEYBOARD_GPIO=y`
   - ✅ Device tree support: `gpio-keys` compatible

3. **GPIO Control** (Alternative to `gpio-export`)
   - ✅ GPIO SYSFS enabled: `CONFIG_GPIO_SYSFS=y`
   - ✅ Basic GPIO lib: `CONFIG_GPIOLIB=y`
   - ✅ Runtime control via `/sys/class/gpio/`

### ❌ **Not Supported**

1. **gpio-export**
   - ❌ Not a standard Linux kernel driver
   - ❌ No mainline kernel support
   - ✅ **Alternative**: Use GPIO SYSFS or GPIO hogs

## Configuration Changes Made

### Kernel Configuration Updates (`config-4.9`)

```bash
# LED Support
CONFIG_NEW_LEDS=y
CONFIG_LEDS_CLASS=y  
CONFIG_LEDS_GPIO=y

# Input/Keyboard Support
CONFIG_INPUT_KEYBOARD=y
CONFIG_KEYBOARD_GPIO=y

# GPIO Support (already enabled)
CONFIG_GPIOLIB=y
CONFIG_GPIO_SYSFS=y
```

### Device Tree Configuration (`board.dts`)

1. **GPIO LEDs** - Hardware controlled LEDs:
```dts
gpio-leds {
    compatible = "gpio-leds";
    
    led-yellow {
        label = "yellow-led";
        gpios = <&pio PF 1 GPIO_ACTIVE_HIGH>;
        default-state = "off";
    };
    
    led-green {
        label = "green-led"; 
        gpios = <&pio PF 4 GPIO_ACTIVE_HIGH>;
        default-state = "off";
    };
    
    led-red {
        label = "red-led";
        gpios = <&pio PF 6 GPIO_ACTIVE_HIGH>;
        default-state = "off";
    };
};
```

2. **GPIO Keys** - Hardware input monitoring:
```dts
gpio-keys {
    compatible = "gpio-keys";
    
    batt-chg-st1 {
        label = "Battery Charge Status 1";
        gpios = <&pio PE 0 GPIO_ACTIVE_HIGH>;
        gpio-key,wakeup;
    };
    
    main-reg-pg {
        label = "Main Regulator Power Good";
        gpios = <&pio PE 2 GPIO_ACTIVE_HIGH>;
        gpio-key,wakeup;
    };
    
    // ... other input pins
};
```

## GPIO Control Methods

### Method 1: LED Control (Kernel Driver)
```bash
# LEDs are controlled via sysfs LED class
echo 1 > /sys/class/leds/yellow-led/brightness   # Turn on
echo 0 > /sys/class/leds/yellow-led/brightness   # Turn off
```

### Method 2: GPIO SYSFS (Manual Control)
```bash
# Export GPIO
echo 8 > /sys/class/gpio/export

# Set as output
echo out > /sys/class/gpio/gpio8/direction

# Set value
echo 1 > /sys/class/gpio/gpio8/value   # High
echo 0 > /sys/class/gpio/gpio8/value   # Low

# Read value (for inputs)
cat /sys/class/gpio/gpio8/value
```

### Method 3: Custom Script (Recommended)
Use the provided `gpio_control.sh` script:

```bash
# Initialize all GPIOs
./gpio_control.sh init-all

# Control specific functions
./gpio_control.sh sim enable
./gpio_control.sh modem-power on
./gpio_control.sh led yellow-led on
./gpio_control.sh status
```

## GPIO Pin Mapping

| Function | Pin | GPIO Number | Type |
|----------|-----|-------------|------|
| SIM_DIS_CTRL | PA8 | 8 | Output |
| MDM_PWR_CTRL | PA9 | 9 | Output |
| USB_ENUM_CTRL | PE3 | 131 | Output |
| MDM_ON_CTRL | PE4 | 132 | Output |
| MDM_RST_CTRL | PE11 | 139 | Output |
| BATT_CHG_ST1 | PE0 | 128 | Input |
| MAIN_REG_PG | PE2 | 130 | Input |
| BATT_CHG_ST2 | PE5 | 133 | Input |
| PWR_PATH_ST | PE8 | 136 | Input |
| UC_ATTENTION | PE9 | 137 | Input |
| ACCEL_INT1 | PH0 | 224 | Input |
| ACCEL_INT2 | PF3 | 163 | Input |
| USB_DETECT | PH13 | 237 | Input |
| Yellow LED | PF1 | 161 | Output |
| Green LED | PF4 | 164 | Output |
| Red LED | PF6 | 166 | Output |

## Usage Examples

### Initialize System
```bash
# Run once after boot to set up all GPIOs
./gpio_control.sh init-all
```

### Control LTE Modem
```bash
# Power on sequence
./gpio_control.sh modem-power on
sleep 1
./gpio_control.sh sim enable
sleep 1
./gpio_control.sh modem-reset
```

### Monitor System Status
```bash
# Check all input statuses
./gpio_control.sh status
```

### Control LEDs
```bash
# Status indication
./gpio_control.sh led green-led on    # System OK
./gpio_control.sh led yellow-led on   # Warning
./gpio_control.sh led red-led on      # Error
```

## Verification Commands

### Check Kernel Support
```bash
./check_gpio_support.sh
```

### Test LED Control
```bash
# After kernel boot with new config
ls /sys/class/leds/                    # Should show yellow-led, green-led, red-led
echo 1 > /sys/class/leds/yellow-led/brightness
```

### Test GPIO Keys
```bash
# After kernel boot
cat /proc/bus/input/devices           # Should show gpio-keys device
evtest                                # Can test key events
```

### Test GPIO SYSFS
```bash
ls /sys/class/gpio/                   # Should show export/unexport
echo 8 > /sys/class/gpio/export       # Should create gpio8 directory
```

## Build Instructions

1. **Update Kernel Configuration**:
   - The `config-4.9` file has been updated with necessary configs
   - Rebuild kernel with new configuration

2. **Use Updated Device Tree**:
   - The `board.dts` file includes gpio-leds and gpio-keys
   - Rebuild device tree blob

3. **Deploy Control Script**:
   - Copy `gpio_control.sh` to target system
   - Make executable and run `init-all` after boot

## Troubleshooting

### LEDs not working
- Check `/sys/class/leds/` directory exists
- Verify kernel config includes LED support
- Check device tree GPIO pin assignments

### GPIO Keys not working  
- Check `/proc/bus/input/devices` for gpio-keys
- Verify INPUT_KEYBOARD and KEYBOARD_GPIO enabled
- Test with `evtest` command

### GPIO Control not working
- Verify GPIO_SYSFS is enabled
- Check GPIO pin numbers in script match hardware
- Ensure GPIO pins are not used by other drivers

### Permission Issues
- Run scripts as root or with sudo
- Check GPIO sysfs permissions
- Verify user groups for GPIO access

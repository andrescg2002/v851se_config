# GPIO Control Pins Configuration Summary

## Added GPIO Control Pins Configuration

I've now properly configured the missing control pins in the device tree:

### Control Pins Added:
1. **PA8** - SIM Disable Control
2. **PA9** - Modem Power Control  
3. **PE3** - USB Enumeration Control
4. **PE4** - Modem ON Control
5. **PE11** - Modem Reset Control

### Device Tree Changes Made:

#### 1. Added pinctrl configurations in &pio section:
```dts
gpio_control_pins_a: gpio-control-a@0 {
    allwinner,pins = "PA8", "PA9";
    allwinner,function = "gpio_out";
    allwinner,muxsel = <1>;
    allwinner,drive = <1>;
    allwinner,pull = <0>;
};

gpio_control_pins_e: gpio-control-e@0 {
    allwinner,pins = "PE3", "PE4", "PE11";
    allwinner,function = "gpio_out";
    allwinner,muxsel = <1>;
    allwinner,drive = <1>;
    allwinner,pull = <0>;
};
```

### GPIO Control via Sysfs:

The `gpio_control.sh` script already includes correct mappings for these pins:

- **PA8** (sim-dis-ctrl) = GPIO 8
- **PA9** (mdm-pwr-ctrl) = GPIO 9  
- **PE3** (usb-enum-ctrl) = GPIO 131
- **PE4** (mdm-on-ctrl) = GPIO 132
- **PE11** (mdm-rst-ctrl) = GPIO 139

### Usage Examples:

```bash
# Enable SIM (set PA8 low - active high to disable)
./gpio_control.sh set_gpio sim-dis-ctrl 0

# Power on modem (set PA9 high)
./gpio_control.sh set_gpio mdm-pwr-ctrl 1

# Enable USB enumeration (set PE3 high)
./gpio_control.sh set_gpio usb-enum-ctrl 1

# Turn on modem (set PE4 high)
./gpio_control.sh set_gpio mdm-on-ctrl 1

# Reset modem (pulse PE11)
./gpio_control.sh set_gpio mdm-rst-ctrl 1
sleep 0.1
./gpio_control.sh set_gpio mdm-rst-ctrl 0
```

### Functions Available:
The GPIO control script provides high-level functions for modem control:
- `modem_power_on()` - Powers on the modem
- `modem_power_off()` - Powers off the modem
- `modem_reset()` - Resets the modem
- `sim_enable()` - Enables SIM card
- `sim_disable()` - Disables SIM card
- `usb_enum_enable()` - Enables USB enumeration
- `usb_enum_disable()` - Disables USB enumeration

All control pins are now properly configured in both the device tree and runtime control script!

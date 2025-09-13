#!/bin/bash

# GPIO Control Script for Custom Board
# This script provides functions to control GPIOs using sysfs since gpio-export is not standard

# GPIO Pin Mappings (based on your hardware configuration)
declare -A GPIO_PINS=(
    ["sim-dis-ctrl"]="8"      # PA8
    ["mdm-pwr-ctrl"]="9"      # PA9  
    ["usb-enum-ctrl"]="131"   # PE3 (PE base=128, offset=3)
    ["mdm-on-ctrl"]="132"     # PE4 (PE base=128, offset=4)
    ["mdm-rst-ctrl"]="139"    # PE11 (PE base=128, offset=11)
)

# GPIO Input Pin Mappings (for reading status)
declare -A GPIO_INPUTS=(
    ["batt-chg-st1"]="128"    # PE0
    ["main-reg-pg"]="130"     # PE2  
    ["batt-chg-st2"]="133"    # PE5
    ["pwr-path-st"]="136"     # PE8
    ["uc-attention"]="137"    # PE9
    ["accel-int1"]="224"      # PH0 (PH base=224)
    ["accel-int2"]="161"      # PF3 (PF base=160, offset=3)
    ["usb-detect"]="237"      # PH13 (PH base=224, offset=13)
)

# LED Pin Mappings
declare -A LED_PINS=(
    ["yellow-led"]="161"      # PF1 (PF base=160, offset=1)
    ["green-led"]="164"       # PF4 (PF base=160, offset=4)
    ["red-led"]="166"         # PF6 (PF base=160, offset=6)
)

# Function to export a GPIO
export_gpio() {
    local gpio_num=$1
    if [ ! -d "/sys/class/gpio/gpio${gpio_num}" ]; then
        echo "${gpio_num}" > /sys/class/gpio/export
        if [ $? -eq 0 ]; then
            echo "GPIO ${gpio_num} exported successfully"
        else
            echo "Failed to export GPIO ${gpio_num}"
            return 1
        fi
    else
        echo "GPIO ${gpio_num} already exported"
    fi
}

# Function to set GPIO direction
set_gpio_direction() {
    local gpio_num=$1
    local direction=$2  # "in" or "out"
    
    if [ -d "/sys/class/gpio/gpio${gpio_num}" ]; then
        echo "${direction}" > "/sys/class/gpio/gpio${gpio_num}/direction"
        if [ $? -eq 0 ]; then
            echo "GPIO ${gpio_num} direction set to ${direction}"
        else
            echo "Failed to set GPIO ${gpio_num} direction"
            return 1
        fi
    else
        echo "GPIO ${gpio_num} not exported"
        return 1
    fi
}

# Function to set GPIO value
set_gpio_value() {
    local gpio_num=$1
    local value=$2  # 0 or 1
    
    if [ -f "/sys/class/gpio/gpio${gpio_num}/value" ]; then
        echo "${value}" > "/sys/class/gpio/gpio${gpio_num}/value"
        if [ $? -eq 0 ]; then
            echo "GPIO ${gpio_num} value set to ${value}"
        else
            echo "Failed to set GPIO ${gpio_num} value"
            return 1
        fi
    else
        echo "GPIO ${gpio_num} not available for writing"
        return 1
    fi
}

# Function to read GPIO value
get_gpio_value() {
    local gpio_num=$1
    
    if [ -f "/sys/class/gpio/gpio${gpio_num}/value" ]; then
        local value=$(cat "/sys/class/gpio/gpio${gpio_num}/value")
        echo "${value}"
        return 0
    else
        echo "GPIO ${gpio_num} not available for reading"
        return 1
    fi
}

# Function to initialize control GPIOs
init_control_gpios() {
    echo "Initializing control GPIOs..."
    for name in "${!GPIO_PINS[@]}"; do
        local gpio_num=${GPIO_PINS[$name]}
        export_gpio "$gpio_num"
        set_gpio_direction "$gpio_num" "out"
        set_gpio_value "$gpio_num" "0"  # Initialize to low/off
        echo "Initialized $name (GPIO $gpio_num)"
    done
}

# Function to initialize input GPIOs
init_input_gpios() {
    echo "Initializing input GPIOs..."
    for name in "${!GPIO_INPUTS[@]}"; do
        local gpio_num=${GPIO_INPUTS[$name]}
        export_gpio "$gpio_num"
        set_gpio_direction "$gpio_num" "in"
        echo "Initialized $name (GPIO $gpio_num) as input"
    done
}

# Function to initialize LED GPIOs
init_led_gpios() {
    echo "Initializing LED GPIOs..."
    for name in "${!LED_PINS[@]}"; do
        local gpio_num=${LED_PINS[$name]}
        export_gpio "$gpio_num"
        set_gpio_direction "$gpio_num" "out"
        set_gpio_value "$gpio_num" "0"  # LEDs off initially
        echo "Initialized $name (GPIO $gpio_num)"
    done
}

# Control functions for specific devices
control_sim() {
    local action=$1  # "enable" or "disable"
    local gpio_num=${GPIO_PINS["sim-dis-ctrl"]}
    
    case $action in
        "enable")
            set_gpio_value "$gpio_num" "0"  # Active low to enable SIM
            echo "SIM enabled"
            ;;
        "disable")
            set_gpio_value "$gpio_num" "1"  # Active high to disable SIM
            echo "SIM disabled"
            ;;
        *)
            echo "Usage: control_sim [enable|disable]"
            ;;
    esac
}

control_modem_power() {
    local action=$1  # "on" or "off"
    local gpio_num=${GPIO_PINS["mdm-pwr-ctrl"]}
    
    case $action in
        "on")
            set_gpio_value "$gpio_num" "1"
            echo "Modem power ON"
            ;;
        "off")
            set_gpio_value "$gpio_num" "0"
            echo "Modem power OFF"
            ;;
        *)
            echo "Usage: control_modem_power [on|off]"
            ;;
    esac
}

control_modem_reset() {
    local gpio_num=${GPIO_PINS["mdm-rst-ctrl"]}
    
    echo "Resetting modem..."
    set_gpio_value "$gpio_num" "1"  # Assert reset
    sleep 1
    set_gpio_value "$gpio_num" "0"  # Release reset
    echo "Modem reset complete"
}

control_led() {
    local led_name=$1  # "yellow-led", "green-led", "red-led"
    local state=$2     # "on" or "off"
    
    if [[ -z "${LED_PINS[$led_name]}" ]]; then
        echo "Invalid LED name: $led_name"
        echo "Available LEDs: ${!LED_PINS[@]}"
        return 1
    fi
    
    local gpio_num=${LED_PINS[$led_name]}
    
    case $state in
        "on")
            set_gpio_value "$gpio_num" "1"
            echo "$led_name turned ON"
            ;;
        "off")
            set_gpio_value "$gpio_num" "0"
            echo "$led_name turned OFF"
            ;;
        *)
            echo "Usage: control_led $led_name [on|off]"
            ;;
    esac
}

# Function to read all input statuses
read_input_status() {
    echo "=== Input GPIO Status ==="
    for name in "${!GPIO_INPUTS[@]}"; do
        local gpio_num=${GPIO_INPUTS[$name]}
        if [ -f "/sys/class/gpio/gpio${gpio_num}/value" ]; then
            local value=$(get_gpio_value "$gpio_num")
            echo "$name (GPIO $gpio_num): $value"
        else
            echo "$name (GPIO $gpio_num): Not initialized"
        fi
    done
}

# Help function
show_help() {
    echo "GPIO Control Script for Custom Board"
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  init-all           - Initialize all GPIOs"
    echo "  init-control       - Initialize control GPIOs only"
    echo "  init-input         - Initialize input GPIOs only"
    echo "  init-led           - Initialize LED GPIOs only"
    echo "  sim [enable|disable] - Control SIM"
    echo "  modem-power [on|off] - Control modem power"
    echo "  modem-reset        - Reset modem"
    echo "  led [led-name] [on|off] - Control LED (yellow-led, green-led, red-led)"
    echo "  status             - Read all input statuses"
    echo "  help               - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 init-all"
    echo "  $0 sim enable"
    echo "  $0 modem-power on"
    echo "  $0 led yellow-led on"
    echo "  $0 status"
}

# Main script logic
case "$1" in
    "init-all")
        init_control_gpios
        init_input_gpios
        init_led_gpios
        ;;
    "init-control")
        init_control_gpios
        ;;
    "init-input")
        init_input_gpios
        ;;
    "init-led")
        init_led_gpios
        ;;
    "sim")
        control_sim "$2"
        ;;
    "modem-power")
        control_modem_power "$2"
        ;;
    "modem-reset")
        control_modem_reset
        ;;
    "led")
        control_led "$2" "$3"
        ;;
    "status")
        read_input_status
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

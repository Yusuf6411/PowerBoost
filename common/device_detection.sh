#!/system/bin/sh
#
# PowerBoost Device Detection System
# Detects hardware capabilities and builds device profile
#

# Source common functions
. /data/adb/modules/powerboost/common/powerboost_functions.sh

# Device capability detection
detect_device_capabilities() {
    log_info "Starting device capability detection..."

    # Basic system information
    local android_version=$(get_android_version)
    local manufacturer=$(get_device_manufacturer)
    local hardware=$(get_hardware_platform)
    local board=$(get_board_platform)
    local cpu_count=$(get_cpu_count)

    # CPU capabilities
    local cpu_freq_scaling=$(check_feature_support cpu_freq_scaling && echo "yes" || echo "no")
    local available_governors=$(get_available_governors 0)
    local current_governor=$(get_current_governor 0)
    local cpu_freq_limits=$(get_cpu_freq_limits 0)

    # Thermal capabilities
    local thermal_zones=$(get_thermal_zones)
    local cooling_devices=$(get_cooling_devices)

    # Battery capabilities
    local battery_control=$(check_feature_support battery_charge_control && echo "yes" || echo "no")

    # Display capabilities
    local display_control=$(check_feature_support display_refresh_rate && echo "yes" || echo "no")

    # Connectivity capabilities
    local wifi_power_save=$(check_feature_support wifi_power_save && echo "yes" || echo "no")

    # Build device profile
    local profile_file="$POWERBOOST_DIR/device_profile"

    cat > "$profile_file" << EOF
# PowerBoost Device Profile
# Generated: $(date)

ANDROID_VERSION=$android_version
MANUFACTURER=$manufacturer
HARDWARE=$hardware
BOARD=$board
CPU_COUNT=$cpu_count

# CPU Capabilities
CPU_FREQ_SCALING=$cpu_freq_scaling
AVAILABLE_GOVERNORS="$available_governors"
CURRENT_GOVERNOR=$current_governor
CPU_FREQ_LIMITS="$cpu_freq_limits"

# Thermal Capabilities
THERMAL_ZONES=$thermal_zones
COOLING_DEVICES=$cooling_devices

# Battery Capabilities
BATTERY_CONTROL=$battery_control

# Display Capabilities
DISPLAY_CONTROL=$display_control

# Connectivity Capabilities
WIFI_POWER_SAVE=$wifi_power_save

# Supported Features
SUPPORTED_FEATURES=""

if [ "$cpu_freq_scaling" = "yes" ]; then
    SUPPORTED_FEATURES="$SUPPORTED_FEATURES cpu_freq_scaling"
fi

if [ "$thermal_zones" -gt 0 ]; then
    SUPPORTED_FEATURES="$SUPPORTED_FEATURES thermal_monitoring"
fi

if [ "$cooling_devices" -gt 0 ]; then
    SUPPORTED_FEATURES="$SUPPORTED_FEATURES thermal_control"
fi

if [ "$battery_control" = "yes" ]; then
    SUPPORTED_FEATURES="$SUPPORTED_FEATURES battery_control"
fi

if [ "$display_control" = "yes" ]; then
    SUPPORTED_FEATURES="$SUPPORTED_FEATURES display_control"
fi

if [ "$wifi_power_save" = "yes" ]; then
    SUPPORTED_FEATURES="$SUPPORTED_FEATURES wifi_power_save"
fi

EOF

    log_info "Device profile saved to $profile_file"
    cat "$profile_file"
}

# Detect specific hardware platform
detect_hardware_platform() {
    local board=$(get_board_platform)
    local hardware=$(get_hardware_platform)
    local manufacturer=$(get_device_manufacturer)

    # Qualcomm detection
    if echo "$board" | grep -qi "msm\|sdm\|qcom"; then
        echo "qualcomm"
        return
    fi

    # MediaTek detection
    if echo "$board" | grep -qi "mt\|mediatek"; then
        echo "mediatek"
        return
    fi

    # Exynos detection
    if echo "$board" | grep -qi "exynos\|universal"; then
        echo "exynos"
        return
    fi

    # Tensor detection
    if echo "$board" | grep -qi "gs\|tensor"; then
        echo "tensor"
        return
    fi

    # Unisoc detection
    if echo "$board" | grep -qi "sprd\|unisoc"; then
        echo "unisoc"
        return
    fi

    # Generic detection based on manufacturer
    case "$manufacturer" in
        samsung|Samsung) echo "exynos" ;;
        google|Google) echo "tensor" ;;
        xiaomi|Xiaomi|redmi|Redmi|POCO|poco) echo "qualcomm" ;;
        realme|Realme|oppo|Oppo|oneplus|OnePlus) echo "qualcomm" ;;
        vivo|Vivo|iqoo|IQOO) echo "mediatek" ;;
        motorola|Motorola) echo "qualcomm" ;;
        sony|Sony) echo "qualcomm" ;;
        *) echo "unknown" ;;
    esac
}

# Detect CPU architecture
detect_cpu_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        arm*|aarch64) echo "arm" ;;
        x86_64|i*86) echo "x86" ;;
        *) echo "unknown" ;;
    esac
}

# Detect kernel version
detect_kernel_version() {
    uname -r
}

# Detect SELinux status
detect_selinux_status() {
    if [ -f "/sys/fs/selinux/enforce" ]; then
        local status=$(cat "/sys/fs/selinux/enforce" 2>/dev/null)
        if [ "$status" = "1" ]; then
            echo "enforcing"
        else
            echo "permissive"
        fi
    else
        echo "disabled"
    fi
}

# Detect available CPU governors
detect_cpu_governors() {
    local cpu_count=$(get_cpu_count)
    local governors=""

    for i in $(seq 0 $((cpu_count - 1))); do
        if [ -f "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_available_governors" ]; then
            local cpu_governors=$(cat "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_available_governors")
            if [ -n "$cpu_governors" ]; then
                governors="$governors $cpu_governors"
            fi
        fi
    done

    echo "$governors" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//'
}

# Detect CPU frequency ranges
detect_cpu_frequencies() {
    local cpu_count=$(get_cpu_count)
    local freq_info=""

    for i in $(seq 0 $((cpu_count - 1))); do
        if [ -f "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_available_frequencies" ]; then
            local freqs=$(cat "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_available_frequencies")
            freq_info="$freq_info\nCPU$i: $freqs"
        fi
    done

    echo "$freq_info"
}

# Detect thermal zones and their types
detect_thermal_zones_info() {
    if [ -d "/sys/class/thermal" ]; then
        local zones=$(ls /sys/class/thermal/thermal_zone* 2>/dev/null)
        local zone_info=""

        for zone in $zones; do
            local zone_id=$(basename "$zone" | sed 's/thermal_zone//')
            local type=$(cat "$zone/type" 2>/dev/null)
            local temp=$(get_thermal_temp "thermal_zone$zone_id")
            zone_info="$zone_info\nZone $zone_id: $type ($temp°C)"
        done

        echo "$zone_info"
    fi
}

# Detect cooling devices
detect_cooling_devices_info() {
    if [ -d "/sys/class/thermal" ]; then
        local devices=$(ls /sys/class/thermal/cooling_device* 2>/dev/null)
        local device_info=""

        for device in $devices; do
            local device_id=$(basename "$device" | sed 's/cooling_device//')
            local type=$(cat "$device/type" 2>/dev/null)
            local max_state=$(cat "$device/max_state" 2>/dev/null)
            local cur_state=$(cat "$device/cur_state" 2>/dev/null)
            device_info="$device_info\nDevice $device_id: $type (state: $cur_state/$max_state)"
        done

        echo "$device_info"
    fi
}

# Detect battery information
detect_battery_info() {
    local battery_status=$(get_battery_status)
    local battery_info=""

    # Parse battery status
    while IFS='=' read -r key value; do
        battery_info="$battery_info\n$key: $value"
    done <<< "$battery_status"

    echo "$battery_info"
}

# Detect display information
detect_display_info() {
    local display_info=""

    # Try different display interfaces
    if [ -e "/sys/class/drm/card0/device/display_mode" ]; then
        display_info="$display_info\nDRM Display Mode: $(cat /sys/class/drm/card0/device/display_mode 2>/dev/null)"
    fi

    if [ -e "/sys/devices/platform/soc/*.dsi/display_mode" ]; then
        display_info="$display_info\nDSI Display Mode: $(cat /sys/devices/platform/soc/*.dsi/display_mode 2>/dev/null)"
    fi

    if [ -e "/sys/class/graphics/fb0/msm_fb_panel_mode" ]; then
        display_info="$display_info\nFB Panel Mode: $(cat /sys/class/graphics/fb0/msm_fb_panel_mode 2>/dev/null)"
    fi

    # Get resolution
    if [ -e "/sys/class/graphics/fb0/virtual_size" ]; then
        display_info="$display_info\nResolution: $(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null)"
    fi

    echo "$display_info"
}

# Detect WiFi capabilities
detect_wifi_info() {
    local wifi_info=""

    if is_executable "/system/bin/iw"; then
        wifi_info="$wifi_info\nWiFi Tool: iw available"
    fi

    if is_executable "/system/bin/wpa_cli"; then
        wifi_info="$wifi_info\nWiFi Tool: wpa_cli available"
    fi

    if [ -d "/sys/class/net/wlan0" ]; then
        wifi_info="$wifi_info\nWiFi Interface: wlan0 found"
    fi

    echo "$wifi_info"
}

# Detect mobile data capabilities
detect_mobile_data_info() {
    local mobile_info=""

    if [ -d "/sys/class/net/rmnet_data0" ]; then
        mobile_info="$mobile_info\nMobile Interface: rmnet_data0 found"
    fi

    if [ -d "/sys/class/net/ppp0" ]; then
        mobile_info="$mobile_info\nMobile Interface: ppp0 found"
    fi

    echo "$mobile_info"
}

# Generate comprehensive device report
generate_device_report() {
    log_info "Generating comprehensive device report..."

    local report_file="$POWERBOOST_DIR/device_report.txt"

    cat > "$report_file" << EOF
PowerBoost Device Report
Generated: $(date)
================================

SYSTEM INFORMATION
------------------
Android Version: $(get_android_version)
Manufacturer: $(get_device_manufacturer)
Hardware: $(get_hardware_platform)
Board: $(get_board_platform)
Kernel: $(detect_kernel_version)
SELinux: $(detect_selinux_status)
CPU Architecture: $(detect_cpu_architecture)
Hardware Platform: $(detect_hardware_platform)

CPU INFORMATION
---------------
CPU Count: $(get_cpu_count)
Available Governors: $(detect_cpu_governors)
Current Governor: $(get_current_governor 0)
Available Frequencies:$(detect_cpu_frequencies)

THERMAL INFORMATION
-------------------
Thermal Zones: $(get_thermal_zones)
Thermal Zone Details:$(detect_thermal_zones_info)
Cooling Devices: $(get_cooling_devices)
Cooling Device Details:$(detect_cooling_devices_info)

BATTERY INFORMATION
-------------------
Battery Status:$(detect_battery_info)

DISPLAY INFORMATION
-------------------
Display Control: $(check_feature_support display_refresh_rate && echo "supported" || echo "unsupported")
Display Details:$(detect_display_info)

CONNECTIVITY INFORMATION
-------------------------
WiFi Power Save: $(check_feature_support wifi_power_save && echo "supported" || echo "unsupported")
WiFi Details:$(detect_wifi_info)
Mobile Data Details:$(detect_mobile_data_info)

FEATURE SUPPORT
---------------
CPU Frequency Scaling: $(check_feature_support cpu_freq_scaling && echo "✓" || echo "✗")
Thermal Monitoring: $(check_feature_support thermal_zones && echo "✓" || echo "✗")
Thermal Control: $(check_feature_support thermal_zones && echo "✓" || echo "✗")
Battery Control: $(check_feature_support battery_charge_control && echo "✓" || echo "✗")
Display Control: $(check_feature_support display_refresh_rate && echo "✓" || echo "✗")
WiFi Power Save: $(check_feature_support wifi_power_save && echo "✓" || echo "✗")

EOF

    log_info "Device report saved to $report_file"
    cat "$report_file"
}

# Main detection function
main() {
    check_root || exit 1

    log_info "Starting PowerBoost device detection..."

    # Create device profile
    detect_device_capabilities

    # Generate comprehensive report
    generate_device_report

    log_info "Device detection complete"
}

# Run main function if executed directly
if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi
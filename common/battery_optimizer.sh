#!/system/bin/sh
#
# PowerBoost Battery Optimizer
# Handles battery optimization, charging control, and health monitoring
#

# Source common functions
. /data/adb/modules/powerboost/common/powerboost_functions.sh

# Battery optimization settings per profile
# These will be overridden by profile configurations

# Apply battery optimization
apply_battery_optimization() {
    local optimization="$1"

    log_info "Applying battery optimization: $optimization"

    case "$optimization" in
        aggressive)
            apply_aggressive_battery_optimization
            ;;
        moderate)
            apply_moderate_battery_optimization
            ;;
        balanced)
            apply_balanced_battery_optimization
            ;;
        performance)
            apply_performance_battery_optimization
            ;;
        gaming)
            apply_gaming_battery_optimization
            ;;
        *)
            log_warn "Unknown battery optimization: $optimization"
            return 1
            ;;
    esac
}

# Aggressive battery optimization - maximum savings
apply_aggressive_battery_optimization() {
    log_info "Applying aggressive battery optimization"

    # Reduce wakelocks
    apply_wakelock_optimization "aggressive"

    # Optimize background processes
    apply_background_optimization "aggressive"

    # Network optimizations
    apply_network_optimization "aggressive"

    # Sensor optimizations
    apply_sensor_optimization "aggressive"

    # Display optimizations
    apply_display_battery_optimization "aggressive"

    # CPU optimizations handled by CPU optimizer
}

# Moderate battery optimization - good savings
apply_moderate_battery_optimization() {
    log_info "Applying moderate battery optimization"

    apply_wakelock_optimization "moderate"
    apply_background_optimization "moderate"
    apply_network_optimization "moderate"
    apply_sensor_optimization "moderate"
    apply_display_battery_optimization "moderate"
}

# Balanced battery optimization - default
apply_balanced_battery_optimization() {
    log_info "Applying balanced battery optimization"

    apply_wakelock_optimization "balanced"
    apply_background_optimization "balanced"
    apply_network_optimization "balanced"
    apply_sensor_optimization "balanced"
    apply_display_battery_optimization "balanced"
}

# Performance battery optimization - minimal savings
apply_performance_battery_optimization() {
    log_info "Applying performance battery optimization"

    apply_wakelock_optimization "performance"
    apply_background_optimization "performance"
    apply_network_optimization "performance"
    apply_sensor_optimization "performance"
    apply_display_battery_optimization "performance"
}

# Gaming battery optimization - balanced for gaming
apply_gaming_battery_optimization() {
    log_info "Applying gaming battery optimization"

    apply_wakelock_optimization "gaming"
    apply_background_optimization "gaming"
    apply_network_optimization "gaming"
    apply_sensor_optimization "gaming"
    apply_display_battery_optimization "gaming"
}

# Wakelock optimization
apply_wakelock_optimization() {
    local level="$1"

    case "$level" in
        aggressive)
            # Disable non-critical wakelocks via settings
            if [ -e "/sys/power/wake_unlock" ]; then
                echo "PowerBoost:*" > /sys/power/wake_unlock 2>/dev/null
            fi
            # Reduce alarm wakeups
            settings put global wifi_scan_interval 300 2>/dev/null
            settings put global wifi_scan_always_enabled 0 2>/dev/null
            ;;
        moderate)
            settings put global wifi_scan_interval 180 2>/dev/null
            settings put global wifi_scan_always_enabled 0 2>/dev/null
            ;;
        balanced)
            settings put global wifi_scan_interval 120 2>/dev/null
            settings put global wifi_scan_always_enabled 1 2>/dev/null
            ;;
        performance)
            settings put global wifi_scan_interval 60 2>/dev/null
            settings put global wifi_scan_always_enabled 1 2>/dev/null
            ;;
        gaming)
            settings put global wifi_scan_interval 60 2>/dev/null
            settings put global wifi_scan_always_enabled 1 2>/dev/null
            ;;
    esac
}

# Background process optimization
apply_background_optimization() {
    local level="$1"

    case "$level" in
        aggressive)
            # Restrict background apps more aggressively
            settings put global background_process_limit 4 2>/dev/null
            settings put global activity_manager_constants "max_cached_processes=8" 2>/dev/null
            ;;
        moderate)
            settings put global background_process_limit 8 2>/dev/null
            settings put global activity_manager_constants "max_cached_processes=16" 2>/dev/null
            ;;
        balanced)
            settings put global background_process_limit 16 2>/dev/null
            settings put global activity_manager_constants "max_cached_processes=24" 2>/dev/null
            ;;
        performance|gaming)
            settings put global background_process_limit 32 2>/dev/null
            settings put global activity_manager_constants "max_cached_processes=32" 2>/dev/null
            ;;
    esac
}

# Network optimization
apply_network_optimization() {
    local level="$1"

    case "$level" in
        aggressive)
            # Disable mobile data when on WiFi
            settings put global mobile_data_always_on 0 2>/dev/null
            # Reduce network scanning
            settings put global wifi_scan_interval 300 2>/dev/null
            # Disable network location
            settings put secure location_providers_allowed "" 2>/dev/null
            ;;
        moderate)
            settings put global mobile_data_always_on 0 2>/dev/null
            settings put global wifi_scan_interval 180 2>/dev/null
            ;;
        balanced)
            settings put global mobile_data_always_on 1 2>/dev/null
            settings put global wifi_scan_interval 120 2>/dev/null
            ;;
        performance|gaming)
            settings put global mobile_data_always_on 1 2>/dev/null
            settings put global wifi_scan_interval 60 2>/dev/null
            ;;
    esac
}

# Sensor optimization
apply_sensor_optimization() {
    local level="$1"

    case "$level" in
        aggressive)
            # Disable non-essential sensors via sensor HAL if possible
            # This is device-specific and may not work on all devices
            if [ -e "/sys/class/sensors/proximity_sensor/enable" ]; then
                echo "0" > /sys/class/sensors/proximity_sensor/enable 2>/dev/null
            fi
            if [ -e "/sys/class/sensors/light_sensor/enable" ]; then
                echo "0" > /sys/class/sensors/light_sensor/enable 2>/dev/null
            fi
            ;;
        moderate)
            # Reduce sensor polling rates if possible
            if [ -e "/sys/class/sensors/proximity_sensor/pollrate" ]; then
                echo "5000" > /sys/class/sensors/proximity_sensor/pollrate 2>/dev/null
            fi
            ;;
        balanced|performance|gaming)
            # Default sensor behavior
            if [ -e "/sys/class/sensors/proximity_sensor/enable" ]; then
                echo "1" > /sys/class/sensors/proximity_sensor/enable 2>/dev/null
            fi
            if [ -e "/sys/class/sensors/light_sensor/enable" ]; then
                echo "1" > /sys/class/sensors/light_sensor/enable 2>/dev/null
            fi
            ;;
    esac
}

# Display battery optimization
apply_display_battery_optimization() {
    local level="$1"

    case "$level" in
        aggressive)
            # Reduce screen timeout
            settings put system screen_off_timeout 15000 2>/dev/null
            # Reduce brightness
            settings put system screen_brightness 100 2>/dev/null
            settings put system screen_auto_brightness_adj 0.5 2>/dev/null
            # Reduce refresh rate if possible
            if [ -e "/sys/class/drm/card0/device/display_mode" ]; then
                echo "60" > /sys/class/drm/card0/device/display_mode 2>/dev/null
            fi
            ;;
        moderate)
            settings put system screen_off_timeout 30000 2>/dev/null
            settings put system screen_brightness 120 2>/dev/null
            settings put system screen_auto_brightness_adj 0.7 2>/dev/null
            ;;
        balanced)
            settings put system screen_off_timeout 60000 2>/dev/null
            settings put system screen_brightness 150 2>/dev/null
            settings put system screen_auto_brightness_adj 1.0 2>/dev/null
            ;;
        performance)
            settings put system screen_off_timeout 120000 2>/dev/null
            settings put system screen_brightness 180 2>/dev/null
            settings put system screen_auto_brightness_adj 1.2 2>/dev/null
            ;;
        gaming)
            settings put system screen_off_timeout 120000 2>/dev/null
            settings put system screen_brightness 200 2>/dev/null
            settings put system screen_auto_brightness_adj 1.0 2>/dev/null
            # High refresh rate for gaming
            if [ -e "/sys/class/drm/card0/device/display_mode" ]; then
                echo "120" > /sys/class/drm/card0/device/display_mode 2>/dev/null
            fi
            ;;
    esac
}

# Charging optimization
apply_charging_optimization() {
    local level="$1"

    # Check if battery charge control is supported
    if ! check_feature_support battery_charge_control; then
        log_debug "Battery charge control not supported"
        return 0
    fi

    case "$level" in
        aggressive)
            # Limit charge to 80% for battery health
            if [ -e "/sys/class/power_supply/battery/charge_control_limit" ]; then
                safe_write "/sys/class/power_supply/battery/charge_control_limit" "80" "Charge limit"
            fi
            if [ -e "/sys/class/power_supply/battery/charge_control_end" ]; then
                safe_write "/sys/class/power_supply/battery/charge_control_end" "80" "Charge end"
            fi
            # Disable fast charging if possible
            if [ -e "/sys/class/power_supply/battery/fast_charging" ]; then
                safe_write "/sys/class/power_supply/battery/fast_charging" "0" "Fast charging"
            fi
            ;;
        moderate)
            if [ -e "/sys/class/power_supply/battery/charge_control_limit" ]; then
                safe_write "/sys/class/power_supply/battery/charge_control_limit" "90" "Charge limit"
            fi
            if [ -e "/sys/class/power_supply/battery/charge_control_end" ]; then
                safe_write "/sys/class/power_supply/battery/charge_control_end" "90" "Charge end"
            fi
            ;;
        balanced)
            if [ -e "/sys/class/power_supply/battery/charge_control_limit" ]; then
                safe_write "/sys/class/power_supply/battery/charge_control_limit" "100" "Charge limit"
            fi
            if [ -e "/sys/class/power_supply/battery/charge_control_end" ]; then
                safe_write "/sys/class/power_supply/battery/charge_control_end" "100" "Charge end"
            fi
            # Enable fast charging
            if [ -e "/sys/class/power_supply/battery/fast_charging" ]; then
                safe_write "/sys/class/power_supply/battery/fast_charging" "1" "Fast charging"
            fi
            ;;
        performance|gaming)
            # Full charge, fast charging enabled
            if [ -e "/sys/class/power_supply/battery/charge_control_limit" ]; then
                safe_write "/sys/class/power_supply/battery/charge_control_limit" "100" "Charge limit"
            fi
            if [ -e "/sys/class/power_supply/battery/fast_charging" ]; then
                safe_write "/sys/class/power_supply/battery/fast_charging" "1" "Fast charging"
            fi
            ;;
    esac
}

# Battery health monitoring
monitor_battery_health() {
    local interval="${1:-60}"
    local duration="${2:-3600}"
    local end_time=$(($(date +%s) + duration))

    log_info "Monitoring battery health for ${duration}s (interval: ${interval}s)"

    while [ $(date +%s) -lt $end_time ]; do
        local battery_status=$(get_battery_status)
        local capacity=$(echo "$battery_status" | grep -o 'capacity=[0-9]*' | cut -d'=' -f2)
        local status=$(echo "$battery_status" | grep -o 'status=[A-Za-z]*' | cut -d'=' -f2)
        local health=$(echo "$battery_status" | grep -o 'health=[A-Za-z]*' | cut -d'=' -f2)
        local temp=$(echo "$battery_status" | grep -o 'temp=[0-9]*' | cut -d'=' -f2)
        local current=$(echo "$battery_status" | grep -o 'current=[0-9-]*' | cut -d'=' -f2)
        local voltage=$(echo "$battery_status" | grep -o 'voltage=[0-9]*' | cut -d'=' -f2)

        # Convert temperature
        if [ "$temp" -gt 100 ]; then
            temp=$((temp / 10))
        fi

        # Log battery status
        log_info "Battery: ${capacity}% ${status} Health:${health} Temp:${temp}°C Current:${current}mA Voltage:${voltage}mV"

        # Alert on critical conditions
        if [ "$capacity" -le 15 ] && [ "$status" != "Charging" ]; then
            log_warn "Low battery: ${capacity}%"
        fi

        if [ "$temp" -ge 45 ]; then
            log_warn "High battery temperature: ${temp}°C"
        fi

        if [ "$health" != "Good" ] && [ "$health" != "Unknown" ]; then
            log_warn "Battery health issue: $health"
        fi

        sleep "$interval"
    done
}

# Get battery statistics
get_battery_stats() {
    echo "=== Battery Statistics ==="
    echo ""

    local battery_status=$(get_battery_status)
    local capacity=$(echo "$battery_status" | grep -o 'capacity=[0-9]*' | cut -d'=' -f2)
    local status=$(echo "$battery_status" | grep -o 'status=[A-Za-z]*' | cut -d'=' -f2)
    local health=$(echo "$battery_status" | grep -o 'health=[A-Za-z]*' | cut -d'=' -f2)
    local temp=$(echo "$battery_status" | grep -o 'temp=[0-9]*' | cut -d'=' -f2)
    local current=$(echo "$battery_status" | grep -o 'current=[0-9-]*' | cut -d'=' -f2)
    local voltage=$(echo "$battery_status" | grep -o 'voltage=[0-9]*' | cut -d'=' -f2)

    if [ "$temp" -gt 100 ]; then
        temp=$((temp / 10))
    fi

    echo "Capacity: ${capacity}%"
    echo "Status: $status"
    echo "Health: $health"
    echo "Temperature: ${temp}°C"
    echo "Current: ${current}mA"
    echo "Voltage: ${voltage}mV"

    # Calculate power
    if [ "$current" -ne 0 ] && [ "$voltage" -ne 0 ]; then
        local power_mw=$((current * voltage / 1000))
        local power_w=$(echo "scale=2; $power_mw / 1000" | bc 2>/dev/null || echo "N/A")
        echo "Power: ${power_mw}mW (${power_w}W)"
    fi

    # Charge control status
    if [ -e "/sys/class/power_supply/battery/charge_control_limit" ]; then
        echo "Charge Limit: $(cat /sys/class/power_supply/battery/charge_control_limit)%"
    fi
    if [ -e "/sys/class/power_supply/battery/fast_charging" ]; then
        echo "Fast Charging: $(cat /sys/class/power_supply/battery/fast_charging)"
    fi
}

# Estimate battery time remaining
estimate_battery_time() {
    local battery_status=$(get_battery_status)
    local capacity=$(echo "$battery_status" | grep -o 'capacity=[0-9]*' | cut -d'=' -f2)
    local current=$(echo "$battery_status" | grep -o 'current=[0-9-]*' | cut -d'=' -f2)
    local status=$(echo "$battery_status" | grep -o 'status=[A-Za-z]*' | cut -d'=' -f2)

    if [ "$status" = "Charging" ]; then
        echo "Charging..."
        return
    fi

    if [ "$current" -ge 0 ]; then
        echo "Unknown (current not negative)"
        return
    fi

    # Convert current to positive mA
    local current_ma=${current#-}

    if [ "$current_ma" -gt 0 ]; then
        # Estimate hours remaining
        local hours=$((capacity * 1000 / current_ma))
        local minutes=$(((capacity * 1000 % current_ma) * 60 / current_ma))
        echo "${hours}h ${minutes}m remaining"
    else
        echo "Unknown"
    fi
}

# Adaptive battery optimization based on usage
apply_adaptive_battery() {
    local current_hour=$(date +%H)
    local battery_status=$(get_battery_status)
    local capacity=$(echo "$battery_status" | grep -o 'capacity=[0-9]*' | cut -d'=' -f2)
    local status=$(echo "$battery_status" | grep -o 'status=[A-Za-z]*' | cut -d'=' -f2)

    log_info "Applying adaptive battery optimization (Hour: $current_hour, Battery: ${capacity}%, Status: $status)"

    # Night time optimization (10PM - 6AM)
    if [ "$current_hour" -ge 22 ] || [ "$current_hour" -lt 6 ]; then
        if [ "$status" != "Charging" ]; then
            apply_aggressive_battery_optimization
        else
            apply_charging_optimization "aggressive"
        fi
        return
    fi

    # Low battery optimization
    if [ "$capacity" -le 20 ] && [ "$status" != "Charging" ]; then
        apply_aggressive_battery_optimization
        return
    fi

    # Medium battery optimization
    if [ "$capacity" -le 40 ] && [ "$status" != "Charging" ]; then
        apply_moderate_battery_optimization
        return
    fi

    # Default to balanced
    apply_balanced_battery_optimization
}

# Export functions
export -f apply_battery_optimization apply_aggressive_battery_optimization
export -f apply_moderate_battery_optimization apply_balanced_battery_optimization
export -f apply_performance_battery_optimization apply_gaming_battery_optimization
export -f apply_wakelock_optimization apply_background_optimization
export -f apply_network_optimization apply_sensor_optimization
export -f apply_display_battery_optimization apply_charging_optimization
export -f monitor_battery_health get_battery_stats estimate_battery_time
export -f apply_adaptive_battery
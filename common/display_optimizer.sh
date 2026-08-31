#!/system/bin/sh
#
# PowerBoost Display Optimizer
# Handles display refresh rate, brightness, and power optimization
#

# Source common functions
. /data/adb/modules/powerboost/common/powerboost_functions.sh

# Display optimization settings per profile
# These will be overridden by profile configurations

# Set display refresh rate
set_display_refresh_rate() {
    local rate="$1"

    log_info "Setting display refresh rate: ${rate}Hz"

    # Try different display interfaces
    if [ -e "/sys/class/drm/card0/device/display_mode" ]; then
        safe_write "/sys/class/drm/card0/device/display_mode" "$rate" "DRM display mode"
    elif [ -e "/sys/devices/platform/soc/*.dsi/display_mode" ]; then
        safe_write "/sys/devices/platform/soc/*.dsi/display_mode" "$rate" "DSI display mode"
    elif [ -e "/sys/class/graphics/fb0/msm_fb_panel_mode" ]; then
        safe_write "/sys/class/graphics/fb0/msm_fb_panel_mode" "$rate" "FB panel mode"
    else
        log_warn "Display refresh rate control not available"
        return 1
    fi

    return 0
}

# Set display brightness limit
set_display_brightness_limit() {
    local limit="$1"

    log_info "Setting display brightness limit: ${limit}"

    # Set maximum brightness
    if [ -e "/sys/class/backlight/panel0-backlight/max_brightness" ]; then
        local max_brightness=$(cat "/sys/class/backlight/panel0-backlight/max_brightness" 2>/dev/null)
        if [ -n "$max_brightness" ] && [ "$max_brightness" -gt 0 ]; then
            local target=$((max_brightness * limit / 100))
            safe_write "/sys/class/backlight/panel0-backlight/brightness" "$target" "Display brightness"
        fi
    fi

    # Set brightness limit via settings
    settings put system screen_brightness "$limit" 2>/dev/null
}

# Apply display optimization
apply_display_optimization() {
    local optimization="$1"

    log_info "Applying display optimization: $optimization"

    case "$optimization" in
        battery)
            apply_battery_display
            ;;
        moderate)
            apply_moderate_display
            ;;
        balanced)
            apply_balanced_display
            ;;
        performance)
            apply_performance_display
            ;;
        gaming)
            apply_gaming_display
            ;;
        *)
            log_warn "Unknown display optimization: $optimization"
            return 1
            ;;
    esac
}

# Battery display optimization
apply_battery_display() {
    log_info "Applying battery display optimization"

    # Lower refresh rate
    set_display_refresh_rate "60"

    # Reduce brightness
    set_display_brightness_limit "80"

    # Reduce screen timeout
    settings put system screen_off_timeout 15000 2>/dev/null

    # Disable auto-brightness or set lower target
    settings put system screen_auto_brightness_adj 0.5 2>/dev/null
}

# Moderate display optimization
apply_moderate_display() {
    log_info "Applying moderate display optimization"

    set_display_refresh_rate "60"
    set_display_brightness_limit "90"
    settings put system screen_off_timeout 30000 2>/dev/null
    settings put system screen_auto_brightness_adj 0.7 2>/dev/null
}

# Balanced display optimization
apply_balanced_display() {
    log_info "Applying balanced display optimization"

    set_display_refresh_rate "60"
    set_display_brightness_limit "100"
    settings put system screen_off_timeout 60000 2>/dev/null
    settings put system screen_auto_brightness_adj 1.0 2>/dev/null
}

# Performance display optimization
apply_performance_display() {
    log_info "Applying performance display optimization"

    set_display_refresh_rate "90"
    set_display_brightness_limit "120"
    settings put system screen_off_timeout 120000 2>/dev/null
    settings put system screen_auto_brightness_adj 1.2 2>/dev/null
}

# Gaming display optimization
apply_gaming_display() {
    log_info "Applying gaming display optimization"

    # High refresh rate for gaming
    set_display_refresh_rate "120"
    set_display_brightness_limit "150"
    settings put system screen_off_timeout 120000 2>/dev/null
    settings put system screen_auto_brightness_adj 1.0 2>/dev/null
}

# Adaptive display optimization based on content
apply_adaptive_display() {
    local current_hour=$(date +%H)
    local battery_status=$(get_battery_status)
    local capacity=$(echo "$battery_status" | grep -o 'capacity=[0-9]*' | cut -d'=' -f2)

    log_info "Applying adaptive display optimization (Hour: $current_hour, Battery: ${capacity}%)"

    # Night time optimization
    if [ "$current_hour" -ge 22 ] || [ "$current_hour" -lt 6 ]; then
        apply_battery_display
        return
    fi

    # Low battery optimization
    if [ "$capacity" -le 20 ]; then
        apply_battery_display
        return
    fi

    # Default to balanced
    apply_balanced_display
}

# Get display information
get_display_info() {
    echo "=== Display Information ==="
    echo ""

    # Get current brightness
    if [ -e "/sys/class/backlight/panel0-backlight/brightness" ]; then
        local brightness=$(cat "/sys/class/backlight/panel0-backlight/brightness" 2>/dev/null)
        local max_brightness=$(cat "/sys/class/backlight/panel0-backlight/max_brightness" 2>/dev/null)
        if [ -n "$brightness" ] && [ -n "$max_brightness" ]; then
            local percentage=$((brightness * 100 / max_brightness))
            echo "Brightness: ${percentage}% (${brightness}/${max_brightness})"
        fi
    fi

    # Get screen timeout
    local timeout=$(settings get system screen_off_timeout 2>/dev/null)
    if [ -n "$timeout" ]; then
        echo "Screen Timeout: ${timeout}ms ($((timeout / 1000))s)"
    fi

    # Get auto-brightness
    local auto_brightness=$(settings get system screen_auto_brightness_adj 2>/dev/null)
    if [ -n "$auto_brightness" ]; then
        echo "Auto Brightness: ${auto_brightness}"
    fi

    # Get refresh rate
    if [ -e "/sys/class/drm/card0/device/display_mode" ]; then
        echo "Refresh Rate: $(cat /sys/class/drm/card0/device/display_mode 2>/dev/null)Hz"
    elif [ -e "/sys/devices/platform/soc/*.dsi/display_mode" ]; then
        echo "Refresh Rate: $(cat /sys/devices/platform/soc/*.dsi/display_mode 2>/dev/null)Hz"
    elif [ -e "/sys/class/graphics/fb0/msm_fb_panel_mode" ]; then
        echo "Refresh Rate: $(cat /sys/class/graphics/fb0/msm_fb_panel_mode 2>/dev/null)Hz"
    else
        echo "Refresh Rate: Unknown"
    fi

    # Get resolution
    if [ -e "/sys/class/graphics/fb0/virtual_size" ]; then
        echo "Resolution: $(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null)"
    fi
}

# Monitor display usage
monitor_display() {
    local interval="${1:-60}"
    local duration="${2:-3600}"
    local end_time=$(($(date +%s) + duration))

    log_info "Monitoring display for ${duration}s (interval: ${interval}s)"

    while [ $(date +%s) -lt $end_time ]; do
        local brightness=$(settings get system screen_brightness 2>/dev/null)
        local timeout=$(settings get system screen_off_timeout 2>/dev/null)
        local auto_brightness=$(settings get system screen_auto_brightness_adj 2>/dev/null)

        log_info "Display: Brightness=${brightness}% Timeout=${timeout}ms Auto=${auto_brightness}"

        sleep "$interval"
    done
}

# Export functions
export -f set_display_refresh_rate set_display_brightness_limit apply_display_optimization
export -f apply_battery_display apply_moderate_display apply_balanced_display
export -f apply_performance_display apply_gaming_display apply_adaptive_display
export -f get_display_info monitor_display
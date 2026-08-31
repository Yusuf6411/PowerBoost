#!/system/bin/sh
#
# PowerBoost Connectivity Optimizer
# Handles Wi-Fi, mobile data, and network optimization
#

# Source common functions
. /data/adb/modules/powerboost/common/powerboost_functions.sh

# Connectivity optimization settings per profile
# These will be overridden by profile configurations

# Set Wi-Fi power save mode
set_wifi_power_save() {
    local mode="$1"

    log_info "Setting Wi-Fi power save: $mode"

    case "$mode" in
        aggressive)
            # Enable aggressive power save
            if is_executable "/system/bin/iw"; then
                iw dev wlan0 set power_save on 2>/dev/null
            fi
            if is_executable "/system/bin/wpa_cli"; then
                wpa_cli -i wlan0 set power_save 1 2>/dev/null
            fi
            ;;
        moderate)
            # Enable moderate power save
            if is_executable "/system/bin/iw"; then
                iw dev wlan0 set power_save on 2>/dev/null
            fi
            ;;
        balanced)
            # Enable balanced power save
            if is_executable "/system/bin/iw"; then
                iw dev wlan0 set power_save on 2>/dev/null
            fi
            ;;
        performance|gaming)
            # Disable power save for performance
            if is_executable "/system/bin/iw"; then
                iw dev wlan0 set power_save off 2>/dev/null
            fi
            if is_executable "/system/bin/wpa_cli"; then
                wpa_cli -i wlan0 set power_save 0 2>/dev/null
            fi
            ;;
        *)
            log_warn "Unknown Wi-Fi power save mode: $mode"
            return 1
            ;;
    esac

    return 0
}

# Apply mobile data optimization
apply_mobile_data_optimization() {
    local optimization="$1"

    log_info "Applying mobile data optimization: $optimization"

    case "$optimization" in
        aggressive)
            # Disable mobile data when on WiFi
            settings put global mobile_data_always_on 0 2>/dev/null
            # Reduce network scanning
            settings put global wifi_scan_interval 300 2>/dev/null
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

# Apply connectivity optimization
apply_connectivity_optimization() {
    local optimization="$1"

    log_info "Applying connectivity optimization: $optimization"

    case "$optimization" in
        aggressive)
            apply_aggressive_connectivity
            ;;
        moderate)
            apply_moderate_connectivity
            ;;
        balanced)
            apply_balanced_connectivity
            ;;
        performance)
            apply_performance_connectivity
            ;;
        gaming)
            apply_gaming_connectivity
            ;;
        *)
            log_warn "Unknown connectivity optimization: $optimization"
            return 1
            ;;
    esac
}

# Aggressive connectivity optimization
apply_aggressive_connectivity() {
    log_info "Applying aggressive connectivity optimization"

    set_wifi_power_save "aggressive"
    apply_mobile_data_optimization "aggressive"

    # Disable network location
    settings put secure location_providers_allowed "" 2>/dev/null

    # Reduce sync frequency
    settings put global sync_interval 3600 2>/dev/null
}

# Moderate connectivity optimization
apply_moderate_connectivity() {
    log_info "Applying moderate connectivity optimization"

    set_wifi_power_save "moderate"
    apply_mobile_data_optimization "moderate"

    settings put secure location_providers_allowed "gps" 2>/dev/null
    settings put global sync_interval 1800 2>/dev/null
}

# Balanced connectivity optimization
apply_balanced_connectivity() {
    log_info "Applying balanced connectivity optimization"

    set_wifi_power_save "balanced"
    apply_mobile_data_optimization "balanced"

    settings put secure location_providers_allowed "gps,wifi,network" 2>/dev/null
    settings put global sync_interval 900 2>/dev/null
}

# Performance connectivity optimization
apply_performance_connectivity() {
    log_info "Applying performance connectivity optimization"

    set_wifi_power_save "performance"
    apply_mobile_data_optimization "performance"

    settings put secure location_providers_allowed "gps,wifi,network" 2>/dev/null
    settings put global sync_interval 300 2>/dev/null
}

# Gaming connectivity optimization
apply_gaming_connectivity() {
    log_info "Applying gaming connectivity optimization"

    set_wifi_power_save "gaming"
    apply_mobile_data_optimization "gaming"

    settings put secure location_providers_allowed "gps,wifi,network" 2>/dev/null
    settings put global sync_interval 300 2>/dev/null

    # Disable WiFi power save completely for gaming
    set_wifi_power_save "performance"
}

# Adaptive connectivity optimization
apply_adaptive_connectivity() {
    local current_hour=$(date +%H)
    local battery_status=$(get_battery_status)
    local capacity=$(echo "$battery_status" | grep -o 'capacity=[0-9]*' | cut -d'=' -f2)

    log_info "Applying adaptive connectivity optimization (Hour: $current_hour, Battery: ${capacity}%)"

    # Night time optimization
    if [ "$current_hour" -ge 22 ] || [ "$current_hour" -lt 6 ]; then
        apply_aggressive_connectivity
        return
    fi

    # Low battery optimization
    if [ "$capacity" -le 20 ]; then
        apply_aggressive_connectivity
        return
    fi

    # Default to balanced
    apply_balanced_connectivity
}

# Get connectivity information
get_connectivity_info() {
    echo "=== Connectivity Information ==="
    echo ""

    # WiFi information
    if is_executable "/system/bin/iw"; then
        echo "WiFi Tool: iw available"
        iw dev 2>/dev/null | grep -E "Interface|type|addr" | head -5
    fi

    if is_executable "/system/bin/wpa_cli"; then
        echo "WiFi Tool: wpa_cli available"
    fi

    # Mobile data information
    if [ -d "/sys/class/net/rmnet_data0" ]; then
        echo "Mobile Interface: rmnet_data0 found"
    fi

    # Network settings
    echo ""
    echo "Network Settings:"
    echo "  WiFi Scan Interval: $(settings get global wifi_scan_interval 2>/dev/null) seconds"
    echo "  Mobile Data Always On: $(settings get global mobile_data_always_on 2>/dev/null)"
    echo "  Sync Interval: $(settings get global sync_interval 2>/dev/null) seconds"
    echo "  Location Providers: $(settings get secure location_providers_allowed 2>/dev/null)"
}

# Monitor connectivity
monitor_connectivity() {
    local interval="${1:-60}"
    local duration="${2:-3600}"
    local end_time=$(($(date +%s) + duration))

    log_info "Monitoring connectivity for ${duration}s (interval: ${interval}s)"

    while [ $(date +%s) -lt $end_time ]; do
        local wifi_scan=$(settings get global wifi_scan_interval 2>/dev/null)
        local mobile_data=$(settings get global mobile_data_always_on 2>/dev/null)
        local sync_interval=$(settings get global sync_interval 2>/dev/null)

        log_info "Connectivity: WiFiScan=${wifi_scan}s MobileData=${mobile_data} Sync=${sync_interval}s"

        sleep "$interval"
    done
}

# Export functions
export -f set_wifi_power_save apply_mobile_data_optimization apply_connectivity_optimization
export -f apply_aggressive_connectivity apply_moderate_connectivity apply_balanced_connectivity
export -f apply_performance_connectivity apply_gaming_connectivity apply_adaptive_connectivity
export -f get_connectivity_info monitor_connectivity
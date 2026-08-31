#!/system/bin/sh
#
# PowerBoost Thermal Manager
# Handles thermal monitoring, cooling device control, and throttling prevention
#

# Source common functions
. /data/adb/modules/powerboost/common/powerboost_functions.sh

# Thermal optimization settings per profile
# These will be overridden by profile configurations

# Apply thermal policy
apply_thermal_policy() {
    local policy="$1"

    log_info "Applying thermal policy: $policy"

    case "$policy" in
        conservative)
            apply_conservative_thermal
            ;;
        balanced)
            apply_balanced_thermal
            ;;
        performance)
            apply_performance_thermal
            ;;
        gaming)
            apply_gaming_thermal
            ;;
        *)
            log_warn "Unknown thermal policy: $policy"
            return 1
            ;;
    esac
}

# Conservative thermal policy - prioritize cooling
apply_conservative_thermal() {
    log_info "Applying conservative thermal policy"

    # Enable all cooling devices at lower thresholds
    local cooling_count=$(get_cooling_devices)

    for i in $(seq 0 $((cooling_count - 1))); do
        if [ -e "/sys/class/thermal/cooling_device${i}/cur_state" ]; then
            local max_state=$(cat "/sys/class/thermal/cooling_device${i}/max_state" 2>/dev/null)
            if [ -n "$max_state" ] && [ "$max_state" -gt 0 ]; then
                # Set to moderate cooling state
                local target_state=$((max_state / 2))
                safe_write "/sys/class/thermal/cooling_device${i}/cur_state" "$target_state" "Cooling device $i conservative"
            fi
        fi
    done

    # Set thermal zone trip points if writable
    if [ -d "/sys/class/thermal" ]; then
        for zone in /sys/class/thermal/thermal_zone*; do
            if [ -e "$zone/trip_point_0_temp" ]; then
                # Lower trip points for earlier throttling
                local trip_temp=$(cat "$zone/trip_point_0_temp" 2>/dev/null)
                if [ -n "$trip_temp" ] && [ "$trip_temp" -gt 60000 ]; then
                    safe_write "$zone/trip_point_0_temp" "55000" "Thermal zone $(basename $zone) trip point"
                fi
            fi
        done
    fi
}

# Balanced thermal policy - moderate cooling
apply_balanced_thermal() {
    log_info "Applying balanced thermal policy"

    # Enable cooling devices at moderate thresholds
    local cooling_count=$(get_cooling_devices)

    for i in $(seq 0 $((cooling_count - 1))); do
        if [ -e "/sys/class/thermal/cooling_device${i}/cur_state" ]; then
            local max_state=$(cat "/sys/class/thermal/cooling_device${i}/max_state" 2>/dev/null)
            if [ -n "$max_state" ] && [ "$max_state" -gt 0 ]; then
                # Set to light cooling state
                local target_state=$((max_state / 4))
                safe_write "/sys/class/thermal/cooling_device${i}/cur_state" "$target_state" "Cooling device $i balanced"
            fi
        fi
    done

    # Default thermal zone trip points
    if [ -d "/sys/class/thermal" ]; then
        for zone in /sys/class/thermal/thermal_zone*; do
            if [ -e "$zone/trip_point_0_temp" ]; then
                local trip_temp=$(cat "$zone/trip_point_0_temp" 2>/dev/null)
                if [ -n "$trip_temp" ] && [ "$trip_temp" -gt 70000 ]; then
                    safe_write "$zone/trip_point_0_temp" "65000" "Thermal zone $(basename $zone) trip point"
                fi
            fi
        done
    fi
}

# Performance thermal policy - minimal cooling intervention
apply_performance_thermal() {
    log_info "Applying performance thermal policy"

    # Disable cooling devices or set to minimum
    local cooling_count=$(get_cooling_devices)

    for i in $(seq 0 $((cooling_count - 1))); do
        if [ -e "/sys/class/thermal/cooling_device${i}/cur_state" ]; then
            safe_write "/sys/class/thermal/cooling_device${i}/cur_state" "0" "Cooling device $i performance"
        fi
    done

    # Higher thermal trip points
    if [ -d "/sys/class/thermal" ]; then
        for zone in /sys/class/thermal/thermal_zone*; do
            if [ -e "$zone/trip_point_0_temp" ]; then
                local trip_temp=$(cat "$zone/trip_point_0_temp" 2>/dev/null)
                if [ -n "$trip_temp" ] && [ "$trip_temp" -lt 75000 ]; then
                    safe_write "$zone/trip_point_0_temp" "75000" "Thermal zone $(basename $zone) trip point"
                fi
            fi
        done
    fi
}

# Gaming thermal policy - sustained performance with thermal management
apply_gaming_thermal() {
    log_info "Applying gaming thermal policy"

    # Enable cooling devices proactively but not aggressively
    local cooling_count=$(get_cooling_devices)

    for i in $(seq 0 $((cooling_count - 1))); do
        if [ -e "/sys/class/thermal/cooling_device${i}/cur_state" ]; then
            local max_state=$(cat "/sys/class/thermal/cooling_device${i}/max_state" 2>/dev/null)
            if [ -n "$max_state" ] && [ "$max_state" -gt 0 ]; then
                # Set to moderate cooling for sustained performance
                local target_state=$((max_state / 3))
                safe_write "/sys/class/thermal/cooling_device${i}/cur_state" "$target_state" "Cooling device $i gaming"
            fi
        fi
    done

    # Gaming-optimized thermal trip points
    if [ -d "/sys/class/thermal" ]; then
        for zone in /sys/class/thermal/thermal_zone*; do
            if [ -e "$zone/trip_point_0_temp" ]; then
                local trip_temp=$(cat "$zone/trip_point_0_temp" 2>/dev/null)
                if [ -n "$trip_temp" ] && [ "$trip_temp" -gt 65000 ]; then
                    safe_write "$zone/trip_point_0_temp" "68000" "Thermal zone $(basename $zone) trip point"
                fi
            fi
        done
    fi
}

# Monitor thermal status
monitor_thermal() {
    local interval="${1:-5}"
    local duration="${2:-60}"
    local end_time=$(($(date +%s) + duration))

    log_info "Monitoring thermal for ${duration}s (interval: ${interval}s)"

    while [ $(date +%s) -lt $end_time ]; do
        local zone_count=$(get_thermal_zones)

        for i in $(seq 0 $((zone_count - 1))); do
            local zone="thermal_zone$i"
            local type=$(safe_read "/sys/class/thermal/${zone}/type" "unknown")
            local temp=$(get_thermal_temp "$zone")

            # Log if temperature is high
            if [ "$temp" -gt 60 ]; then
                log_warn "Thermal $zone ($type): ${temp}°C - HIGH TEMPERATURE"
            elif [ "$temp" -gt 45 ]; then
                log_info "Thermal $zone ($type): ${temp}°C - WARM"
            else
                log_debug "Thermal $zone ($type): ${temp}°C"
            fi
        done

        # Log cooling device states
        local cooling_count=$(get_cooling_devices)
        for i in $(seq 0 $((cooling_count - 1))); do
            local device="cooling_device$i"
            local type=$(safe_read "/sys/class/thermal/${device}/type" "unknown")
            local cur_state=$(safe_read "/sys/class/thermal/${device}/cur_state" "0")
            local max_state=$(safe_read "/sys/class/thermal/${device}/max_state" "0")

            if [ "$cur_state" -gt 0 ]; then
                log_debug "Cooling $device ($type): state $cur_state/$max_state"
            fi
        done

        sleep "$interval"
    done
}

# Get thermal statistics
get_thermal_stats() {
    echo "=== Thermal Statistics ==="
    echo ""

    local zone_count=$(get_thermal_zones)
    echo "Thermal Zones: $zone_count"

    for i in $(seq 0 $((zone_count - 1))); do
        local zone="thermal_zone$i"
        local type=$(safe_read "/sys/class/thermal/${zone}/type" "unknown")
        local temp=$(get_thermal_temp "$zone")
        local mode=$(safe_read "/sys/class/thermal/${zone}/mode" "unknown")

        echo "  Zone $i ($type): ${temp}°C, mode=$mode"

        # Show trip points
        local trip=0
        while [ -e "/sys/class/thermal/${zone}/trip_point_${trip}_temp" ]; do
            local trip_temp=$(cat "/sys/class/thermal/${zone}/trip_point_${trip}_temp" 2>/dev/null)
            local trip_type=$(cat "/sys/class/thermal/${zone}/trip_point_${trip}_type" 2>/dev/null)
            if [ -n "$trip_temp" ]; then
                local trip_temp_c=$((trip_temp / 1000))
                echo "    Trip $trip ($trip_type): ${trip_temp_c}°C"
            fi
            trip=$((trip + 1))
        done
    done

    echo ""
    local cooling_count=$(get_cooling_devices)
    echo "Cooling Devices: $cooling_count"

    for i in $(seq 0 $((cooling_count - 1))); do
        local device="cooling_device$i"
        local type=$(safe_read "/sys/class/thermal/${device}/type" "unknown")
        local cur_state=$(safe_read "/sys/class/thermal/${device}/cur_state" "0")
        local max_state=$(safe_read "/sys/class/thermal/${device}/max_state" "0")

        echo "  Device $i ($type): state $cur_state/$max_state"
    done
}

# Check for thermal throttling
check_thermal_throttling() {
    local throttled=false

    local zone_count=$(get_thermal_zones)
    for i in $(seq 0 $((zone_count - 1))); do
        local zone="thermal_zone$i"
        local temp=$(get_thermal_temp "$zone")

        if [ "$temp" -ge 80 ]; then
            log_warn "CRITICAL: Thermal zone $zone at ${temp}°C - likely throttling!"
            throttled=true
        elif [ "$temp" -ge 70 ]; then
            log_warn "WARNING: Thermal zone $zone at ${temp}°C - approaching throttle"
            throttled=true
        fi
    done

    if [ "$throttled" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Apply thermal mitigation based on current temperature
apply_thermal_mitigation() {
    local zone_count=$(get_thermal_zones)
    local max_temp=0
    local hottest_zone=""

    # Find hottest zone
    for i in $(seq 0 $((zone_count - 1))); do
        local zone="thermal_zone$i"
        local temp=$(get_thermal_temp "$zone")
        if [ "$temp" -gt "$max_temp" ]; then
            max_temp=$temp
            hottest_zone="$zone"
        fi
    done

    log_info "Hottest zone: $hottest_zone at ${max_temp}°C"

    # Apply mitigation based on temperature
    if [ "$max_temp" -ge 80 ]; then
        log_warn "CRITICAL TEMPERATURE: Applying aggressive mitigation"
        apply_conservative_thermal
        # Could also trigger CPU frequency reduction
        set_cpu_governor "powersave"
    elif [ "$max_temp" -ge 70 ]; then
        log_warn "HIGH TEMPERATURE: Applying moderate mitigation"
        apply_balanced_thermal
    elif [ "$max_temp" -ge 60 ]; then
        log_info "ELEVATED TEMPERATURE: Monitoring"
    else
        log_debug "Temperature normal: ${max_temp}°C"
    fi
}

# Get thermal zone by type
get_thermal_zone_by_type() {
    local target_type="$1"
    local zone_count=$(get_thermal_zones)

    for i in $(seq 0 $((zone_count - 1))); do
        local zone="thermal_zone$i"
        local type=$(safe_read "/sys/class/thermal/${zone}/type" "unknown")
        if [ "$type" = "$target_type" ]; then
            echo "$zone"
            return 0
        fi
    done

    return 1
}

# Get CPU thermal zone temperature
get_cpu_temp() {
    local cpu_zone=$(get_thermal_zone_by_type "cpu-thermal")
    if [ -z "$cpu_zone" ]; then
        cpu_zone=$(get_thermal_zone_by_type "cpu")
    fi
    if [ -z "$cpu_zone" ]; then
        cpu_zone=$(get_thermal_zone_by_type "CPU")
    fi
    if [ -z "$cpu_zone" ]; then
        # Fallback to first zone
        cpu_zone="thermal_zone0"
    fi

    get_thermal_temp "$cpu_zone"
}

# Get GPU thermal zone temperature
get_gpu_temp() {
    local gpu_zone=$(get_thermal_zone_by_type "gpu-thermal")
    if [ -z "$gpu_zone" ]; then
        gpu_zone=$(get_thermal_zone_by_type "gpu")
    fi
    if [ -z "$gpu_zone" ]; then
        gpu_zone=$(get_thermal_zone_by_type "GPU")
    fi

    if [ -n "$gpu_zone" ]; then
        get_thermal_temp "$gpu_zone"
    else
        echo "N/A"
    fi
}

# Get battery thermal zone temperature
get_battery_temp() {
    local bat_zone=$(get_thermal_zone_by_type "battery")
    if [ -z "$bat_zone" ]; then
        bat_zone=$(get_thermal_zone_by_type "battery-thermal")
    fi
    if [ -z "$bat_zone" ]; then
        bat_zone=$(get_thermal_zone_by_type "batt")
    fi

    if [ -n "$bat_zone" ]]; then
        get_thermal_temp "$bat_zone"
    else
        # Fallback to battery sysfs
        local temp=$(safe_read "/sys/class/power_supply/battery/temp" "0")
        if [ "$temp" -gt 100 ]; then
            echo $((temp / 10))
        else
            echo "$temp"
        fi
    fi
}

# Export functions
export -f apply_thermal_policy apply_conservative_thermal apply_balanced_thermal
export -f apply_performance_thermal apply_gaming_thermal monitor_thermal
export -f get_thermal_stats check_thermal_throttling apply_thermal_mitigation
export -f get_thermal_zone_by_type get_cpu_temp get_gpu_temp get_battery_temp
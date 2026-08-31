#!/system/bin/sh
#
# PowerBoost Core Functions Library
# Common utility functions used across all optimization modules
#

# Set up logging
POWERBOOST_LOG="/cache/powerboost.log"
POWERBOOST_DIR="/data/adb/modules/powerboost"

# Ensure log directory exists
mkdir -p /cache

# Logging functions
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$POWERBOOST_LOG"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$POWERBOOST_LOG"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$POWERBOOST_LOG"
}

log_debug() {
    if [ "$POWERBOOST_DEBUG" = "1" ]; then
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$POWERBOOST_LOG"
    fi
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must run as root"
        return 1
    fi
    return 0
}

# Check if sysfs interface exists and is writable
check_interface() {
    local interface="$1"
    if [ -e "$interface" ]; then
        if [ -w "$interface" ]; then
            log_debug "Interface $interface is writable"
            return 0
        else
            log_warn "Interface $interface exists but not writable"
            return 1
        fi
    else
        log_debug "Interface $interface does not exist"
        return 1
    fi
}

# Safe write to sysfs interface
safe_write() {
    local interface="$1"
    local value="$2"
    local description="$3"

    if check_interface "$interface"; then
        local current=$(cat "$interface" 2>/dev/null)
        if [ "$current" != "$value" ]; then
            echo "$value" > "$interface" 2>/dev/null
            if [ $? -eq 0 ]; then
                log_info "Set $description: $current -> $value"
                return 0
            else
                log_error "Failed to set $description to $value"
                return 1
            fi
        else
            log_debug "$description already set to $value"
            return 0
        fi
    else
        log_warn "Cannot write to $description ($interface)"
        return 1
    fi
}

# Read sysfs value safely
safe_read() {
    local interface="$1"
    local default="$2"

    if [ -r "$interface" ]; then
        cat "$interface" 2>/dev/null
    else
        echo "$default"
    fi
}

# Get CPU count
get_cpu_count() {
    ls -d /sys/devices/system/cpu/cpu[0-9]* 2>/dev/null | wc -l
}

# Get available governors for a CPU
get_available_governors() {
    local cpu="${1:-0}"
    safe_read "/sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_available_governors" "powersave performance"
}

# Get current governor
get_current_governor() {
    local cpu="${1:-0}"
    safe_read "/sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_governor" "unknown"
}

# Get CPU frequency limits
get_cpu_freq_limits() {
    local cpu="${1:-0}"
    local min_freq=$(safe_read "/sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_min_freq" "0")
    local max_freq=$(safe_read "/sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_max_freq" "0")
    echo "$min_freq $max_freq"
}

# Set CPU governor
set_cpu_governor() {
    local governor="$1"
    local cpu_count=$(get_cpu_count)
    local success=0

    for i in $(seq 0 $((cpu_count - 1))); do
        if safe_write "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor" "$governor" "CPU${i} governor"; then
            success=$((success + 1))
        fi
    done

    log_info "Set governor to $governor on $success/$cpu_count CPUs"
    return $([ $success -eq $cpu_count ] && echo 0 || echo 1)
}

# Set CPU frequency limits
set_cpu_freq_limits() {
    local min_freq="$1"
    local max_freq="$2"
    local cpu_count=$(get_cpu_count)
    local success=0

    for i in $(seq 0 $((cpu_count - 1))); do
        if [ "$min_freq" != "auto" ]; then
            safe_write "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq" "$min_freq" "CPU${i} min freq" && success=$((success + 1))
        fi
        if [ "$max_freq" != "auto" ]; then
            safe_write "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq" "$max_freq" "CPU${i} max freq" && success=$((success + 1))
        fi
    done

    log_info "Set frequency limits on $success CPUs (min: $min_freq, max: $max_freq)"
}

# Detect Android version
get_android_version() {
    getprop ro.build.version.sdk
}

# Detect device manufacturer
get_device_manufacturer() {
    local manufacturer=$(getprop ro.product.manufacturer)
    local brand=$(getprop ro.product.brand)
    echo "${manufacturer:-$brand}"
}

# Detect hardware platform
get_hardware_platform() {
    getprop ro.hardware
}

# Detect board platform
get_board_platform() {
    getprop ro.board.platform
}

# Check if file exists and is executable
is_executable() {
    [ -x "$1" ]
}

# Run command with timeout
run_with_timeout() {
    local timeout="$1"
    shift
    timeout "$timeout" "$@" 2>/dev/null
}

# Check if we're in a Magisk environment
is_magisk() {
    [ -n "$MAGISK_VER" ] || [ -d "/data/adb/modules" ] || [ -f "/data/adb/magisk.db" ]
}

# Get Magisk version
get_magisk_version() {
    if [ -n "$MAGISK_VER" ]; then
        echo "$MAGISK_VER"
    elif is_executable "/data/adb/magisk"; then
        /data/adb/magisk -v 2>/dev/null | head -1
    else
        echo "unknown"
    fi
}

# Create backup of current settings
backup_setting() {
    local interface="$1"
    local backup_dir="$POWERBOOST_DIR/backups"
    local name=$(basename "$interface")

    mkdir -p "$backup_dir"
    if [ -r "$interface" ]; then
        cat "$interface" > "$backup_dir/${name}.bak" 2>/dev/null
        log_debug "Backed up $interface to $backup_dir/${name}.bak"
    fi
}

# Restore setting from backup
restore_setting() {
    local interface="$1"
    local backup_dir="$POWERBOOST_DIR/backups"
    local name=$(basename "$interface")

    if [ -f "$backup_dir/${name}.bak" ]; then
        local value=$(cat "$backup_dir/${name}.bak" 2>/dev/null)
        if [ -n "$value" ]; then
            echo "$value" > "$interface" 2>/dev/null
            log_info "Restored $interface from backup: $value"
            return 0
        fi
    fi
    return 1
}

# Check if device supports specific feature
check_feature_support() {
    local feature="$1"

    case "$feature" in
        cpu_freq_scaling)
            [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]
            ;;
        thermal_zones)
            [ -d "/sys/class/thermal" ]
            ;;
        battery_charge_control)
            [ -e "/sys/class/power_supply/battery/charge_control_limit" ] || \
            [ -e "/sys/class/power_supply/battery/charging_enabled" ] || \
            [ -e "/sys/class/power_supply/battery/battery_charging_enabled" ]
            ;;
        display_refresh_rate)
            [ -e "/sys/class/drm/card0/device/display_mode" ] || \
            [ -e "/sys/devices/platform/soc/*.dsi/display_mode" ] || \
            [ -e "/sys/class/graphics/fb0/msm_fb_panel_mode" ]
            ;;
        wifi_power_save)
            is_executable "/system/bin/iw" || is_executable "/system/bin/wpa_cli"
            ;;
        *)
            return 1
            ;;
    esac
}

# Get thermal zones info
get_thermal_zones() {
    if [ -d "/sys/class/thermal" ]; then
        ls /sys/class/thermal/thermal_zone* 2>/dev/null | wc -l
    else
        echo 0
    fi
}

# Get thermal zone temperature
get_thermal_temp() {
    local zone="$1"
    local temp=$(safe_read "/sys/class/thermal/${zone}/temp" "0")
    # Convert from millidegrees to degrees if needed
    if [ "$temp" -gt 1000 ]; then
        echo $((temp / 1000))
    else
        echo "$temp"
    fi
}

# Get cooling devices
get_cooling_devices() {
    if [ -d "/sys/class/thermal" ]; then
        ls /sys/class/thermal/cooling_device* 2>/dev/null | wc -l
    else
        echo 0
    fi
}

# Set cooling device state
set_cooling_state() {
    local device="$1"
    local state="$2"
    safe_write "/sys/class/thermal/${device}/cur_state" "$state" "Cooling device $device"
}

# Check battery status
get_battery_status() {
    local capacity=$(safe_read "/sys/class/power_supply/battery/capacity" "0")
    local status=$(safe_read "/sys/class/power_supply/battery/status" "Unknown")
    local health=$(safe_read "/sys/class/power_supply/battery/health" "Unknown")
    local temp=$(safe_read "/sys/class/power_supply/battery/temp" "0")
    local current=$(safe_read "/sys/class/power_supply/battery/current_now" "0")
    local voltage=$(safe_read "/sys/class/power_supply/battery/voltage_now" "0")

    echo "capacity=$capacity status=$status health=$health temp=$temp current=$current voltage=$voltage"
}

# Check if charging
is_charging() {
    local status=$(safe_read "/sys/class/power_supply/battery/status" "Unknown")
    case "$status" in
        Charging|Full) return 0 ;;
        *) return 1 ;;
    esac
}

# Check screen state
is_screen_on() {
    # Check via dumpsys (requires root) or power supply
    if is_executable "/system/bin/dumpsys"; then
        dumpsys power 2>/dev/null | grep -q "mHoldingDisplaySuspendBlocker=true" && return 0
    fi
    # Fallback: check if any display power is on
    [ -e "/sys/class/backlight" ] && \
    find /sys/class/backlight -name "brightness" -exec sh -c '[ "$(cat {})" -gt 0 ]' \; -quit 2>/dev/null
}

# Get current profile
get_current_profile() {
    local profile_file="$POWERBOOST_DIR/current_profile"
    if [ -f "$profile_file" ]; then
        cat "$profile_file"
    else
        echo "balanced"
    fi
}

# Save current profile
save_current_profile() {
    local profile="$1"
    local profile_file="$POWERBOOST_DIR/current_profile"
    echo "$profile" > "$profile_file"
    log_info "Saved current profile: $profile"
}

# Load profile configuration
load_profile() {
    local profile="$1"
    local profile_dir="$POWERBOOST_DIR/profiles"
    local profile_file="$profile_dir/${profile}.sh"

    if [ -f "$profile_file" ]; then
        # shellcheck disable=SC1090
        . "$profile_file"
        log_info "Loaded profile: $profile"
        return 0
    else
        log_error "Profile not found: $profile"
        return 1
    fi
}

# Apply profile settings
apply_profile() {
    local profile="$1"

    log_info "Applying profile: $profile"

    # Load profile variables
    load_profile "$profile" || return 1

    # Apply CPU settings
    if [ -n "$CPU_GOVERNOR" ]; then
        set_cpu_governor "$CPU_GOVERNOR"
    fi

    if [ -n "$CPU_MIN_FREQ" ] || [ -n "$CPU_MAX_FREQ" ]; then
        set_cpu_freq_limits "${CPU_MIN_FREQ:-auto}" "${CPU_MAX_FREQ:-auto}"
    fi

    # Apply thermal settings
    if [ -n "$THERMAL_POLICY" ]; then
        apply_thermal_policy "$THERMAL_POLICY"
    fi

    # Apply battery settings
    if [ -n "$BATTERY_OPTIMIZATION" ]; then
        apply_battery_optimization "$BATTERY_OPTIMIZATION"
    fi

    # Apply display settings
    if [ -n "$DISPLAY_REFRESH_RATE" ]; then
        set_display_refresh_rate "$DISPLAY_REFRESH_RATE"
    fi

    if [ -n "$DISPLAY_BRIGHTNESS_LIMIT" ]; then
        set_display_brightness_limit "$DISPLAY_BRIGHTNESS_LIMIT"
    fi

    # Apply connectivity settings
    if [ -n "$WIFI_POWER_SAVE" ]; then
        set_wifi_power_save "$WIFI_POWER_SAVE"
    fi

    if [ -n "$MOBILE_DATA_OPTIMIZATION" ]; then
        apply_mobile_data_optimization "$MOBILE_DATA_OPTIMIZATION"
    fi

    # Save as current profile
    save_current_profile "$profile"

    log_info "Profile $profile applied successfully"
    return 0
}

# Placeholder functions for modules to implement
apply_thermal_policy() {
    log_debug "apply_thermal_policy called with: $1"
    return 0
}

apply_battery_optimization() {
    log_debug "apply_battery_optimization called with: $1"
    return 0
}

set_display_refresh_rate() {
    log_debug "set_display_refresh_rate called with: $1"
    return 0
}

set_display_brightness_limit() {
    log_debug "set_display_brightness_limit called with: $1"
    return 0
}

set_wifi_power_save() {
    log_debug "set_wifi_power_save called with: $1"
    return 0
}

apply_mobile_data_optimization() {
    log_debug "apply_mobile_data_optimization called with: $1"
    return 0
}

# Initialize PowerBoost
init_powerboost() {
    log_info "Initializing PowerBoost..."

    # Create necessary directories
    mkdir -p "$POWERBOOST_DIR/backups"
    mkdir -p "$POWERBOOST_DIR/profiles"
    mkdir -p "$POWERBOOST_DIR/logs"

    # Log system info
    log_info "Android SDK: $(get_android_version)"
    log_info "Manufacturer: $(get_device_manufacturer)"
    log_info "Hardware: $(get_hardware_platform)"
    log_info "Board: $(get_board_platform)"
    log_info "Magisk: $(get_magisk_version)"
    log_info "CPU Count: $(get_cpu_count)"
    log_info "Available Governors: $(get_available_governors)"
    log_info "CPU Freq Scaling: $(check_feature_support cpu_freq_scaling && echo "supported" || echo "unsupported")"
    log_info "Thermal Zones: $(get_thermal_zones)"
    log_info "Cooling Devices: $(get_cooling_devices)"
    log_info "Battery Control: $(check_feature_support battery_charge_control && echo "supported" || echo "unsupported")"
    log_info "Display Control: $(check_feature_support display_refresh_rate && echo "supported" || echo "unsupported")"
    log_info "WiFi Power Save: $(check_feature_support wifi_power_save && echo "supported" || echo "unsupported")"

    # Load last used profile or default to balanced
    local profile=$(get_current_profile)
    apply_profile "$profile"
}

# Cleanup on uninstall
cleanup_powerboost() {
    log_info "Cleaning up PowerBoost..."

    # Restore backed up settings
    local backup_dir="$POWERBOOST_DIR/backups"
    if [ -d "$backup_dir" ]; then
        for backup in "$backup_dir"/*.bak; do
            if [ -f "$backup" ]; then
                local name=$(basename "$backup" .bak)
                local interface="/sys/devices/system/cpu/cpu0/cpufreq/$name"
                if [ -e "$interface" ]; then
                    restore_setting "$interface"
                fi
            fi
        done
    fi

    # Reset to default governor if possible
    set_cpu_governor "schedutil" 2>/dev/null || set_cpu_governor "ondemand" 2>/dev/null || set_cpu_governor "performance" 2>/dev/null

    log_info "PowerBoost cleanup complete"
}

# Export functions for use in other scripts
export -f log_info log_warn log_error log_debug
export -f check_root check_interface safe_write safe_read
export -f get_cpu_count get_available_governors get_current_governor
export -f get_cpu_freq_limits set_cpu_governor set_cpu_freq_limits
export -f get_android_version get_device_manufacturer get_hardware_platform get_board_platform
export -f is_executable run_with_timeout is_magisk get_magisk_version
export -f backup_setting restore_setting check_feature_support
export -f get_thermal_zones get_thermal_temp get_cooling_devices set_cooling_state
export -f get_battery_status is_charging is_screen_on
export -f get_current_profile save_current_profile load_profile apply_profile
export -f init_powerboost cleanup_powerboost
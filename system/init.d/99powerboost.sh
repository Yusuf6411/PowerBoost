#!/system/bin/sh
#
# PowerBoost v1.2 - Intelligent Android Optimization Platform
# Main optimization script that applies adaptive profiles based on device capabilities
#

# Source core functions
. /data/adb/modules/powerboost/common/powerboost_functions.sh

# Source optimization modules
. /data/adb/modules/powerboost/common/cpu_optimizer.sh
. /data/adb/modules/powerboost/common/thermal_manager.sh
. /data/adb/modules/powerboost/common/battery_optimizer.sh
. /data/adb/modules/powerboost/common/display_optimizer.sh
. /data/adb/modules/powerboost/common/connectivity_optimizer.sh

# Main optimization function
main() {
    log_info "========================================"
    log_info "PowerBoost v1.2 Starting"
    log_info "========================================"

    # Check root
    check_root || exit 1

    # Initialize PowerBoost
    init_powerboost

    # Run device detection if not already done
    if [ ! -f "$POWERBOOST_DIR/device_profile" ]; then
        log_info "Running device detection..."
        /data/adb/modules/powerboost/common/device_detection.sh
    fi

    # Get current profile (from command line or saved)
    local profile="${1:-$(get_current_profile)}"

    # Validate profile
    local profile_file="$POWERBOOST_DIR/profiles/${profile}.sh"
    if [ ! -f "$profile_file" ]; then
        log_warn "Profile '$profile' not found, falling back to balanced"
        profile="balanced"
    fi

    log_info "Applying profile: $profile"

    # Apply the selected profile
    apply_profile "$profile"

    log_info "========================================"
    log_info "PowerBoost v1.2 Optimization Complete"
    log_info "========================================"
}

# Handle script arguments
case "${1:-}" in
    battery|balanced|performance|gaming|custom)
        main "$1"
        ;;
    detect)
        # Run device detection only
        check_root || exit 1
        /data/adb/modules/powerboost/common/device_detection.sh
        ;;
    monitor)
        # Monitor system status
        check_root || exit 1
        . /data/adb/modules/powerboost/common/device_detection.sh
        log_info "Starting system monitoring..."
        get_cpu_stats
        get_thermal_stats
        get_battery_stats
        get_display_info
        get_connectivity_info
        ;;
    stats)
        # Show current statistics
        check_root || exit 1
        . /data/adb/modules/powerboost/common/device_detection.sh
        get_cpu_stats
        get_thermal_stats
        get_battery_stats
        get_display_info
        get_connectivity_info
        ;;
    cleanup)
        # Cleanup on uninstall
        check_root || exit 1
        cleanup_powerboost
        ;;
    *)
        # Default: apply balanced profile
        main "balanced"
        ;;
esac
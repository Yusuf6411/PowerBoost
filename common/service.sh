#!/system/bin/sh
#
# PowerBoost - Service Script
# Runs as a service to monitor and maintain optimizations
#

# Source core functions
. /data/adb/modules/powerboost/common/powerboost_functions.sh

# Main service loop
main() {
    log_info "PowerBoost service started"

    # Wait for boot to complete
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 5
    done

    log_info "Boot completed, starting optimization service"

    # Run device detection if needed
    if [ ! -f "$POWERBOOST_DIR/device_profile" ]; then
        log_info "Running device detection..."
        /data/adb/modules/powerboost/common/device_detection.sh
    fi

    # Apply current profile
    local profile=$(get_current_profile)
    apply_profile "$profile"

    # Main monitoring loop
    while true; do
        sleep 300  # Check every 5 minutes

        # Check if profile changed
        local current_profile=$(get_current_profile)
        local new_profile="$current_profile"

        # Could add adaptive profile switching logic here
        # For now, just re-apply current profile to maintain settings
        apply_profile "$current_profile"

        # Check thermal status and apply mitigation if needed
        if check_thermal_throttling; then
            log_warn "Thermal throttling detected, applying mitigation"
            apply_thermal_mitigation
        fi

        # Check battery and apply adaptive optimization if enabled
        if [ -f "$POWERBOOST_DIR/adaptive_enabled" ]; then
            apply_adaptive_battery
            apply_adaptive_display
            apply_adaptive_connectivity
        fi
    done
}

# Handle signals
trap 'log_info "PowerBoost service stopping"; exit 0' TERM INT

main
#!/system/bin/sh
#
# PowerBoost - Post-FS-Data Script
# Runs early in boot process to apply critical optimizations
#

# Source core functions
. /data/adb/modules/powerboost/common/powerboost_functions.sh

# Early boot optimizations
main() {
    log_info "PowerBoost post-fs-data: Applying early boot optimizations"

    # Wait for system to be ready
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 1
    done

    # Run device detection
    if [ ! -f "$POWERBOOST_DIR/device_profile" ]; then
        log_info "Running device detection..."
        /data/adb/modules/powerboost/common/device_detection.sh
    fi

    # Apply balanced profile early for critical optimizations
    apply_profile "balanced"

    log_info "PowerBoost post-fs-data: Complete"
}

main
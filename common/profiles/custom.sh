#!/system/bin/sh
#
# PowerBoost Custom Profile Template
# Copy this file and modify to create your own custom profile
#

# Profile name (must match filename without .sh extension)
PROFILE_NAME="custom"

# CPU Settings
# Available governors: powersave, performance, schedutil, ondemand, conservative
# CPU_GOVERNOR="schedutil"
# CPU_MIN_FREQ="auto"  # or specific frequency in KHz (e.g., "800000")
# CPU_MAX_FREQ="auto"  # or specific frequency in KHz (e.g., "2800000")

# Thermal Settings
# Available policies: conservative, balanced, performance, gaming
# THERMAL_POLICY="balanced"

# Battery Settings
# Available optimizations: aggressive, moderate, balanced, performance, gaming
# BATTERY_OPTIMIZATION="balanced"

# Display Settings
# DISPLAY_REFRESH_RATE="60"  # 60, 90, 120, 144 (device dependent)
# DISPLAY_BRIGHTNESS_LIMIT="100"  # percentage of max brightness

# Connectivity Settings
# Available WiFi power save: aggressive, moderate, balanced, performance
# WIFI_POWER_SAVE="balanced"
# Available mobile data optimization: aggressive, moderate, balanced, performance, gaming
# MOBILE_DATA_OPTIMIZATION="balanced"

# Export all variables (uncomment the ones you want to customize)
# export PROFILE_NAME CPU_GOVERNOR CPU_MIN_FREQ CPU_MAX_FREQ
# export THERMAL_POLICY BATTERY_OPTIMIZATION
# export DISPLAY_REFRESH_RATE DISPLAY_BRIGHTNESS_LIMIT
# export WIFI_POWER_SAVE MOBILE_DATA_OPTIMIZATION

# Note: Only uncomment and set the variables you want to override.
# Unset variables will use the default balanced profile values.
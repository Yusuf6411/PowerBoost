#!/system/bin/sh
#
# PowerBoost Gaming Profile
# Optimized for gaming - performance with thermal management
#

# Profile name
PROFILE_NAME="gaming"

# CPU Settings
CPU_GOVERNOR="performance"
CPU_MIN_FREQ="auto"
CPU_MAX_FREQ="auto"

# Thermal Settings
THERMAL_POLICY="gaming"

# Battery Settings
BATTERY_OPTIMIZATION="gaming"

# Display Settings
DISPLAY_REFRESH_RATE="120"
DISPLAY_BRIGHTNESS_LIMIT="150"

# Connectivity Settings
WIFI_POWER_SAVE="performance"
MOBILE_DATA_OPTIMIZATION="gaming"

# Export all variables
export PROFILE_NAME CPU_GOVERNOR CPU_MIN_FREQ CPU_MAX_FREQ
export THERMAL_POLICY BATTERY_OPTIMIZATION
export DISPLAY_REFRESH_RATE DISPLAY_BRIGHTNESS_LIMIT
export WIFI_POWER_SAVE MOBILE_DATA_OPTIMIZATION
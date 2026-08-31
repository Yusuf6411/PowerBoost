#!/system/bin/sh
#
# PowerBoost Performance Profile
# Maximum performance with reasonable thermal limits
#

# Profile name
PROFILE_NAME="performance"

# CPU Settings
CPU_GOVERNOR="performance"
CPU_MIN_FREQ="auto"
CPU_MAX_FREQ="auto"

# Thermal Settings
THERMAL_POLICY="performance"

# Battery Settings
BATTERY_OPTIMIZATION="performance"

# Display Settings
DISPLAY_REFRESH_RATE="90"
DISPLAY_BRIGHTNESS_LIMIT="120"

# Connectivity Settings
WIFI_POWER_SAVE="performance"
MOBILE_DATA_OPTIMIZATION="performance"

# Export all variables
export PROFILE_NAME CPU_GOVERNOR CPU_MIN_FREQ CPU_MAX_FREQ
export THERMAL_POLICY BATTERY_OPTIMIZATION
export DISPLAY_REFRESH_RATE DISPLAY_BRIGHTNESS_LIMIT
export WIFI_POWER_SAVE MOBILE_DATA_OPTIMIZATION
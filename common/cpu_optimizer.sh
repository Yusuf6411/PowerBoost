#!/system/bin/sh
#
# PowerBoost CPU Optimizer
# Handles CPU frequency scaling, governor management, and scheduler tuning
#

# Source common functions
. /data/adb/modules/powerboost/common/powerboost_functions.sh

# CPU optimization settings per profile
# These will be overridden by profile configurations

# Apply CPU governor
apply_cpu_governor() {
    local governor="$1"
    log_info "Applying CPU governor: $governor"

    local available_governors=$(get_available_governors 0)
    if echo "$available_governors" | grep -qw "$governor"; then
        set_cpu_governor "$governor"
    else
        log_warn "Governor $governor not available. Available: $available_governors"
        return 1
    fi
}

# Apply CPU frequency limits
apply_cpu_frequency_limits() {
    local min_freq="$1"
    local max_freq="$2"

    log_info "Applying CPU frequency limits: min=$min_freq, max=$max_freq"

    if [ "$min_freq" != "auto" ] && [ "$max_freq" != "auto" ]; then
        set_cpu_freq_limits "$min_freq" "$max_freq"
    elif [ "$min_freq" != "auto" ]; then
        local cpu_count=$(get_cpu_count)
        for i in $(seq 0 $((cpu_count - 1))); do
            safe_write "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq" "$min_freq" "CPU${i} min freq"
        done
    elif [ "$max_freq" != "auto" ]; then
        local cpu_count=$(get_cpu_count)
        for i in $(seq 0 $((cpu_count - 1))); do
            safe_write "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq" "$max_freq" "CPU${i} max freq"
        done
    fi
}

# Apply EAS (Energy Aware Scheduling) settings if available
apply_eas_settings() {
    local profile="$1"

    # Check if EAS is available
    if [ ! -e "/sys/devices/system/cpu/cpu0/cpufreq/energy_aware_scheduling" ]; then
        log_debug "EAS not available on this device"
        return 0
    fi

    case "$profile" in
        battery)
            safe_write "/sys/devices/system/cpu/cpu0/cpufreq/energy_aware_scheduling" "1" "EAS enable"
            ;;
        performance)
            safe_write "/sys/devices/system/cpu/cpu0/cpufreq/energy_aware_scheduling" "0" "EAS disable"
            ;;
        balanced)
            safe_write "/sys/devices/system/cpu/cpu0/cpufreq/energy_aware_scheduling" "1" "EAS enable"
            ;;
        gaming)
            safe_write "/sys/devices/system/cpu/cpu0/cpufreq/energy_aware_scheduling" "0" "EAS disable"
            ;;
    esac
}

# Apply scheduler settings
apply_scheduler_settings() {
    local profile="$1"

    # Schedutil tunables
    if [ -e "/sys/devices/system/cpu/cpu0/cpufreq/schedutil" ]; then
        case "$profile" in
            battery)
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us" "2000" "schedutil up_rate_limit"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us" "10000" "schedutil down_rate_limit"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/iowait_boost_enable" "0" "schedutil iowait_boost"
                ;;
            performance)
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us" "500" "schedutil up_rate_limit"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us" "2000" "schedutil down_rate_limit"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/iowait_boost_enable" "1" "schedutil iowait_boost"
                ;;
            balanced)
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us" "1000" "schedutil up_rate_limit"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us" "5000" "schedutil down_rate_limit"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/iowait_boost_enable" "1" "schedutil iowait_boost"
                ;;
            gaming)
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us" "500" "schedutil up_rate_limit"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us" "5000" "schedutil down_rate_limit"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/schedutil/iowait_boost_enable" "1" "schedutil iowait_boost"
                ;;
        esac
    fi

    # Ondemand tunables
    if [ -e "/sys/devices/system/cpu/cpu0/cpufreq/ondemand" ]; then
        case "$profile" in
            battery)
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_rate" "80000" "ondemand sampling_rate"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold" "95" "ondemand up_threshold"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/down_differential" "10" "ondemand down_differential"
                ;;
            performance)
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_rate" "20000" "ondemand sampling_rate"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold" "80" "ondemand up_threshold"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/down_differential" "5" "ondemand down_differential"
                ;;
            balanced)
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_rate" "40000" "ondemand sampling_rate"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold" "85" "ondemand up_threshold"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/down_differential" "8" "ondemand down_differential"
                ;;
            gaming)
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_rate" "20000" "ondemand sampling_rate"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold" "75" "ondemand up_threshold"
                safe_write "/sys/devices/system/cpu/cpu0/cpufreq/ondemand/down_differential" "5" "ondemand down_differential"
                ;;
        esac
    fi
}

# Apply CPU idle settings
apply_cpu_idle_settings() {
    local profile="$1"

    # Check if cpuidle is available
    if [ ! -d "/sys/devices/system/cpu/cpu0/cpuidle" ]; then
        log_debug "CPU idle not available"
        return 0
    fi

    case "$profile" in
        battery)
            # Enable deeper idle states
            for state in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
                local state_num=$(dirname "$state" | grep -o 'state[0-9]*' | sed 's/state//')
                if [ "$state_num" -ge 2 ] 2>/dev/null; then
                    safe_write "$state" "0" "CPU idle state $state_num enable"
                else
                    safe_write "$state" "1" "CPU idle state $state_num disable"
                fi
            done
            ;;
        performance)
            # Disable deeper idle states for lower latency
            for state in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
                local state_num=$(dirname "$state" | grep -o 'state[0-9]*' | sed 's/state//')
                if [ "$state_num" -ge 2 ] 2>/dev/null; then
                    safe_write "$state" "1" "CPU idle state $state_num disable"
                else
                    safe_write "$state" "0" "CPU idle state $state_num enable"
                fi
            done
            ;;
        balanced|gaming)
            # Balanced approach
            for state in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
                local state_num=$(dirname "$state" | grep -o 'state[0-9]*' | sed 's/state//')
                if [ "$state_num" -ge 3 ] 2>/dev/null; then
                    safe_write "$state" "1" "CPU idle state $state_num disable"
                else
                    safe_write "$state" "0" "CPU idle state $state_num enable"
                fi
            done
            ;;
    esac
}

# Apply core parking settings (if supported)
apply_core_parking() {
    local profile="$1"

    # Check for core control
    if [ ! -e "/sys/devices/system/cpu/cpu0/core_ctl/enable" ] && [ ! -e "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus" ]; then
        log_debug "Core control not available"
        return 0
    fi

    local cpu_count=$(get_cpu_count)

    case "$profile" in
        battery)
            # Allow fewer cores online
            if [ -e "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus" ]; then
                safe_write "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus" "1" "core_ctl min_cpus"
            fi
            if [ -e "/sys/devices/system/cpu/cpu0/core_ctl/max_cpus" ]; then
                safe_write "/sys/devices/system/cpu/cpu0/core_ctl/max_cpus" "$((cpu_count / 2))" "core_ctl max_cpus"
            fi
            ;;
        performance)
            # Keep all cores available
            if [ -e "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus" ]; then
                safe_write "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus" "$cpu_count" "core_ctl min_cpus"
            fi
            if [ -e "/sys/devices/system/cpu/cpu0/core_ctl/max_cpus" ]; then
                safe_write "/sys/devices/system/cpu/cpu0/core_ctl/max_cpus" "$cpu_count" "core_ctl max_cpus"
            fi
            ;;
        balanced)
            if [ -e "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus" ]; then
                safe_write "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus" "2" "core_ctl min_cpus"
            fi
            if [ -e "/sys/devices/system/cpu/cpu0/core_ctl/max_cpus" ]; then
                safe_write "/sys/devices/system/cpu/cpu0/core_ctl/max_cpus" "$cpu_count" "core_ctl max_cpus"
            fi
            ;;
        gaming)
            if [ -e "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus" ]; then
                safe_write "/sys/devices/system/cpu/cpu0/core_ctl/min_cpus" "$((cpu_count - 1))" "core_ctl min_cpus"
            fi
            if [ -e "/sys/devices/system/cpu/cpu0/core_ctl/max_cpus" ]; then
                safe_write "/sys/devices/system/cpu/cpu0/core_ctl/max_cpus" "$cpu_count" "core_ctl max_cpus"
            fi
            ;;
    esac
}

# Apply CPU boost settings
apply_cpu_boost() {
    local profile="$1"

    # Check for input boost
    if [ -e "/sys/module/cpu_boost/parameters/input_boost_enabled" ]; then
        case "$profile" in
            battery)
                safe_write "/sys/module/cpu_boost/parameters/input_boost_enabled" "0" "input_boost disable"
                ;;
            performance|gaming)
                safe_write "/sys/module/cpu_boost/parameters/input_boost_enabled" "1" "input_boost enable"
                ;;
            balanced)
                safe_write "/sys/module/cpu_boost/parameters/input_boost_enabled" "1" "input_boost enable"
                ;;
        esac
    fi

    # Check for sched boost
    if [ -e "/proc/sys/kernel/sched_boost" ]; then
        case "$profile" in
            battery)
                safe_write "/proc/sys/kernel/sched_boost" "0" "sched_boost disable"
                ;;
            performance|gaming)
                safe_write "/proc/sys/kernel/sched_boost" "1" "sched_boost enable"
                ;;
            balanced)
                safe_write "/proc/sys/kernel/sched_boost" "1" "sched_boost enable"
                ;;
        esac
    fi
}

# Apply scheduler features
apply_scheduler_features() {
    local profile="$1"

    # Scheduler features
    if [ -e "/sys/kernel/debug/sched/features" ]; then
        case "$profile" in
            battery)
                safe_write "/sys/kernel/debug/sched/features" "NO_HRTICK" "sched disable HRTICK"
                safe_write "/sys/kernel/debug/sched/features" "NO_SCHED_HRTICK" "sched disable SCHED_HRTICK"
                ;;
            performance|gaming)
                safe_write "/sys/kernel/debug/sched/features" "HRTICK" "sched enable HRTICK"
                safe_write "/sys/kernel/debug/sched/features" "SCHED_HRTICK" "sched enable SCHED_HRTICK"
                ;;
        esac
    fi

    # Scheduler migration cost
    if [ -e "/proc/sys/kernel/sched_migration_cost_ns" ]; then
        case "$profile" in
            battery)
                safe_write "/proc/sys/kernel/sched_migration_cost_ns" "10000000" "sched_migration_cost_ns"
                ;;
            performance|gaming)
                safe_write "/proc/sys/kernel/sched_migration_cost_ns" "500000" "sched_migration_cost_ns"
                ;;
            balanced)
                safe_write "/proc/sys/kernel/sched_migration_cost_ns" "3000000" "sched_migration_cost_ns"
                ;;
        esac
    fi

    # Scheduler latency
    if [ -e "/proc/sys/kernel/sched_latency_ns" ]; then
        case "$profile" in
            battery)
                safe_write "/proc/sys/kernel/sched_latency_ns" "24000000" "sched_latency_ns"
                ;;
            performance|gaming)
                safe_write "/proc/sys/kernel/sched_latency_ns" "12000000" "sched_latency_ns"
                ;;
            balanced)
                safe_write "/proc/sys/kernel/sched_latency_ns" "18000000" "sched_latency_ns"
                ;;
        esac
    fi

    # Scheduler min granularity
    if [ -e "/proc/sys/kernel/sched_min_granularity_ns" ]; then
        case "$profile" in
            battery)
                safe_write "/proc/sys/kernel/sched_min_granularity_ns" "4000000" "sched_min_granularity_ns"
                ;;
            performance|gaming)
                safe_write "/proc/sys/kernel/sched_min_granularity_ns" "1000000" "sched_min_granularity_ns"
                ;;
            balanced)
                safe_write "/proc/sys/kernel/sched_min_granularity_ns" "2000000" "sched_min_granularity_ns"
                ;;
        esac
    fi
}

# Apply wakeup boost settings
apply_wakeup_boost() {
    local profile="$1"

    if [ -e "/proc/sys/kernel/sched_wakeup_granularity_ns" ]; then
        case "$profile" in
            battery)
                safe_write "/proc/sys/kernel/sched_wakeup_granularity_ns" "4000000" "sched_wakeup_granularity_ns"
                ;;
            performance|gaming)
                safe_write "/proc/sys/kernel/sched_wakeup_granularity_ns" "1000000" "sched_wakeup_granularity_ns"
                ;;
            balanced)
                safe_write "/proc/sys/kernel/sched_wakeup_granularity_ns" "2000000" "sched_wakeup_granularity_ns"
                ;;
        esac
    fi
}

# Main CPU optimization function
optimize_cpu() {
    local profile="$1"

    log_info "Optimizing CPU for profile: $profile"

    # Get profile-specific settings
    load_profile "$profile" || return 1

    # Apply governor
    if [ -n "$CPU_GOVERNOR" ]; then
        apply_cpu_governor "$CPU_GOVERNOR"
    fi

    # Apply frequency limits
    if [ -n "$CPU_MIN_FREQ" ] || [ -n "$CPU_MAX_FREQ" ]; then
        apply_cpu_frequency_limits "${CPU_MIN_FREQ:-auto}" "${CPU_MAX_FREQ:-auto}"
    fi

    # Apply EAS settings
    apply_eas_settings "$profile"

    # Apply scheduler settings
    apply_scheduler_settings "$profile"

    # Apply CPU idle settings
    apply_cpu_idle_settings "$profile"

    # Apply core parking
    apply_core_parking "$profile"

    # Apply CPU boost
    apply_cpu_boost "$profile"

    # Apply scheduler features
    apply_scheduler_features "$profile"

    # Apply wakeup boost
    apply_wakeup_boost "$profile"

    log_info "CPU optimization complete for profile: $profile"
}

# Monitor CPU status
monitor_cpu() {
    local interval="${1:-5}"
    local duration="${2:-60}"
    local end_time=$(($(date +%s) + duration))

    log_info "Monitoring CPU for ${duration}s (interval: ${interval}s)"

    while [ $(date +%s) -lt $end_time ]; do
        local cpu_count=$(get_cpu_count)

        for i in $(seq 0 $((cpu_count - 1))); do
            local governor=$(get_current_governor "$i")
            local freq=$(safe_read "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_cur_freq" "0")
            local min_freq=$(safe_read "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq" "0")
            local max_freq=$(safe_read "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq" "0")

            log_debug "CPU$i: governor=$governor freq=${freq}KHz min=${min_freq}KHz max=${max_freq}KHz"
        done

        sleep "$interval"
    done
}

# Get CPU statistics
get_cpu_stats() {
    local cpu_count=$(get_cpu_count)

    echo "=== CPU Statistics ==="
    echo "CPU Count: $cpu_count"
    echo ""

    for i in $(seq 0 $((cpu_count - 1))); do
        echo "CPU $i:"
        echo "  Governor: $(get_current_governor "$i")"
        echo "  Available Governors: $(get_available_governors "$i")"
        echo "  Current Freq: $(safe_read "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_cur_freq" "N/A") KHz"
        echo "  Min Freq: $(safe_read "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq" "N/A") KHz"
        echo "  Max Freq: $(safe_read "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq" "N/A") KHz"
        echo ""
    done

    # Check for additional info
    if [ -e "/sys/devices/system/cpu/cpu0/cpufreq/energy_aware_scheduling" ]; then
        echo "EAS: $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_aware_scheduling)"
    fi

    if [ -e "/sys/devices/system/cpu/cpu0/core_ctl/enable" ]; then
        echo "Core Control: $(cat /sys/devices/system/cpu/cpu0/core_ctl/enable)"
        echo "Min CPUs: $(cat /sys/devices/system/cpu/cpu0/core_ctl/min_cpus)"
        echo "Max CPUs: $(cat /sys/devices/system/cpu/cpu0/core_ctl/max_cpus)"
    fi
}

# Export functions
export -f apply_cpu_governor apply_cpu_frequency_limits apply_eas_settings
export -f apply_scheduler_settings apply_cpu_idle_settings apply_core_parking
export -f apply_cpu_boost apply_scheduler_features apply_wakeup_boost
export -f optimize_cpu monitor_cpu get_cpu_stats
#! /vendor/bin/sh

# Copyright (c) 2012-2013, 2016-2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Cleaned up for MSM8953 (Snapdragon 625) with uclamp + schedutil
# Removed: all non-8953 SoC code, HMP scheduler settings, interactive governor,
#          input_boost (let powerhal handle boosts), hispeed_freq/hispeed_load

target=`getprop ro.board.platform`

function configure_read_ahead_kb_values() {
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    dmpts=$(ls /sys/block/*/queue/read_ahead_kb | grep -e dm -e mmc)

    # Set 128 for <= 3GB &
    # set 512 for >= 4GB targets.
    if [ $MemTotal -le 3145728 ]; then
        echo 128 > /sys/block/mmcblk0/bdi/read_ahead_kb
        echo 128 > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
        for dm in $dmpts; do
            echo 128 > $dm
        done
    else
        echo 512 > /sys/block/mmcblk0/bdi/read_ahead_kb
        echo 512 > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
        for dm in $dmpts; do
            echo 512 > $dm
        done
    fi
}

function configure_memory_parameters() {
    arch_type=`uname -m`
    low_ram=`getprop ro.config.low_ram`

    if [ "$low_ram" == "true" ]; then
        echo 0 > /sys/module/lowmemorykiller/parameters/enable_lmk
        echo 0 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
        echo 0 > /sys/module/process_reclaim/parameters/enable_process_reclaim
        if [ -f /proc/sys/vm/reap_mem_on_sigkill ]; then
            echo 1 > /proc/sys/vm/reap_mem_on_sigkill
        fi
    else
        adj_series=`cat /sys/module/lowmemorykiller/parameters/adj`
        adj_1="${adj_series#*,}"
        set_almk_ppr_adj="${adj_1%%,*}"
        set_almk_ppr_adj=$(((set_almk_ppr_adj * 6) + 6))
        echo $set_almk_ppr_adj > /sys/module/lowmemorykiller/parameters/adj_max_shift

        if [ "$arch_type" == "aarch64" ]; then
            minfree_series=`cat /sys/module/lowmemorykiller/parameters/minfree`
            minfree_1="${minfree_series#*,}" ; rem_minfree_1="${minfree_1%%,*}"
            minfree_2="${minfree_1#*,}" ; rem_minfree_2="${minfree_2%%,*}"
            minfree_3="${minfree_2#*,}" ; rem_minfree_3="${minfree_3%%,*}"
            minfree_4="${minfree_3#*,}" ; rem_minfree_4="${minfree_4%%,*}"
            minfree_5="${minfree_4#*,}"
            vmpres_file_min=$((minfree_5 + (minfree_5 - rem_minfree_4)))
            echo $vmpres_file_min > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
        else
            echo "15360,19200,23040,26880,34415,43737" > /sys/module/lowmemorykiller/parameters/minfree
            echo 53059 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
        fi

        echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk

        if [ -f /sys/module/lowmemorykiller/parameters/oom_reaper ]; then
            echo 1 > /sys/module/lowmemorykiller/parameters/oom_reaper
        fi

        # PPR settings
        echo $set_almk_ppr_adj > /sys/module/process_reclaim/parameters/min_score_adj
        echo 1 > /sys/module/process_reclaim/parameters/enable_process_reclaim
        echo 50 > /sys/module/process_reclaim/parameters/pressure_min
        echo 70 > /sys/module/process_reclaim/parameters/pressure_max
        echo 30 > /sys/module/process_reclaim/parameters/swap_opt_eff
        echo 512 > /sys/module/process_reclaim/parameters/per_swap_size
    fi

    echo 0 > /sys/module/vmpressure/parameters/allocstall_threshold
    echo 1 > /proc/sys/vm/watermark_scale_factor
    configure_read_ahead_kb_values
}

case "$target" in
    "msm8953")

        # Disable sched_boost
        echo 0 > /proc/sys/kernel/sched_boost

        # Setup cpubw (memory bandwidth) governor
        for devfreq_gov in /sys/class/devfreq/qcom,mincpubw*/governor
        do
            echo "cpufreq" > $devfreq_gov
        done

        for devfreq_gov in /sys/class/devfreq/soc:qcom,cpubw/governor
        do
            echo "bw_hwmon" > $devfreq_gov
            for cpu_io_percent in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/io_percent
            do
                echo 34 > $cpu_io_percent
            done
            for cpu_guard_band in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/guard_band_mbps
            do
                echo 0 > $cpu_guard_band
            done
            for cpu_hist_memory in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/hist_memory
            do
                echo 20 > $cpu_hist_memory
            done
            for cpu_hyst_length in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/hyst_length
            do
                echo 10 > $cpu_hyst_length
            done
            for cpu_idle_mbps in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/idle_mbps
            do
                echo 1600 > $cpu_idle_mbps
            done
            for cpu_low_power_delay in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/low_power_delay
            do
                echo 20 > $cpu_low_power_delay
            done
            for cpu_low_power_io_percent in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/low_power_io_percent
            do
                echo 34 > $cpu_low_power_io_percent
            done
            for cpu_mbps_zones in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/mbps_zones
            do
                echo "1611 3221 5859 6445 7104" > $cpu_mbps_zones
            done
            for cpu_sample_ms in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/sample_ms
            do
                echo 4 > $cpu_sample_ms
            done
            for cpu_up_scale in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/up_scale
            do
                echo 250 > $cpu_up_scale
            done
            for cpu_min_freq in /sys/class/devfreq/soc:qcom,cpubw/min_freq
            do
                echo 1611 > $cpu_min_freq
            done
        done

        for gpu_bimc_io_percent in /sys/class/devfreq/soc:qcom,gpubw/bw_hwmon/io_percent
        do
            echo 40 > $gpu_bimc_io_percent
        done

        # Set schedutil governor
        echo 1 > /sys/devices/system/cpu/cpu0/online
        echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo 500 > /sys/devices/system/cpu/cpufreq/schedutil/up_rate_limit_us
        echo 20000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us

        # Bring up all cores online
        echo 1 > /sys/devices/system/cpu/cpu1/online
        echo 1 > /sys/devices/system/cpu/cpu2/online
        echo 1 > /sys/devices/system/cpu/cpu3/online
        echo 1 > /sys/devices/system/cpu/cpu4/online
        echo 1 > /sys/devices/system/cpu/cpu5/online
        echo 1 > /sys/devices/system/cpu/cpu6/online
        echo 1 > /sys/devices/system/cpu/cpu7/online

        # Enable low power modes
        echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled

        # Set Memory parameters
        configure_memory_parameters

        setprop vendor.post_boot.parsed 1
    ;;
esac

if [ -f /sys/devices/soc0/select_image ]; then
    image_version="10:"
    image_version+=`getprop ro.build.id`
    image_version+=":"
    image_version+=`getprop ro.build.version.incremental`
    image_variant=`getprop ro.product.name`
    image_variant+="-"
    image_variant+=`getprop ro.build.type`
    oem_version=`getprop ro.build.version.codename`
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
fi

# Change console log level as per console config property
console_config=`getprop persist.vendor.console.silent.config`
case "$console_config" in
    "1")
        echo 0 > /proc/sys/kernel/printk
        ;;
esac

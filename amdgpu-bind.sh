#!/usr/bin/env bash
set -euo pipefail

ERROR_PATTERN="hw_init of IP block <smu> failed -62"
GPU_PCI_ADDRESS="${GPU_PCI_ADDRESS:-0000:03:00.0}"
GPU_DEVICE_PATH="/sys/bus/pci/devices/${GPU_PCI_ADDRESS}"
GPU_DRM_PATH="${GPU_DEVICE_PATH}/drm"
MODE="${1:-boot-watch}"

trigger_bind() {
    local initial_delay="${1:-2}"

    sleep "${initial_delay}"

    for i in {1..3}; do
        echo "Attempt ${i}: Resetting GPU..."
        echo "${GPU_PCI_ADDRESS}" > /sys/bus/pci/drivers/amdgpu/unbind 2>/dev/null || true
        sleep 2
        echo "${GPU_PCI_ADDRESS}" > /sys/bus/pci/drivers/amdgpu/bind
        sleep 10

        if [ -d "${GPU_DRM_PATH}" ]; then
            echo "GPU bind successful."
            exit 0
        fi

        echo "Bind failed. Retrying..."
        sleep 3
    done

    echo "GPU failed to bind after 3 attempts."
    exit 1
}

watch_boot_errors() {
    if dmesg | grep -q "${ERROR_PATTERN}"; then
        echo "amdgpu-bind detected failed smu"
        trigger_bind
    fi

    set +e
    timeout 90 dmesg -w | while read -r line; do
        if echo "${line}" | grep -q "${ERROR_PATTERN}"; then
            echo "Error occured while amdgpu-bind was following new kernel messages"
            trigger_bind
        fi
    done
    local watcher_status=$?
    set -e

    if [[ ${watcher_status} -ne 0 && ${watcher_status} -ne 124 ]]; then
        echo "Kernel log watch failed with status ${watcher_status}."
        exit "${watcher_status}"
    fi

    if [ -d "${GPU_DRM_PATH}" ]; then
        echo "GPU initialization successful."
        exit 0
    fi

    echo "Error pattern was not found but GPU did not initialize. Different error?"
    trigger_bind
}

resume_rebind() {
    echo "Running AMDGPU resume recovery for ${GPU_PCI_ADDRESS}"
    trigger_bind 1
}

case "${MODE}" in
    boot-watch)
        watch_boot_errors
        ;;
    resume)
        resume_rebind
        ;;
    *)
        echo "Unknown mode: ${MODE}" >&2
        exit 2
        ;;
esac

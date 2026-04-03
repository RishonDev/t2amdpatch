#!/usr/bin/env bash

ERROR_PATTERN="hw_init of IP block <smu> failed -62"

trigger_bind() {

    # Give it a couple seconds
    sleep 2

    # Attempt up to 3 times to bind the driver
    for i in {1..3}; do

        echo "Attempt $i: Resetting GPU..."
        # Make sure it's not already bound
        echo "0000:03:00.0" > /sys/bus/pci/drivers/amdgpu/unbind 2>/dev/null
        sleep 2

        # Bind
        echo "0000:03:00.0" > /sys/bus/pci/drivers/amdgpu/bind

        # Wait for bind to happen
        sleep 10

        # Check if the driver took hold
        if [ -d "/sys/bus/pci/devices/0000:03:00.0/drm" ]; then
            echo "GPU bind successful."
            exit 0
        fi

        # Retry if bind failed
        echo "Bind failed. Retrying..."
        sleep 3
    done

    # Give up after 3 failed attempts
    echo "GPU failed to bind after 3 attempts."
    exit 1
}

# Check the log so far to see if <smu> error happened before this script started
if dmesg | grep -q "$ERROR_PATTERN"; then
    echo "amdgpu-bind detected failed smu"
    trigger_bind
fi

# Then follow new log messages for 90 s to see if <smu> error happens after this script started
timeout 90 dmesg -w | while read -r line; do
    if echo "$line" | grep -q "$ERROR_PATTERN"; then
        echo "Error occured while amdgpu-bind was following new kernel messages"
        trigger_bind
    fi
done

# If still no error check if it's safe to exit
if [ -d "/sys/bus/pci/devices/0000:03:00.0/drm" ]; then
    echo "GPU initialization successful."
    exit 0
else
    echo "Error pattern was not found but GPU did not initialize. Different error?"
    trigger_bind
fi
exit 1

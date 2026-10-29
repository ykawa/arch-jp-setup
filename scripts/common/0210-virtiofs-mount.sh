#!/bin/bash
# This script detects VirtioFS tags and mounts them automatically
set -e

echo "================================"
echo "  VirtioFS Mount Setup Script"
echo "  For Libvirt Guest Systems"
echo "================================"
echo ""

# Check if running in a libvirt guest
echo "Step 1: Checking if running in libvirt guest environment..."

# Check for VirtioFS filesystem
if [ ! -d "/sys/fs/virtiofs" ]; then
    echo "VirtioFS not available, skipping VirtioFS setup"
    exit 0
fi

# Look for VirtioFS filesystems by checking /sys/fs/virtiofs/*/tag
virtiofs_tags=()
if [ -d "/sys/fs/virtiofs" ]; then
    for fs_dir in /sys/fs/virtiofs/*; do
        if [ -d "$fs_dir" ] && [ -f "$fs_dir/tag" ]; then
            tag=$(cat "$fs_dir/tag")
            if [ -n "$tag" ]; then
                virtiofs_tags+=("$tag")
            fi
        fi
    done
fi

if [ ${#virtiofs_tags[@]} -eq 0 ]; then
    echo "No VirtioFS tags found, exiting"
    exit 0
fi

echo "Found ${#virtiofs_tags[@]} VirtioFS tag(s): ${virtiofs_tags[*]}"

echo ""
echo "Step 2: Processing VirtioFS tags..."

# Backup fstab
if [ ! -f "/etc/fstab.backup" ]; then
    echo "Backing up /etc/fstab..."
    sudo cp /etc/fstab /etc/fstab.backup
fi

mounted_tags=()

for tag in "${virtiofs_tags[@]}"; do
    echo "Processing VirtioFS tag: $tag"

    mount_point="/mnt/$tag"

    # Create mount point if it doesn't exist
    if [ ! -d "$mount_point" ]; then
        echo "Creating mount point: $mount_point"
        sudo mkdir -p "$mount_point"
    fi

    # Check if already in fstab
    if grep -q "^$tag " /etc/fstab; then
        echo "$tag already configured in /etc/fstab"
    else
        echo "Adding $tag to /etc/fstab..."
        echo "$tag $mount_point virtiofs defaults 0 0" | sudo tee -a /etc/fstab
        echo "Added $tag to /etc/fstab"
    fi

    # Try to mount immediately
    if mountpoint -q "$mount_point"; then
        echo "$mount_point already mounted"
    else
        echo "Mounting $tag to $mount_point..."
        if sudo mount "$mount_point" 2>/dev/null; then
            echo "Successfully mounted $tag"
        else
            echo "⚠ Failed to mount $tag (will mount on next boot)"
        fi
    fi

    mounted_tags+=("$tag")
done

echo ""
echo "Step 3: Setting up permissions..."

# Set appropriate permissions for mounted directories
for tag in "${mounted_tags[@]}"; do
    mount_point="/mnt/$tag"
    if mountpoint -q "$mount_point"; then
        echo "Setting permissions for $mount_point..."
        # Make the mount point accessible to the current user
        sudo chown "$USER:$USER" "$mount_point" 2>/dev/null || echo "Note: Could not change ownership of $mount_point"
        sudo chmod 755 "$mount_point" 2>/dev/null || echo "Note: Could not change permissions of $mount_point"
    fi
done

echo ""
echo "VirtioFS setup completed successfully!"
echo ""

if [ ${#mounted_tags[@]} -gt 0 ]; then
    echo "Configured VirtioFS mounts:"
    for tag in "${mounted_tags[@]}"; do
        mount_point="/mnt/$tag"
        if mountpoint -q "$mount_point"; then
            echo "$tag -> $mount_point (mounted)"
        else
            echo "$tag -> $mount_point (will mount on boot)"
        fi
    done
    echo ""
    echo "IMPORTANT:"
    echo "- VirtioFS mounts are now configured in /etc/fstab"
    echo "- Mounts will be available after reboot if not mounted now"
    echo "- Mount points are created under /mnt/"
else
    echo "No VirtioFS tags were processed"
fi

echo "================================"

#!/bin/bash

# Cari partisi sda terbesar
largest_partition=$(lsblk -nr -o NAME,SIZE | grep '^sda[0-9]' | sort -k2 -rh | head -n 1 | awk '{print $1}')

if [ -z "$largest_partition" ]; then
  echo "Tidak ada partisi sda yang ditemukan."
  exit 1
fi

# Unmount partisi jika ter-mount
mount_point=$(mount | grep "/dev/$largest_partition" | awk '{print $3}')
if [ -n "$mount_point" ]; then
  echo "Unmounting /dev/$largest_partition from $mount_point"
  sudo umount "/dev/$largest_partition"
fi

# Format partisi dengan NTFS quick format dan beri label "external"
echo "Formatting /dev/$largest_partition with NTFS and labeling it 'external'"
sudo mkfs.ntfs -Q -L external "/dev/$largest_partition"

# Verifikasi
echo "Verifying the format"
sudo blkid "/dev/$largest_partition"

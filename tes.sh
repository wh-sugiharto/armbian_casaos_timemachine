#!/bin/bash

# Menampilkan storage yang ada
echo "Menampilkan storage yang ada:"
lsblk
echo

# Meminta input dari pengguna untuk partisi yang akan diunmount dan diformat
read -p "Masukkan partisi yang ingin di-unmount dan diformat (contoh: sda2): " PARTITION
PARTITION="/dev/$PARTITION"

# Memeriksa apakah partisi ter-mount
MOUNT_POINT=$(mount | grep "$PARTITION" | awk '{print $3}')

if [ -z "$MOUNT_POINT" ]; then
  echo "Partisi $PARTITION tidak ter-mount."
else
  # Unmount partisi
  echo "Unmounting $PARTITION dari $MOUNT_POINT"
  sudo umount "$PARTITION"
  if [ $? -ne 0 ]; then
    echo "Gagal unmount $PARTITION."
    exit 1
  fi
fi

# Format partisi dengan NTFS dan label "external" menggunakan quick format
echo "Memformat $PARTITION dengan NTFS dan label 'external' menggunakan quick format."
sudo mkfs.ntfs -Q -L external "$PARTITION"
if [ $? -ne 0 ]; then
    echo "Gagal memformat $PARTITION."
    exit 1
fi

# Verifikasi hasil format
echo "Verifikasi hasil format:"
sudo blkid "$PARTITION"
echo

echo "Proses selesai."

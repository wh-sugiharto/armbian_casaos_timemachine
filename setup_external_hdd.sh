#!/bin/bash

# Fungsi untuk menemukan perangkat penyimpanan baru
find_new_drive() {
    for drive in /dev/sd*; do
        if [ ! -e "${drive}1" ]; then
            echo "$drive"
        fi
    done
}

# Fungsi untuk membuat filesystem dan mount
setup_drive() {
    local drive=$1
    local mount_point="/mnt/external"

    # Membuat direktori mount jika belum ada
    sudo mkdir -p $mount_point

    # Membuat filesystem ext4 pada drive
    sudo mkfs.ext4 $drive

    # Menambahkan entri ke /etc/fstab untuk mount permanen
    echo "$drive $mount_point ext4 defaults 0 0" | sudo tee -a /etc/fstab

    # Melakukan mount drive
    sudo mount -a
}

# Mencari perangkat penyimpanan baru
new_drive=$(find_new_drive)

if [ -z "$new_drive" ]; then
    echo "Tidak ditemukan perangkat penyimpanan baru."
    exit 1
else
    echo "Ditemukan perangkat baru: $new_drive"
    setup_drive $new_drive
    echo "Perangkat $new_drive telah di-mount ke /mnt/external dan entri telah ditambahkan ke /etc/fstab."
fi

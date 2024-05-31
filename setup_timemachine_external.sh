#!/bin/bash

# Fungsi untuk menampilkan daftar perangkat penyimpanan
list_drives() {
    lsblk -o NAME,SIZE,LABEL,FSTYPE,MOUNTPOINT -dn | grep -E "^sd"
}

# Fungsi untuk mount drive NTFS
setup_drive() {
    local drive=$1
    local mount_point="/mnt/external"

    # Membuat direktori mount jika belum ada
    sudo mkdir -p $mount_point

    # Melakukan mount drive NTFS
    sudo mount -t ntfs-3g /dev/$drive $mount_point

    # Menambahkan entri ke /etc/fstab untuk mount permanen
    echo "/dev/$drive $mount_point ntfs-3g defaults 0 0" | sudo tee -a /etc/fstab
}

# Menampilkan daftar perangkat penyimpanan
echo "Daftar perangkat penyimpanan:"
list_drives | nl -v 0

# Meminta pengguna memilih perangkat
echo "Pilih perangkat penyimpanan yang ingin Anda gunakan (masukkan nomor):"
read -p "Nomor perangkat: " device_number

# Memvalidasi input pengguna
if ! [[ "$device_number" =~ ^[0-9]+$ ]]; then
    echo "Input tidak valid. Harap masukkan nomor perangkat yang benar."
    exit 1
fi

# Menemukan nama perangkat berdasarkan nomor yang dipilih
drive_name=$(list_drives | sed -n "$((device_number + 1))p" | awk '{print $1}')

if [ -z "$drive_name" ]; then
    echo "Perangkat tidak ditemukan. Harap pilih nomor perangkat yang benar."
    exit 1
else
    echo "Perangkat yang dipilih: /dev/$drive_name"
    setup_drive $drive_name
    echo "Perangkat /dev/$drive_name telah di-mount ke /mnt/external dan entri telah ditambahkan ke /etc/fstab."
fi

# Update package list dan install dependencies
sudo apt update
sudo apt install -y netatalk avahi-daemon ntfs-3g

# Membuat direktori Time Machine backup
sudo mkdir -p /mnt/external/timemachine
sudo chown -R $USER:$USER /mnt/external/timemachine
sudo chmod -R 775 /mnt/external/timemachine

# Konfigurasi Netatalk
sudo tee /etc/netatalk/afp.conf > /dev/null <<EOL
[Global]
log file = /var/log/netatalk.log

[TimeMachine]
path = /mnt/external/timemachine
time machine = yes
EOL

# Membuat file konfigurasi Avahi untuk AFP
sudo tee /etc/avahi/services/afpd.service > /dev/null <<EOL
<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
    <name replace-wildcards="yes">%h</name>
    <service>
        <type>_afpovertcp._tcp</type>
        <port>548</port>
    </service>
    <service>
        <type>_device-info._tcp</type>
        <port>0</port>
        <txt-record>model=Xserve</txt-record>
    </service>
</service-group>
EOL

# Restart layanan Netatalk dan Avahi
sudo systemctl restart netatalk
sudo systemctl restart avahi-daemon

echo "Setup Time Machine HomeServer selesai dengan sukses."
echo "Direktori Time Machine ada di /mnt/external/timemachine"

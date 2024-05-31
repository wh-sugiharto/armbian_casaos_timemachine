#!/bin/bash

# Fungsi untuk menemukan perangkat penyimpanan terbesar
find_largest_drive() {
    lsblk -b -dn -o NAME,SIZE | sort -k2 -nr | head -n 1 | awk '{print $1}'
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

# Mencari perangkat penyimpanan terbesar
largest_drive=$(find_largest_drive)

if [ -z "$largest_drive" ]; then
    echo "Tidak ditemukan perangkat penyimpanan."
    exit 1
else
    echo "Ditemukan perangkat terbesar: /dev/$largest_drive"
    setup_drive $largest_drive
    echo "Perangkat /dev/$largest_drive telah di-mount ke /mnt/external dan entri telah ditambahkan ke /etc/fstab."
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

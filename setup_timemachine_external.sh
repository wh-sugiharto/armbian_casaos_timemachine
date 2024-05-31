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

# Update package list dan install dependencies
# sudo apt update
# sudo apt install -y netatalk avahi-daemon

# Membuat direktori Time Machine backup
sudo mkdir -p /mnt/external/timemachine
sudo chown -R $USER:$USER /mnt/external/timemachine
sudo chmod -R 755 /mnt/external/timemachine

# Membuat user baru 'amlogic' tanpa password
sudo adduser --gecos "" amlogic --disabled-password
sudo usermod -p '*' amlogic

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

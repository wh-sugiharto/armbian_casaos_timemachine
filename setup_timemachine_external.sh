#!/bin/bash

# Mendapatkan semua partisi yang ter-mount di /media/devmon/*
partitions=($(lsblk -o NAME,MOUNTPOINT | grep '/media/devmon' | awk '{print $1}'))

if [ ${#partitions[@]} -eq 0 ]; then
    echo "Tidak ada partisi yang ter-mount di /media/devmon."
    exit 1
else
    echo "Partisi yang ter-mount di /media/devmon:"
    for partition in "${partitions[@]}"; do
        echo "/dev/$partition"
    done
fi

# Menggunakan partisi pertama yang ditemukan
partition_to_use=${partitions[0]}
mount_point=$(lsblk -o MOUNTPOINT | grep "/media/devmon")

if [ -z "$mount_point" ]; then
    echo "Tidak ada mount point yang ditemukan untuk partisi /dev/$partition_to_use."
    exit 1
else
    echo "Menggunakan partisi /dev/$partition_to_use yang ter-mount di $mount_point"
fi

# Update package list dan install dependencies
sudo apt update
sudo apt install -y netatalk avahi-daemon ntfs-3g

# Membuat direktori Time Machine backup
sudo mkdir -p $mount_point/timemachine
sudo chown -R $USER:$USER $mount_point/timemachine
sudo chmod -R 775 $mount_point/timemachine

# Konfigurasi Netatalk
sudo tee /etc/netatalk/afp.conf > /dev/null <<EOL
[Global]
log file = /var/log/netatalk.log

[TimeMachine]
path = $mount_point/timemachine
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
echo "Direktori Time Machine ada di $mount_point/timemachine"

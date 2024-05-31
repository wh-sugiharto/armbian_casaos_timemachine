#!/bin/bash

# Fungsi untuk menemukan partisi penyimpanan terbesar
find_largest_partition() {
    lsblk -b -dn -o NAME,SIZE,FSTYPE | grep ntfs | sort -k2 -nr | head -n 1 | awk '{print $1}'
}

# Fungsi untuk unmount partisi jika sudah ter-mount dan kemudian mount ke /mnt/external
setup_partition() {
    local partition=$1
    local mount_point="/mnt/external"

    # Mengecek apakah partisi sudah ter-mount, jika ya, unmount
    mount | grep /dev/$partition > /dev/null
    if [ $? -eq 0 ]; then
        sudo umount /dev/$partition
    fi

    # Membuat direktori mount jika belum ada
    sudo mkdir -p $mount_point

    # Melakukan mount partisi NTFS
    sudo mount -t ntfs-3g /dev/$partition $mount_point

    # Menambahkan entri ke /etc/fstab untuk mount permanen
    echo "/dev/$partition $mount_point ntfs-3g defaults 0 0" | sudo tee -a /etc/fstab
}

# Mencari partisi penyimpanan NTFS terbesar
largest_partition=$(find_largest_partition)

if [ -z "$largest_partition" ]; then
    echo "Tidak ditemukan partisi NTFS."
    exit 1
else
    echo "Ditemukan partisi NTFS terbesar: /dev/$largest_partition"
    setup_partition $largest_partition
    echo "Partisi /dev/$largest_partition telah di-mount ke /mnt/external dan entri telah ditambahkan ke /etc/fstab."
fi

# Menampilkan kapasitas dari /mnt/external
df -h /mnt/external

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

#!/bin/bash

# Update package list and install dependencies
sudo apt update
sudo apt install -y netatalk avahi-daemon

# Create the Time Machine backup directory
#sudo mkdir -p /DATA/timemachine
#sudo chown -R $USER:$USER /DATA/timemachine
#sudo chmod -R 755 /DATA/timemachine

# Create a new user for Time Machine (replace 'yourusername' and 'yourpassword')
#sudo adduser --gecos "" timemachineuser --disabled-password
#echo "timemachineuser:password" | sudo chpasswd

# Configure Netatalk
sudo tee /etc/netatalk/afp.conf > /dev/null <<EOL
[Global]
log file = /var/log/netatalk.log

[TimeMachine]
path = /DATA
time machine = yes
EOL

# Create Avahi configuration file for AFP
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

# Restart Netatalk and Avahi services
sudo systemctl restart netatalk
sudo systemctl restart avahi-daemon

echo "Time Machine HomeServer setup completed successfully."
echo "Time Machine Directory is /DATA"

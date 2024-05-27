
# Armbian CasaOS Time Machine Setup


This repository provides a script to set up a Time Machine server on an Armbian system using Netatalk and Avahi-daemon.

## Preparation

```bash
Before running the script, ensure the following:
1. The data you want to share is mounted.
2. The /DATA directory is shared.
```
## Installation
Using curl:
```bash
bash <(curl -s https://raw.githubusercontent.com/wh-sugiharto/armbian_casaos_timemachine/main/setup_timemachine_server.sh)
```
Using Wget:
```bash
wget -O - https://raw.githubusercontent.com/wh-sugiharto/armbian_casaos_timemachine/main/setup_timemachine_server.sh | bash
```

## Verification
After installation, verify the setup by following these steps:
```bash
1. Open Finder on your macOS device.
2. Navigate to Network -> Amlogic.
3. Click Connect As and enter your Armbian username and password. The shared folder should be displayed.
4. Go to System Preferences -> Time Machine.
5. Click the + button and select "Time Machine on Amlogic Local".
```

## Troubleshoot
If you encounter any issues, ensure that:

- The /DATA directory has the correct permissions.
- The Netatalk and Avahi-daemon services are running without errors.
- You can check the logs using:
```bash
sudo tail -f /var/log/netatalk.log
sudo tail -f /var/log/syslog
```

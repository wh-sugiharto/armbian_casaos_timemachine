#!/bin/bash

# Find all mount points under /media/devmon and unmount them
for mount_point in $(mount | grep '/media/devmon' | awk '{print $3}')
do
  echo "Unmounting $mount_point"
  sudo umount "$mount_point"
done

echo "All mount points under /media/devmon/ have been unmounted."

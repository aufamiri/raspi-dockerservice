#!/bin/bash

# create a snapshot with the current date
DIR=$(dirname -- "$0")
configFile="$DIR/config"

ACCOUNT_ID=
ACCOUNT_KEY=

if [[ -f "$configFile" ]]; then
  # shellcheck disable=SC1090
  . "$configFile"
fi

pass='/home/pi/scripts/pass.txt'
resticExclude='/home/pi/scripts/exclude-restic.txt'
basePath='/mnt/data/sync'
logPath="$DIR/logs"

currentDate=$(date)
echo ""
echo "$currentDate"
echo ""

echo "checking if the path is exist"
if [[ -e "$basePath" ]]; then
  echo "path detected"
else
  echo "path not found"
  exit 1
fi

echo "renaming old log files"
if [[ ! -e $logPath ]]; then
  mkdir -p "$logPath"
fi

mv --backup=numbered --suffix="" /home/pi/scripts/btrfs-snapshot.log /home/pi/scripts/logs/backup.log

echo ""
echo ""
echo "create btrfs snapshot to /mnt/data/snapshot/nextcloud...."
sudo btrfs subvolume snapshot /mnt/data/sync /mnt/data/snapshot/sync
echo "btrfs snapshotting done"

echo ""
echo ""
echo "starting restic backup... "

echo ""
echo "backup to pcloud"
sudo -u pi restic -r rclone:pcloud-main:backup --verbose backup /mnt/data/snapshot/sync --exclude-file=${resticExclude} --password-file=${pass}

echo ""
echo "backup to backblaze"

sudo -u pi ACCOUNT_ID="${ACCOUNT_ID}" B2_ACCOUNT_KEY="${ACCOUNT_KEY}" restic -r b2:kjokkenmoddinger:backup --verbose backup /mnt/data/snapshot/sync --password-file=${pass}
echo "restic backup done"

echo ""
echo ""
echo "deleting btrfs snapshot"
sudo btrfs subvolume delete /mnt/data/snapshot/sync
echo "btrfs delete done"

echo ""
echo ""
echo "closing script"

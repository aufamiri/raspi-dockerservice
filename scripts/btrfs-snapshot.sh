#!/bin/bash

#################################################################################
# This script is used to create a btrfs snapshot, and upload it to the cloud storage provider using Restic
#################################################################################

DIR=$(dirname -- "$0")
source "$DIR/util.sh"

configFile="$DIR/config"

BASE_PATH='/mnt/data/sync'
LOG_FOLDER="$DIR/logs"
RESTIC_PASS="$DIR/pass.txt"
RESTIC_EXCLUDE="$DIR/exclude-restic.txt"
SUBJECT_ERROR_MAIL="weekly backup error"
RECIPIENT_EMAIL=""

if [[ -f "$configFile" ]]; then
  # shellcheck disable=SC1090
  . "$configFile"
fi

# for logging, we convert the date format to use weekday name
# so the logging will automatically rewrite itself per-week
DATE_LOG_FILE=$(date -d "$DATE" "+%A")
LOG_FILE="$LOG_FOLDER/$DATE_LOG_FILE.log"
initLog "$LOG_FILE"

currentDate=$(date)
doLog "$currentDate"

doLog "checking if the path is exist"
if [[ -e "$BASE_PATH" ]]; then
  doLog "path detected"
else
  doLog "path not found"
  notifyEmail "${SUBJECT_ERROR_MAIL}" "backup path not found" "${RECIPIENT_EMAIL}"
  exit 1
fi

#breakpoint
#doLog "retrieving content from outside sources"
## shellcheck disable=SC2024
#sudo -u pi rclone sync -q drive-personal:Apotek/ /mnt/data/sync/Apt/ >>"${LOG_FILE}" 2>&1
#doLog "retrieving content done"

breakpoint
doLog "creating read-only btrfs snapshot to /mnt/data/snapshot/...."
# shellcheck disable=SC2024
sudo btrfs subvolume snapshot -r /mnt/data/sync /mnt/data/snapshot/sync >>"${LOG_FILE}" 2>&1
errorCatcher "${SUBJECT_ERROR_MAIL}" "something went wrong when snapshotting" "${RECIPIENT_EMAIL}"
doLog "btrfs snapshotting done"

breakpoint
doLog "starting restic backup... "

doLog "backing-up to pcloud"
# shellcheck disable=SC2024
sudo -u pi restic -r rclone:pcloud-main:newBackup --verbose backup /mnt/data/snapshot/sync --exclude-file="${RESTIC_EXCLUDE}" --password-file="${RESTIC_PASS}" >>"${LOG_FILE}" 2>&1
errorCatcher "${SUBJECT_ERROR_MAIL}" "restic backup fail" "${RECIPIENT_EMAIL}"
doLog "restic backup done"

breakpoint
doLog "deleting btrfs snapshot"
# shellcheck disable=SC2024
sudo btrfs subvolume delete /mnt/data/snapshot/sync >>"${LOG_FILE}" 2>&1
errorCatcher "${SUBJECT_ERROR_MAIL}" "something went wrong went deleting btrfs snapshot" "${RECIPIENT_EMAIL}"
doLog "btrfs delete done"

echo "closing script"

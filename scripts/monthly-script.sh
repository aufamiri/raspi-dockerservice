#!/bin/bash

DIR=$(dirname -- "$0")
source "$DIR/util.sh"

configFile="$DIR/config"

RESTIC_PASS="$DIR/pass.txt"
RECIPIENT_EMAIL=""

if [[ -f "$configFile" ]]; then
  # shellcheck disable=SC1090
  . "$configFile"
fi

LOG_FILE="$DIR/monthly.log"
initLog "$LOG_FILE"

# for mail purposes, this is being used in the msmtp subject body
doLog "Subject: Monthly Script Reports"

breakpoint
doLog "running scrub command"
# shellcheck disable=SC2024
sudo btrfs scrub start -B -d -R /mnt/data >>"${LOG_FILE}" 2>&1

breakpoint
doLog "fetching SMART attribute"
# shellcheck disable=SC2024
sudo smartctl -a -f brief /dev/sda >>"${LOG_FILE}" 2>&1
# shellcheck disable=SC2024
doLog ""
# shellcheck disable=SC2024
sudo smartctl -a -f brief /dev/sdb >>"${LOG_FILE}" 2>&1

breakpoint
doLog "removing >1 months snapshots"
# shellcheck disable=SC2024
sudo -u morpheus restic -r rclone:pcloud-main:newBackup --password-file="${RESTIC_PASS}" forget --keep-last 10 --prune >>"${LOG_FILE}" 2>&1

breakpoint
doLog "running integrity checks on remote snapshots"
# shellcheck disable=SC2024
sudo -u morpheus restic -r rclone:pcloud-main:newBackup --password-file="${RESTIC_PASS}" check --read-data-subset=5/10 >>"${LOG_FILE}" 2>&1

breakpoint
doLog "reading and clearing dmesg message"
# shellcheck disable=SC2024
sudo dmesg -c >>"${LOG_FILE}" 2>&1

breakpoint
doLog "sending mail to master"
sudo cat "${LOG_FILE}" | sudo -u pi msmtp --from=default -t "${RECIPIENT_EMAIL}"

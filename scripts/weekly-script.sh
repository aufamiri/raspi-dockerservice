#!/bin/bash

DIR=$(dirname -- "$0")
source "$DIR/util.sh"

logFile="$DIR/weekly.log"
initLog "$logFile"

# for mail purposes, this is being used in the msmtp subject body
doLog "Subject: Weekly Script Reports"

breakpoint
doLog "retrieving content from outside sources"
# shellcheck disable=SC2024
sudo -u pi rclone sync -P drive-personal:Apotek/ /mnt/data/sync/Apt/ >>"${logFile}" 2>&1
doLog "retrieving content done"

breakpoint
doLog "running scrub command"
# shellcheck disable=SC2024
sudo btrfs scrub start -B -d -R /mnt/data >>"${logFile}" 2>&1

breakpoint
doLog "running SMART test"
# shellcheck disable=SC2024
sudo smartctl -a -d sat /dev/sda >>"${logFile}" 2>&1
# shellcheck disable=SC2024
doLog ""
# shellcheck disable=SC2024
sudo smartctl -a -d sat /dev/sdb >>"${logFile}" 2>&1

breakpoint
doLog "reading and clearing dmesg message"
# shellcheck disable=SC2024
sudo dmesg -c >>"${logFile}" 2>&1

breakpoint
doLog "sending mail to master"
sudo -u pi msmtp --from=default -t aufa.nabil.amiri@gmail.com <"${logFile}"

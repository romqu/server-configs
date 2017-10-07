#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source borg-passphrase.sh

export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

readonly USER=roman
readonly HOST=kroon.fi
readonly REPO=/mnt/borealis/ensumer/home/backup # Path to repository on the host
readonly TARGET="${USER}@${HOST}/${REPO}"

readonly BORG_CMD_REMOTE_PATH="/mnt/borealis/ensumer/home/borg-linux64"

readonly DOMAINS_DIR="/srv/http/domain/"

for d in "${DOMAINS_DIR}"*/; do
  if [[ -d "$f" && ! -L "${f%/}" ]]; then
    echo "$d"
  fi
done

## last five backups
LAST_BACKUPS="$(borg --remote-path=${BORG_CMD_REMOTE_PATH} list ssh://${TARGET} | tail -5 | awk '{print "backup name: " $1 "  date: " $2" "$3" "$4}')"

FREE_MEMORY="$(free -mh)"

AVAILABLE_SPACE="$(df / -h)"

DRIVE_STATE="$(/opt/MegaRAID/storcli/storcli64 /c0 /eall /sall show all | grep -E "S.M.A.R.T|Predictive")"

BACKUP_SERVICE="$(systemctl list-timers | grep -E "backup|NEXT")"


send_email(){

  echo $(print_status) | mailx -s "status" server@7nerds.de

}

print_status(){

  echo -e "${BACKUP_SERVICE}\n\n${LAST_BACKUPS}\n\n${FREE_MEMORY}\n\n${AVAILABLE_SPACE}\n\n${DRIVE_STATE}"
}

#!/bin/bash

set -o errexit
set -o nounset
#set -o pipefail
#set -euo pipefail

source /usr/local/sbin/borg-passphrase.sh

export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

readonly USER="roman"
readonly HOST="kroon.fi"
readonly REPO="/mnt/borealis/ensumer/home/backup" # Path to repository on the host
readonly TARGET="${USER}@${HOST}/${REPO}"
readonly BORG_CMD_REMOTE_PATH="/mnt/borealis/ensumer/home/borg-linux64"

readonly DOMAINS_DIR="/srv/http/domain/"
readonly EMAIL_ADDRESS="server@7nerds.de"
declare -A DOMAINS_STATUS

DOMAINS=("7nerds.de")
send_email=false
was_backup_successful=true
has_bad_smart_values=false


## last five backups
# LAST_BACKUPS="$(borg --remote-path=${BORG_CMD_REMOTE_PATH} list ssh://${TARGET} | tail -5 | awk '{print "backup name: " $1 "  date: " $2" "$3" "$4}')"
FREE_MEMORY="$(free -mh)"
AVAILABLE_SPACE="$(df / -h)"
DRIVE_STATE=""
#BACKUP_SERVICE="$(systemctl list-timers | grep -E "backup|NEXT")"


get_domains_in_dir(){

  local DIR_WITHOUT_SLASH

  for d in "${DOMAINS_DIR}"*/; do
    if [[ -d "$d" && ! -L "${d%/}" ]]; then
      DIR_WITHOUT_SLASH="${d%/}"
      DOMAINS+=("${DIR_WITHOUT_SLASH##*/}")
    fi
  done
}


check_if_websites_are_online(){

  for domain in "${DOMAINS[@]}"
  do

    if wget --server-response --timeout=3 --tries=1 --spider "${domain}" 2>&1 | grep -q "200 OK"; then
      DOMAINS_STATUS["${domain}"]="Online"
    else
      DOMAINS_STATUS["${domain}"]="Offline"
      send_email=true
    fi

  done
}

check_if_backup_was_successful(){

  if systemctl status backup.service 2>&1 | grep -oq "status=0/SUCCESS"; then
    was_backup_successful=true
  else
    was_backup_successful=false
    send_email=true
  fi
}


check_if_drive_has_bad_smart_values(){

  if /opt/MegaRAID/storcli/storcli64 /c0 /eall /sall show all 2>&1 | grep -E "S.M.A.R.T|Predictive" | grep -q "No"; then
    has_bad_smart_values=false
  else
    has_bad_smart_values=true
    send_email=true
    DRIVE_STATE="$(/opt/MegaRAID/storcli/storcli64 /c0 /eall /sall show all)"
  fi

}

send_email(){

  if [ "$send_email" = true ]; then
    echo $(print_status) | mailx -s "status" "${EMAIL_ADDRESS}"
  fi
}

print_status(){

  echo -e8t5IE "$(print_domains_status)\n${FREE_MEMORY}\n\n${AVAILABLE_SPACE}\n\n${DRIVE_STATE}"
}

print_array(){

  printf '%s\n' "${!1}"
}

print_domains_status(){

  local output=""

  for i in "${!DOMAINS_STATUS[@]}"
  do
    output+="${i}: ${DOMAINS_STATUS[$i]}\n"
  done

  echo "${output}"
}

get_domains_in_dir
check_if_websites_are_online
check_if_backup_was_successful
check_if_drive_has_bad_smart_values
send_email

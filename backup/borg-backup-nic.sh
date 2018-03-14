#!/bin/bash
#
# This is a simple wrapper script for the BorgBackup program. It is primarily
# intended for use in cron or anacron jobs but also provides some functions
# that can simplify interactive maintenance of a Borg repository.
#
# The commands in this script assume a compressed, encrypted, remote
# repository, but the script can be modified for other use cases with minimal
# changes.  See the readme for details.

set -o errexit
set -o nounset
set -o pipefail

export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

# Source the repository passphrase from a separate file. That file's ownership
# and permissions should be set to root:root and 600 to prevent exposure of the
# passphrase.
#
# shellcheck disable=SC1091
source borg-passphrase.sh

# These variables define the path to the Borg repository on the backup machine.
# They can be modified to support local backups if necessary.
#
# Note that the current configuration assumes a one-client-per-repository
# setup, which avoids inefficiencies that can occur when backing up multiple
# machines to a single repository. For details, see
# https://borgbackup.readthedocs.io/en/stable/faq.html#can-i-backup-from-multiple-servers-into-a-single-repository
readonly USER=roman
readonly HOST=kroon.fi
readonly REPO=/mnt/borealis/ensumer/home/backup # Path to repository on the host
readonly TARGET="${USER}@${HOST}:${REPO}"

# Valid options are "none", "keyfile", and "repokey". See Borg docs.
readonly ENCRYPTION_METHOD=repokey

# Compression algorithm and level. See Borg docs.
readonly COMPRESSION_ALGO=zlib
readonly COMPRESSION_LEVEL=6

 readonly SOURCE_PATHS="/srv/http/ /var/backup/mysql"

# Whitespace-separated list of paths to exclude from backup.
readonly EXCLUDE=""

# Number of days, weeks, &c. of backups to keep when pruning.
readonly KEEP_DAILY=7
readonly KEEP_WEEKLY=4
readonly KEEP_MONTHLY=6
readonly KEEP_YEARLY=1

create() {
    echo "Starting Borg archive creation: ${TARGET}"
    
    # shellcheck disable=SC2086
    # We want $SOURCE_PATHS to undergo word splitting here.
    borg create -v --stats --remote-path=/mnt/borealis/ensumer/home/borg-linux64 \
    --compression "${COMPRESSION_ALGO},${COMPRESSION_LEVEL}" \
    --exclude "$EXCLUDE" \
    "${TARGET}::{hostname}-{now:%d-%m-%Y_%H:%M:%S}" $SOURCE_PATHS
    
    echo "Finished Borg archive creation: ${TARGET}"
}

create

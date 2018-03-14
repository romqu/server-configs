#!/bin/sh

/bin/bash /usr/local/sbin/mysql-backup.sh
/bin/bash /usr/local/sbin/borg-backup-nic.sh
/bin/bash /usr/local/sbin/borg-backup-rsync.sh
#!/bin/bash

readonly BACKUP_DIR="/var/backup/mysql"
readonly BACKUP_TIMESTAMP=$(date +%d_%m_%Y_%H_%M_%S)

readonly MYSQL_CMD=/usr/bin/mysql
readonly MYSQL_DUMP=/usr/bin/mysqldump
readonly MYSQL_CONF=/etc/mysql/mysql-client.cnf

readonly ARCHIVE_DAYS="14"

readonly NICE=/usr/bin/nice

readonly DBS_TO_IGNORE="mysql|information_schema|performance_schema|test"
readonly DBS="$($MYSQL_CMD --defaults-extra-file=$MYSQL_CONF -Bse 'show databases' | /bin/grep -Ev $DBS_TO_IGNORE)"

renice 10 $$ > /dev/null
umask 177

for DB in $DBS; do

  echo "Creating backup of \"${DB}\" database."

  $NICE $MYSQL_DUMP --defaults-extra-file=$MYSQL_CONF --events --single-transaction "$DB" | gzip -5 > "${BACKUP_DIR}/mysql_${DB}_${BACKUP_TIMESTAMP}.sql.gz"

done

$NICE find "${BACKUP_DIR}" -mtime +"${ARCHIVE_DAYS}" -exec rm {} \;


# /usr/local/sbin
echo "noob" | wall

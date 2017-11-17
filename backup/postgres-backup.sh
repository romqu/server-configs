#!/bin/bash

readonly backup_dir="/var/backup/postgresql"
readonly backup_timestamp=$(date +%d_%m_%Y_%H_%M_%S)

readonly pg_username="postgres"

readonly pg="/usr/bin/psql"
readonly pg_dump="/usr/bin/pg_dump"
readonly pg_prefix="psql_"
readonly pg_suffix=".sql.gz"

readonly archive_days="14"

readonly nice="/usr/bin/nice"

readonly dbs_to_ignore="template0|template1"
readonly dbs="$($pg -U $pg_username -q -A -t -c "SELECT datname FROM pg_database" | /bin/grep -Ev $dbs_to_ignore)"

renice 10 $$ > /dev/null
umask 177

for db in $dbs; do
    
    echo "Creating backup of \"${db}\" database."
    
    $nice $pg_dump "$db" | gzip -5 > "$ backup_dir}/${pg_prefix}_${db}_${backup_timestamp}${pg_suffix}"
    
done

$nice find "${backup_dir}" -maxdepth 1 -mtime +"${archive_days}" -exec rm -rf {} \;
#!/bin/bash

set -o errexit
set -o nounset

readonly mysql_cmd="/usr/bin/mysql"
readonly mysql_conf="/etc/mysql/mysql-client.cnf"
readonly mysql_default_char_set="utf8mb4"
readonly mysql_collate="utf8mb4_unicode_520_ci"

readonly user_db="seafile"
readonly pw_db="Findus1234"
readonly ccnet_db="ccnet-db"
readonly seafile_db="seafile-db"
readonly seahub_db="seahub-db"

readonly seafile_dir="/srv/http/cloud/cloud.7nerds.de"

readonly dbs=(
  "${ccnet_db}"
  "${seafile_db}"
  "${seahub_db}"
)

add_system_user(){

  adduser --gecos --system --no-create-home --disabled-login seafile
}

create_db(){

  $mysql_cmd --defaults-extra-file=$mysql_conf <<EOF
    CREATE USER IF NOT EXISTS '${user_db}'@'localhost' IDENTIFIED BY '${pw_db}';
EOF

  for db in "${dbs[@]}"; do

    echo "$db"

    $mysql_cmd --defaults-extra-file=$mysql_conf <<EOF
      DROP DATABASE IF EXISTS \`${db}\`;
      CREATE DATABASE \`${db}\` DEFAULT CHARACTER SET ${mysql_default_char_set} COLLATE ${mysql_collate};
      GRANT ALL PRIVILEGES ON \`${db}\`.* TO '${user_db}'@'localhost';
EOF
  done
}

install_packages_debian(){

  apt-get update
  apt-get install -y python2.7 libpython2.7 python-setuptools python-imaging \
  python-ldap python-simplejson python-mysqldb python-memcache python-urllib3
}

download_and_create(){

  mkdir -p "${seafile_dir}"
  cd "${seafile_dir}"

  wget https://download.seadrive.org/seafile-server_6.2.3_x86-64.tar.gz
  tar -xzf seafile-server_*
  mkdir installed
  mv seafile-server_* installed

}

function import_seahub_database_structure {
  $mysql_cmd seahub-db < "${seafile_dir}"/seahub/sql/mysql.sql
}

add_system_user
create_db
install_packages_debian
download_and_create

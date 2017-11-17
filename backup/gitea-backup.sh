#!/bin/bash

readonly backup_timestamp=$(date +%d_%m_%Y_%H_%M_%S)

readonly gitea_dir="/srv/http/git/git.7nerds.de/"
readonly backup_dir="/var/backup/gitea/"

readonly backup_prefix="gitea_"
readonly backup_prefix="gitea_"


tar -zcvf "${backup_dir}"
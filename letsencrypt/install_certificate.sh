#!/bin/bash

set -o errexit
set -o nounset
#set -euo pipefail


readonly domains=("$1" "www.$1")
readonly certificate_dir="/etc/ssl/private/"
readonly domain_dir="/srv/http/domain/"


install_certificates(){

  for domain in domains; do

    if [ ! -d "${certificate_dir}${domain}" ]; then
      mkdir "${certificate_dir}${domain}"
    fi

    acme.sh --issue -d "${domain}" -w "${domain_dir}${domain}" --nginx --debug --keylength ec-384

    acme.sh --install-cert --ecc --debug -d "${domain}" \
    --cert-file      /etc/ssl/private/rodnok.de/"${domain}".cert.pem  \
    --key-file       /etc/ssl/private/rodnok.de/"${domain}".key.pem  \
    --fullchain-file /etc/ssl/private/rodnok.de/fullchain.pem \
    --reloadcmd "systemctl reload nginx.service"

  done

  systemctl reload nginx.service
}

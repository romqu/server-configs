#!/bin/bash

set -o errexit
set -o nounset
#set -euo pipefail


readonly domains=("$1" "www.$1")
readonly domain_dir="$2"
readonly certificate_dir="/etc/ssl/private/"
readonly acme_cmd="/root/.acme.sh/acme.sh"

install_certificates(){
    
    for domain in "${domains[@]}"; do
        
        if [ ! -d "${certificate_dir}${domain}" ]; then
            mkdir "${certificate_dir}${domain}"
        fi
        
        if ! acme.sh --list 2>&1 | grep -q "${domain//\./\\.}"; then
            "${acme_cmd}" --issue -d "${domain}" -w "${domain_dir}${domain//www\./}" --nginx --debug --keylength ec-384
        fi
        
        "${acme_cmd}" --install-cert --ecc --debug -d "${domain}" \
        --cert-file      /etc/ssl/private/"${domain}"/"${domain}".cert.pem  \
        --key-file       /etc/ssl/private/"${domain}"/"${domain}".key.pem  \
        --fullchain-file /etc/ssl/private/"${domain}"/fullchain.pem \
        --reloadcmd "systemctl reload nginx.service"
        
    done
    
    systemctl reload nginx.service
}

install_certificates

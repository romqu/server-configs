#!/bin/bash

set -o errexit
set -o nounset
#set -euo pipefail

readonly domain_dir="/srv/http/domain/"

readonly wp_domain="rodnok.de"
readonly wp_domain_name="$(echo ${wp_domain} | sed 's/\(.*\)\..*/\1/')"
readonly wp_domain_dash="${wp_domain//\./-}"
readonly wp_admin_user="notadmin"
readonly wp_admin_pw="nopw"
readonly wp_admin_mail="r.qlluistler@7nerds.de"
readonly wp_db_prefix="wp_"
readonly wp_db_pw="Test1234"
readonly wp_db_host="localhost"
readonly wp_title="Title"
readonly wp_locale="de_DE"

readonly mysql_cmd="/usr/bin/mysql"
readonly mysql_conf="/etc/mysql/mysql-backwp_nginx_enabled_siteup-config.cnf"
readonly mysql_default_char_set="utf8mb4"
readonly mysql_collate="utf8mb4_unicode_520_ci"

readonly wp_db_name="${wp_db_prefix}${wp_domain//\./_}"
readonly wp_domain_path="${domain_dir}${wp_domain}"
readonly wp_domain_url="http://${wp_domain}"
readonly wp_cache_dir="${wp_domain_path}/cache"

readonly nginx_sites_enabled_path="/etc/nginx/sites-enabled/"
readonly nginx_sites_available_path="/etc/nginx/sites-available/"
readonly wp_nginx_template_file="/etc/nginx/templates/wordpress"
readonly wp_nginx_sites_available_file="${nginx_sites_available_path}${wp_domain}"

readonly wp_nginx_first_to_replace="wordpress\.template"
readonly wp_nginx_second_to_replace="wordpress-template"
readonly wp_nginx_third_to_replace="wordpress"

wp_create_db(){

  $mysql_cmd --defaults-extra-file=$mysql_conf <<EOF
    CREATE DATABASE ${wp_db_name} DEFAULT CHARACTER SET ${mysql_default_char_set} COLLATE ${mysql_collate};
    GRANT ALL ON ${wp_db_name}.* TO '${wp_db_name}'@'localhost' IDENTIFIED BY '${wp_db_pw}';
    FLUSH PRIVILEGES;
EOF
}

wp_install_core(){

  wp core download --allow-root \
  --path="${wp_domain_path}" \
  --locale="${wp_locale}" \
  --skip-themes \
  --skip-plugins

  cd "${wp_domain_path}"

  wp config create --allow-root \
  --dbname="${wp_db_name}" \
  --dbuser="${wp_db_name}" \
  --dbpass="${wp_db_pw}" \
  --dbhost="${wp_db_host}" \
  --dbprefix="${wp_db_prefix}" \
  --locale="${wp_locale}" \
  --dbcharset="${mysql_default_char_set}" \
  --dbcollate="${mysql_collate}"

  wp core install --allow-root \
  --url="${wp_domain_url}" \
  --title="${wp_title}" \
  --admin_user="${wp_admin_user}" \
  --admin_password="${wp_admin_pw}" \
  --admin_email="${wp_admin_mail}"

}

wp_install_plugins(){

  wp plugin install --activate wordpress-seo
}

wp_create_cache_dir(){

  if [ ! -d "${wp_cache_dir}" ]; then
    mkdir "${wp_cache_dir}"
  fi
}

wp_set_permissions(){

  chown -R www-data:www-data "${wp_domain_path}"
  chmod 640 "${wp_domain_path}/wp-config.php"
}

wp_nginx_setup_site(){

  yes | cp -i "${wp_nginx_template_file}" "${wp_nginx_sites_available_file}" &>/dev/null
  sed -i "s/${wp_nginx_first_to_replace}/${wp_domain}/g" "${wp_nginx_sites_available_file}"
  sed -i "s/${wp_nginx_second_to_replace}/${wp_domain_dash}/g" "${wp_nginx_sites_available_file}"
  sed -i "s/${wp_nginx_third_to_replace}/${wp_domain_name}/g" "${wp_nginx_sites_available_file}"
}

wp_nginx_enabled_site_without_ssl(){

  if [ ! -L "${nginx_sites_enabled_path}${wp_domain}" ] ; then
    ln -s "${wp_nginx_sites_available_file}" "${nginx_sites_enabled_path}"
  fi

  systemctl reload nginx.service
}

wp_install_certificates(){

  /home/snickers/install_certificate.sh "${wp_domain}"
}

wp_nginx_enable_site_ssl(){

  
}



#wp_create_db
#wp_install_core
#wp_install_plugins
wp_set_permissions
wp_create_cache_dir
wp_nginx_setup_site
wp_nginx_enabled_site

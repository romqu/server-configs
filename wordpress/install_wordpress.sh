#!/bin/bash

set -o errexit
set -o nounset
#set -euo pipefail

readonly domain_dir="/srv/http/wordpress/"

readonly wp_domain="$1"
readonly wp_domain_name="$(echo ${wp_domain} | sed 's/\(.*\)\..*/\1/')"
readonly wp_domain_dash="${wp_domain//\./-}"
readonly wp_admin_user="demo"
readonly wp_admin_pw="demo"
readonly wp_admin_mail="r.quistler@7nerds.de"
readonly wp_db_prefix="wp_"
readonly wp_db_pw="Findus1234"
readonly wp_db_host="localhost"
readonly wp_title="Title"
readonly wp_locale="de_DE"
readonly wp_plugins=("wordpress-seo" "contact-form-7" "uk-cookie-consent" "loginpress" "file-manager")

readonly mysql_cmd="/usr/bin/mysql"
readonly mysql_conf="/etc/mysql/mysql-client.cnf"
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
readonly wp_nginx_third_to_replace="wordpress_cache"
readonly wp_nginx_site_root_replace="\(root ${wp_domain_path//\//\\/};\)"
readonly wp_nginx_site_return_replace="\(#\)\(return 301 https\)"
readonly wp_nginx_site_first_ssl_replace="\(#\)\(ssl_certificate\)"
readonly wp_nginx_site_second_ssl_replace="\(#\)\(ssl_trusted_certificate\)"

wp_create_db(){

  $mysql_cmd --defaults-extra-file=$mysql_conf <<EOF
    DROP DATABASE IF EXISTS ${wp_db_name};
    CREATE DATABASE ${wp_db_name} DEFAULT CHARACTER SET ${mysql_default_char_set} COLLATE ${mysql_collate};
    GRANT ALL ON ${wp_db_name}.* TO '${wp_db_name}'@'localhost' IDENTIFIED BY '${wp_db_pw}';
EOF
}

wp_install_core(){

  if [[ -d "${wp_domain_path}" ]] && [[ "$(ls -A ${wp_domain_path})" ]]; then
    rm -rf ${wp_domain_path}
  fi

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
  --admin_email="${wp_admin_mail}" \
  --skip-email \
  --skip-themes \
  --skip-plugins
}

wp_delete_all_plugins(){

  readonly local wp_plugins_to_delete=($(wp plugin --allow-root list --field=name))

  for wp_plugin in "${wp_plugins_to_delete[@]}"; do
    wp plugin --allow-root delete "${wp_plugin}"
  done

}

wp_install_plugins(){

  for wp_plugin in "${wp_plugins[@]}"; do
    wp plugin install --allow-root --activate "${wp_plugin}"
  done
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

wp_nginx_enabled_site_no_ssl(){

  if [ ! -L "${nginx_sites_enabled_path}${wp_domain}" ] ; then
    ln -s "${wp_nginx_sites_available_file}" "${nginx_sites_enabled_path}"
  fi

  systemctl reload nginx.service
}

wp_install_certificates(){

  sudo -u root /usr/local/sbin/acme_sh_install_certificate.sh  "${wp_domain}" "${domain_dir}"
}

wp_nginx_enable_site_ssl(){

  sed -i "0,/${wp_nginx_site_root_replace}/s//#\1/" "${wp_nginx_sites_available_file}"
  sed -i "s/${wp_nginx_site_return_replace}/\2/" "${wp_nginx_sites_available_file}"
  sed -i "s/${wp_nginx_site_first_ssl_replace}/\2/" "${wp_nginx_sites_available_file}"
  sed -i "s/${wp_nginx_site_second_ssl_replace}/\2/" "${wp_nginx_sites_available_file}"

  systemctl reload nginx.service
}


#wp_create_db
#wp_install_core
#wp_delete_all_plugins
#wp_install_plugins
#wp_create_cache_dir
#wp_set_permissions
wp_nginx_setup_site
#wp_nginx_enabled_site_no_ssl
#wp_install_certificates
#wp_nginx_enable_site_ssl

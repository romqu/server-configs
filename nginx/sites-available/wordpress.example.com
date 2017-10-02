# Define path to cache and memory zone. The memory zone should be unique.
# keys_zone=ssl-fastcgi-cache.com:100m creates the memory zone and sets the maximum size in MBs.
# inactive=60m will remove cached items that haven't been accessed for 60 minutes or more.
fastcgi_cache_path /srv/https/example.com/cache levels=1:2 keys_zone=example:100m inactive=60m;

# Choose between www and non-www, listen on the *wrong* one and redirect to
# the right one -- http://wiki.nginx.org/Pitfalls#Server_Name
#
server {

  include includes/listen_http.conf;

  # listen on both hosts
  server_name example.com www.example.com;

  # and redirect to the https host (declared below)
  # avoiding http://www -> https://www -> https:// chain.
  include includes/redirect_https.conf;
}

server {

  include includes/listen_http2.conf;

  # listen on the wrong host
  server_name www.example.com;

  include includes/ssl.conf;

  # and redirect to the non-www host (declared below)
  include includes/redirect_https.conf;
}

server {

    include includes/listen_http2.conf;

    server_name example.com;

    root /srv/https/example.com;
    index index.php;

    include includes/ssl.conf
    include includes/location/letsencrypt.conf
    include includes/security.conf

    ## verify chain of trust of OCSP response using Root CA and Intermediate certs
    ssl_trusted_certificate /path/to/root_CA_cert_plus_intermediates;

    # certs sent to the client in SERVER HELLO are concatenated in ssl_certificate
    ssl_certificate /path/to/signed_cert_plus_intermediates;
    ssl_certificate_key /path/to/private_key;

    access_log /var/log/nginx/example-access.log;
    error_log /var/log/nginx/example-erros.log;

    # Specify a charset
    charset utf-8;

    include includes/fastcgi-cache.conf;

    include includes/location/protected_system_files.conf

    location / {

      try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {

      try_files $uri = 404;

      include includes/fastcgi-params.conf;

      fastcgi_pass unix:/run/php/php7.1-fpm.sock;
      fastcgi_index index.php;

      fastcgi_cache fastcgicache;

      # Skip cache based on rules in includes/fastcgi-cache.conf
      .
      fastcgi_cache_bypass $skip_cache;
      fastcgi_no_cache $skip_cache;

      fastcgi_read_timeout 360s;
      fastcgi_buffer_size 128k;
      fastcgi_buffers 4 256k;

      # Define memory zone for caching. Should match key_zone in fastcgi_cache_path above.
      fastcgi_cache example.com;
    }

    # Rewrite robots.txt
    rewrite ^/robots.txt$ /index.php last;

    include includes/resolver.conf
}

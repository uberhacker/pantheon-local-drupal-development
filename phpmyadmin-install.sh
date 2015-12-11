#!/bin/bash
sudo DEBIAN_FRONTEND=noninteractive apt-get install phpmyadmin -y
sudo sh -c 'cat << "EOF" > /etc/nginx/sites-available/phpmyadmin
server {
    listen 8080;
    root /usr/share/phpmyadmin;

    access_log /var/log/nginx/phpmyadmin-access.log;
    error_log /var/log/nginx/phpmyadmin-error.log;

    location / {
        index index.php;
        try_files $uri/ $uri /index.php?$args;
    }

    location ~ ^/(.+\.php)$ {
        try_files $uri =404;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PATH_INFO $fastcgi_script_name;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 4k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_intercept_errors on;
    }
}
EOF'
sudo ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin
/vagrant/restart-lamp.sh
echo "Browse to http://192.168.33.10:8080 and login with Username: drupal and Password: drupal"

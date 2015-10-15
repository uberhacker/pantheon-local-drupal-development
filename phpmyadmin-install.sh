#!/bin/bash
sudo DEBIAN_FRONTEND=noninteractive apt-get install phpmyadmin -y
sudo ln -s /usr/share/phpmyadmin/ /var/www/html/phpmyadmin
/vagrant/restart-lamp.sh
echo "Browse to http://192.168.33.10/phpmyadmin and login with Username: drupal and Password: drupal"

#!/bin/bash
sudo apt-get install debconf-utils -y
echo phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2 | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get install phpmyadmin -y
echo "Browse to http://192.168.33.10/phpmyadmin and login with Username: drupal and Password: drupal"

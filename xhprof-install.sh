#!/bin/bash
sudo apt-get install php5-xhprof
sudo sed -i 's,/var/run/php5-fpm.sock,/var/run/php5-fpm.sock -idle-timeout 120,g' /etc/apache2/mods-available/fastcgi.conf
/vagrant/restart-lamp.sh

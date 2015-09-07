#!/bin/bash
XHPROF=$(dpkg -l | grep php5-xhprof)
if [ ! -z "$XHPROF" ]; then
  echo "XHProf is already installed."
  exit
fi
sudo apt-get install php5-xhprof
sudo sed -i 's,/var/run/php5-fpm.sock,/var/run/php5-fpm.sock -idle-timeout 120,g' /etc/apache2/mods-available/fastcgi.conf
/vagrant/restart-lamp.sh

#!/bin/bash
XDEBUG=$(dpkg -l | grep php5-xdebug)
if [ ! -z "$XDEBUG" ]; then
  echo "Xdebug is already installed."
  exit
fi
echo "Installing Xdebug..."
sudo apt-get install php5-xdebug -y --force-yes
if [ ! -d /var/log/xdebug ]; then
  sudo mkdir /var/log/xdebug
  sudo chown www-data:www-data /var/log/xdebug
fi
sudo sh -c 'cat << "EOF" >> /etc/php5/mods-available/xdebug.ini
xdebug.default_enable=1
xdebug.idekey="xdebug"
xdebug.remote_enable=1
xdebug.remote_autostart=0
xdebug.remote_port=9000
xdebug.remote_handler="dbgp"
xdebug.remote_log="/var/log/xdebug/xdebug.log"
xdebug.remote_host="192.168.33.10"
EOF'
/vagrant/restart-lamp.sh

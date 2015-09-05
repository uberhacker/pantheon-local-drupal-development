#!/bin/bash

# Install Xdebug - Based on article by Anthony Curreri
# http://www.mailbeyond.com/phpstorm-vagrant-install-xdebug-php
VM_ID_ADDRESS="192.168.33.10"
echo "[vagrant provisioning] Installing Xdebug..."
sudo mkdir /var/log/xdebug
sudo chown www-data:www-data /var/log/xdebug
sudo pecl install xdebug
XDEBUG_PATH=`find / -name 'xdebug.so'`
sudo cp /vagrant/xdebug.ini /tmp/
sudo sed -i "s@XDEBUG_PATH@$XDEBUG_PATH@g" /tmp/xdebug.ini
sudo sed -i "s@$VM_ID_ADDRESS@$VM_ID_ADDRESS@g" /tmp/xdebug.ini
sudo cat /tmp/xdebug.ini >> /etc/php5/fpm/php.ini
sudo cat /tmp/xdebug.ini >> /etc/php5/cli/php.ini
sudo service apache2 restart # restart apache so latest php config is picked up

#!/bin/bash
if [ ! "$(pidof php5-fpm)" ]; then
  sudo service php5-fpm start
else
  sudo service php5-fpm restart
fi
if [ ! "$(pidof redis-server)" ]; then
  sudo service redis-server start
else
  sudo service redis-server restart
fi
if [ ! "$(pidof apache2)" ]; then
  sudo service apache2 start
else
  sudo service apache2 restart
fi
if [ ! "$(pidof mysqld)" ]; then
  sudo service mysql start
else
  sudo service mysql restart
fi

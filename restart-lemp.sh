#!/bin/bash
if [ ! "$(pidof php5-fpm)" ]; then
  sudo /etc/init.d/php5-fpm start
else
  sudo /etc/init.d/php5-fpm restart
fi
if [ ! "$(pidof redis-server)" ]; then
  sudo /etc/init.d/redis-server start
else
  sudo /etc/init.d/redis-server restart
fi
if [ ! "$(pidof nginx)" ]; then
  sudo /etc/init.d/nginx start
else
  sudo /etc/init.d/nginx restart
fi
if [ ! "$(pidof mysqld)" ]; then
  sudo /etc/init.d/mysql start
else
  sudo /etc/init.d/mysql restart
fi

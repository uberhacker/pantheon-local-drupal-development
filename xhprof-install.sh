#!/bin/bash
XHPROF=$(dpkg -l | grep php5-xhprof)
if [ ! -z "$XHPROF" ]; then
  echo "XHProf is already installed."
  exit
fi
echo "Installing XHProf..."
sudo apt-get install php5-xhprof -y
/vagrant/restart-lemp.sh

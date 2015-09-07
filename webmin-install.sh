#!/bin/bash
wget http://www.webmin.com/jcameron-key.asc
sudo apt-key add jcameron-key.asc
rm -f jcameron-key.asc
sudo add-apt-repository 'deb http://download.webmin.com/download/repository sarge contrib'
sudo add-apt-repository -r 'deb-src http://download.webmin.com/download/repository sarge contrib'
sudo add-apt-repository 'deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib'
sudo add-apt-repository -r 'deb-src http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib'
sudo apt-get update
sudo apt-get install webmin -y

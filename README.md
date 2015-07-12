Introduction
------------
The purpose of this project is to create a useful local development environment to build Drupal sites hosted on Pantheon.  Since the infrastructure is built on VirtualBox, this configuration can work on virtually any operating system.  The entire LAMP stack is installed and configured.  Drupal installations are fully automated based on existing Pantheon Site Names.  This includes Apache virtual hosts, PHP configuration, MySQL databases and user permissions, and Drupal site installs via installation profiles.

Installation
------------
1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).
2. Install [Vagrant](http://www.vagrantup.com/downloads.html).
3. Install Git (MAC/BSD/Linux) via your package manager or Git Bash (Windows).  See [Git for Windows](https://msysgit.github.io/).
4. Open Terminal (MAC/BSD/Linux) or Git Bash (Windows).  Windows users should run as administrator.  See [Configure Applications to Always Run as an Administrator](https://technet.microsoft.com/en-us/magazine/ff431742.aspx).
**Replace *site* with the Pantheon Site Name.**
> $ git clone
> $ cd
> $ vagrant up
> $ vagrant ssh
> vagrant@debian ~$ git-config (follow prompts)
> vagrant@debian ~$ site-install (follow prompts)
> vagrant@debian ~$ exit
> $ hosts.sh add *site*
5. Visit http://*site*.dev in your favorite browser.
6. Enjoy.

Maintenance
-----------
To restart the LAMP stack:
> vagrant@debian ~$ restart-lamp

To list hosts:
> $ hosts.sh list

Optional
--------
Install webmin:
> vagrant@debian ~$ webmin-install

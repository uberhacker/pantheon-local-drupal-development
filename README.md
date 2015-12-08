Introduction
------------
The purpose of this project is to create a useful local development environment to build Drupal sites hosted on Pantheon.  Since the infrastructure is built on VirtualBox, this configuration can work on virtually any host operating system.  The entire LEMP stack is installed and configured.  Drupal installations are fully automated based on existing Pantheon Site Names.  This includes Nginx virtual hosts, PHP configuration, MySQL databases and user permissions, and Drupal site installs via installation profiles.

Updates
-------
2015-10-13: This project is now using Nginx, which more closely resembles the Pantheon infrastructure.  Also, Debian has been upgraded from version 7 (aka wheezy) to 8 (aka jessie).

Prerequisites
-------------
Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).

Install [VirtualBox Extension Pack](https://www.virtualbox.org/wiki/Downloads).

Install [Vagrant](http://www.vagrantup.com/downloads.html).

Install Git (MAC/BSD/Linux) via your package manager or Git Bash (Windows).  See [Git for Windows](https://msysgit.github.io/).

Installation
------------
Open Terminal (MAC/BSD/Linux) or Git Bash (Windows).  Windows users should run as administrator.

See [Configure Applications to Always Run as an Administrator](https://technet.microsoft.com/en-us/magazine/ff431742.aspx).

Although not necessary, if you want to open VirtualBox, you should also run as administrator.

**Replace *site* with the Pantheon Site Name.**

> $ git config --global core.autocrlf false  **This step is important**

> $ git clone https://github.com/uberhacker/pantheon-local-drupal-development.git

> $ cd pantheon-local-drupal-development

> $ vagrant up

> $ vagrant ssh

> vagrant@debian:~$ ssh-config

> vagrant@debian:~$ git-config (follow prompts)

> vagrant@debian:~$ site-install (follow prompts)

> vagrant@debian:~$ exit

> $ hosts.sh add *site*

Visit http://*site*.dev in your favorite browser.  Enjoy.

Usage
-----
Once the VM has been provisioned, if you want to create additional sites, simply execute the following:

> $ cd /path/to/pantheon-local-drupal-development

> $ vagrant up

> $ vagrant ssh

> vagrant@debian:~$ site-install *site* *profile* *multisite*

**Replace *site* with the Pantheon Site Name, *profile* with the Drupal install profile and *multisite* with the Drupal multisite domain**

> vagrant@debian:~$ exit

> $ hosts.sh add *site*

On site-install, if you don't provide *site*, *profile* or *multisite*, you will be prompted to enter the appropriate values if needed.

Maintenance
-----------
To restart the LAMP stack:
> vagrant@debian:~$ restart-lamp

To repair the database and file permissions:
> vagrant@debian:~$ site-fix *site*

To display the Nginx logs:
> vagrant@debian:~$ site-log *site* [access|error] [less|tail]

If the second or third arguments are omitted, the default values are error and tail.

To download the latest database and upload to your local database:
> vagrant@debian:~$ site-db *site*

To list hosts:
> $ hosts.sh list

Optional
--------
Install phpMyAdmin:
> vagrant@debian ~$ phpmyadmin-install

Install vim configured for Drupal:
> vagrant@debian ~$ vim-install

Install webmin:
> vagrant@debian ~$ webmin-install

Install codespell:
> vagrant@debian ~$ codespell-install

Install compass:
> vagrant@debian ~$ compass-install

Install less:
> vagrant@debian ~$ less-install

Install XHProf:
> vagrant@debian ~$ xhprof-install

Install Xdebug:
> vagrant@debian ~$ xdebug-install

Troubleshooting
---------------
If you notice an error similar to the following:
> ./hosts.sh: line 17: /C/Windows/System32/drivers/etc/hosts: Permission denied

Make sure the hosts file is not read only.  Navigate to C:\Windows\System32\drivers\etc in File Explorer.  Right click on hosts, select Properties, uncheck the Read-only box next to Attributes: and then click OK.

If you forgot to execute the first step: git config --global core.autocrlf false, you may not be able to execute git-config or site-install.  To fix, execute the following:
> vagrant@debian:~$ dos2unix /vagrant/git-config.sh

> vagrant@debian:~$ dos2unix /vagrant/site-install.sh

If you are having trouble with rsync during vagrant up in Windows, try the following:
> Download <a href="https://www.itefix.net/dl/cwRsync_5.4.1_x86_Free.zip">cwRsync Free Edition</a>, extract and copy into your Git bin directory (usually in C:\Program Files\Git\bin or C:\Program Files (x86)\Git\bin).

> $ vagrant install plugin vagrant-rsync

> $ vagrant up

If you get a message that states VirtualBox Guest Additions are missing or not matching the host version during vagrant up, try the following:
> Use a client app like WinSCP or Filezilla and login to 192.168.33.10 via SFTP on port 22 with username vagrant and password vagrant.  Then copy VBoxGuestAdditions.iso (located at C:\Program Files\Oracle\VirtualBox in Windows) to /home/vagrant on the guest.

> $ vagrant ssh

> vagrant@debian:~$ sudo mkdir /media/vb

> vagrant@debian:~$ sudo mount -t iso9660 -o loop /home/vagrant/VBoxGuestAdditions.iso /media/vb

> vagrant@debian:~$ cd /media/vb

> vagrant@debian:~$ sudo ./VBoxLinuxAdditions.run (and follow the instructions)

> vagrant@debian:~$ exit

> $ vagrant reload

Tips
----
To check your code syntax for errors:
> vagrant@debian:~$ cd /path/to/custom/code/directory

> vagrant@debian:~$ drupalcs my_custom_module/

To automatically fix code syntax errors:
> vagrant@debian:~$ cd /path/to/custom/code/directory

> vagrant@debian:~$ drupalcbf my_custom_module/

To spell check your code for errors:
> vagrant@debian ~$ codespell-install

> vagrant@debian:~$ cd /path/to/custom/code/directory

> vagrant@debian:~$ codespell my_custom_module/

To examine your database:
> vagrant@debian ~$ phpmyadmin-install

> Browse to http://192.168.33.10/phpmyadmin and login with Username: drupal and Password: drupal

To update all composer installed apps (drush, terminus, etc.):
> vagrant@debian ~$ composer-up

To get the ip address of the server:
> vagrant@debian ~$ ip

A warning about synced folders:
> If you want to reinstall a site using site-install and you have enabled synced folders, you should clear out your synced folder locally beforehand, otherwise you may notice errors when the script attempts to remove existing files.

Faq
---
Q. Can I install more than one site?

A. Absolutely.  Just execute site-install and make sure the site name is not the same as an existing site, otherwise, it will be overwrote.  Also, the site must first exist in your Pantheon dashboard.


Q. Where do I access my site on the server?

A. All sites are subdirectories of /var/www.  So if your site is my-site, it would be located at /var/www/my-site.


Q. Where is Solr?

A. I may plan to install Solr in a future release.


Q. Why did you choose Debian instead of Ubuntu or CentOS?

A. This is a very good question. I felt Debian was lightweight and included everything I needed for a barebones development environment I could build around.  I also figured it would be easier to upgrade without having to reconfigure or reinstall the entire operating system.

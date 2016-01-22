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

**Replace *site* with the Pantheon Site Name and optionally *[env]* with the environment.**

> $ git config --global core.autocrlf false  **This step is important**

> $ git clone https://github.com/uberhacker/pantheon-local-drupal-development.git

> $ cd pantheon-local-drupal-development

> $ vagrant up

> $ vagrant ssh

> vagrant@debian:~$ ssh-config

> vagrant@debian:~$ git-config (follow prompts)

> vagrant@debian:~$ site-install (follow prompts)

> vagrant@debian:~$ exit

> $ hosts.sh add *site* *[env]*

Visit http://*site*-*env*.site in your favorite browser (Example: http://my-pantheon-dev.site where my-pantheon is the Pantheon Site Name and dev is the environment). Enjoy.

Usage
-----
Once the VM has been provisioned, if you want to create additional sites, simply execute the following:

> $ cd /path/to/pantheon-local-drupal-development

> $ vagrant up

> $ vagrant ssh

> vagrant@debian:~$ site-install *site* *env* *profile* *multisite*

**Replace *site* with the Pantheon Site Name, *env* with the environment, *profile* with the Drupal install profile and *multisite* with the Drupal multisite domain**
On site-install, if you don't provide *site*, *env*, *profile* or *multisite*, you will be prompted to enter the appropriate values if needed.

> vagrant@debian:~$ exit

> $ hosts.sh add *site* *[env]*

The default value for *env* is dev.  The only time you would want to provide *env* is if you are installing a multi-dev site.

Maintenance
-----------
To restart the LEMP stack:
> vagrant@debian:~$ restart-lemp

To repair the database and file permissions:
> vagrant@debian:~$ site-fix *site*

To display the Nginx logs:
> vagrant@debian:~$ site-log *site* *env* [access|error] [less|tail]

The *site* and *env* arguments are not needed if you are within the Drupal root directory and want to accept the defaults.
The default value for *env* is dev.  If the third or fourth arguments are omitted, the default values are error and tail.

To download the latest database and upload to your local database:
> vagrant@debian:~$ site-db *site* *env*

To download the latest files backup to your local environment:
> vagrant@debian:~$ site-files *site* *env*

To download the latest code, files and database backup to your local environment:
> vagrant@debian:~$ site-sync *site* *env*

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
**If you notice an error similar to the following:**
> ./hosts.sh: line 17: /C/Windows/System32/drivers/etc/hosts: Permission denied

> Make sure the hosts file is not read only.  Navigate to C:\Windows\System32\drivers\etc in File Explorer.  Right click on hosts, select Properties, uncheck the Read-only box next to Attributes: and then click OK.

**If you forgot to execute the first step: git config --global core.autocrlf false, you may not be able to execute git-config or site-install.  To fix, execute the following:**
> vagrant@debian:~$ dos2unix /vagrant/git-config.sh

> vagrant@debian:~$ dos2unix /vagrant/site-install.sh

**If you are having trouble with rsync during vagrant up in Windows with a message as follows:**
> "rsync" could not be found on your PATH. Make sure that rsync
is properly installed on your system and available on the PATH.

> Download <a href="https://www.itefix.net/dl/cwRsync_5.4.1_x86_Free.zip">cwRsync Free Edition</a>, extract and copy into your Git bin directory (usually in C:\Program Files\Git\bin or C:\Program Files (x86)\Git\bin).

> $ vagrant plugin install vagrant-rsync

> $ vagrant reload

**If you installed cwRsync as instructed above and execute vagrant ssh, you may get a message similar to the following:**
> cygwin warning:
  MS-DOS style path detected: .../.vagrant/machines/default/virtualbox/private_key
  Preferred POSIX equivalent is: .../.vagrant/machines/default/virtualbox/private_key
  CYGWIN environment variable option "nodosfilewarning" turns off this warning.
  Consult the user's guide for more details about POSIX paths:
    http://cygwin.com/cygwin-ug-net/using.html#using-pathnames

> *If you don't get a vagrant@debian:~$ prompt, press Ctrl+C and try connecting via iTerm 2 (MAC) or PuTTY (Windows).  See Tips section below for more details.*

**If rsync still doesn't work with Vagrant 1.8:**
> See this workaround: https://github.com/mitchellh/vagrant/issues/6702#issuecomment-166503021

**If you get a message that states GuestAdditions are missing or not matching the host version during vagrant up, try the following:**
> $ cd /path/to/pantheon-local-drupal-development

> $ cp "C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso" . <<< Don't forget the trailing dot

> $ vagrant reload

> $ vagrant ssh (see previous troubleshooting tip if you have issues)

> vagrant@debian:~$ sudo mkdir /media/vb

> vagrant@debian:~$ sudo mount -t iso9660 -o loop /vagrant/VBoxGuestAdditions.iso /media/vb

> vagrant@debian:~$ cd /media/vb

> vagrant@debian:~$ sudo ./VBoxLinuxAdditions.run

> vagrant@debian:~$ exit

> $ vagrant reload

Alternatively, you could install from the iso on the VM if you know the host version is the same.

Just replace /vagrant/VBoxGuestAdditions.iso with /usr/share/virtualbox/VBoxGuestAdditions.iso on the mount line above.

Follow the steps below:

> vagrant@debian:~$ sudo mkdir /media/vb

> vagrant@debian:~$ sudo mount -t iso9660 -o loop /usr/share/virtualbox/VBoxGuestAdditions.iso /media/vb

> vagrant@debian:~$ cd /media/vb

> vagrant@debian:~$ sudo ./VBoxLinuxAdditions.run

> vagrant@debian:~$ exit

> $ vagrant reload

**If you are unable to bring up the site in your browser after vagrant up in Windows 10, try reinstalling VirtualBox to get the bridged network working again.**

Tips
----
**Use iTerm 2 (MAC) or PuTTY (Windows) to connect via 192.168.33.10 with username vagrant and password vagrant to improve your terminal experience.**

> Download <a href="https://www.iterm2.com/downloads.html">iTerm 2</a> (MAC) or <a href="http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html">PuTTY</a> (Windows).

**To check your code syntax for errors:**
> vagrant@debian:~$ cd /path/to/custom/code/directory

> vagrant@debian:~$ drupalcs my_custom_module/

**To automatically fix code syntax errors:**
> vagrant@debian:~$ cd /path/to/custom/code/directory

> vagrant@debian:~$ drupalcbf my_custom_module/

**To spell check your code for errors:**
> vagrant@debian ~$ codespell-install

> vagrant@debian:~$ cd /path/to/custom/code/directory

> vagrant@debian:~$ codespell my_custom_module/

**To examine your database:**
> vagrant@debian ~$ phpmyadmin-install

> Browse to http://192.168.33.10:8080 and login with Username: drupal and Password: drupal

**To update all composer installed apps (drush, terminus, etc.):**
> vagrant@debian ~$ composer-up

**To get the ip address of the server:**
> vagrant@debian ~$ ip

**To adjust the VM resources:**
> If your host system supports it, you can increase the vb.cpus and vb.memory values in Vagrantfile to improve performance of the VM.  Remember to vagrant reload after making changes.

**A warning about synced folders:**
> If you want to reinstall a site using site-install and you have enabled synced folders, you should clear out your synced folder locally beforehand, otherwise you may notice errors when the script attempts to remove existing files.

Faq
---
Q. Can I install more than one site?

A. Absolutely.  Just execute site-install and make sure the site name is not the same as an existing site, otherwise, it will be overwrote.  Also, the site must first exist in your Pantheon dashboard.


Q. Can I install a multi-dev site?

A. Absolutely.  Just make sure the site already exists in your Pantheon dashboard and include the multi-site name in the *env* argument.


Q. Where do I access my site on the server?

A. All sites are subdirectories of /var/www.  So if your site is a dev environment of my-site, it would be located at /var/www/my-site-dev.


Q. Where is Solr?

A. I may plan to install Solr in a future release.


Q. Where is Varnish?

A. I may plan to install Varnish in a future release.


Q. Why did you choose Debian instead of Ubuntu or CentOS?

A. This is a very good question. I felt Debian was lightweight and included everything I needed for a barebones development environment I could build around.  I also figured it would be easier to upgrade without having to reconfigure or reinstall the entire operating system.

Introduction
------------
The purpose of this project is to create a useful local development environment to build Drupal sites hosted on Pantheon.  Since the infrastructure is built on VirtualBox, this configuration can work on virtually any operating system.  The entire LAMP stack is installed and configured.  Drupal installations are fully automated based on existing Pantheon Site Names.  This includes Apache virtual hosts, PHP configuration, MySQL databases and user permissions, and Drupal site installs via installation profiles.

Prerequisites
-------------
Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads). **Tested with version 4.3.30.  Version 5.0 is untested and may cause issues.**

Install [VirtualBox Extension Pack](https://www.virtualbox.org/wiki/Downloads).

Install [Vagrant](http://www.vagrantup.com/downloads.html).

Install Git (MAC/BSD/Linux) via your package manager or Git Bash (Windows).  See [Git for Windows](https://msysgit.github.io/).

Installation
------------
Open Terminal (MAC/BSD/Linux) or Git Bash (Windows).  Windows users should run as administrator.

See [Configure Applications to Always Run as an Administrator](https://technet.microsoft.com/en-us/magazine/ff431742.aspx).
**Replace *site* with the Pantheon Site Name.**
> $ git config --global core.autocrlf false  **This step is important**

> $ git clone https://github.com/uberhacker/pantheon-local-drupal-development.git

> $ cd pantheon-local-drupal-development

> $ vagrant up

> $ vagrant ssh

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

To display the Apache logs:
> vagrant@debian:~$ site-log *site* [access|error] [less|tail]

If the second or third arguments are omitted, the default values are error and tail.

To restore the database back to the state of the initial site install:
> vagrant@debian:~$ site-restore-db *site*

To list hosts:
> $ hosts.sh list

Optional
--------
Install vim configured for Drupal:
> vagrant@debian ~$ vim-install

Install webmin:
> vagrant@debian ~$ webmin-install

Troubleshooting
---------------
If you notice an error similar to the following:
> ./hosts.sh: line 17: /C/Windows/System32/drivers/etc/hosts: Permission denied

Make sure the hosts file is not read only.  Navigate to C:\Windows\System32\drivers\etc in File Explorer.  Right click on hosts, select Properties, uncheck the Read-only box next to Attributes: and then click OK.

If you forgot to execute the first step: git config --global core.autocrlf false, you may not be able to execute git-config or site-install.  To fix, execute the following:
> vagrant@debian:~$ dos2unix /vagrant/git-config.sh

> vagrant@debian:~$ dos2unix /vagrant/site-install.sh

Tips
----
To configure redis:
> vagrant@debian:~$ cd /var/www/*site*

> vagrant@debian:~$ drush en redis -y

Add the following to settings.php:
> // Use Redis for caching.

> $redis_path = 'sites/all/modules/contrib/redis';

> $conf['redis_client_interface'] = 'PhpRedis';

> $conf['cache_backends'][] = $redis_path . '/redis.autoload.inc';

> $conf['cache_default_class'] = 'Redis_Cache';

> // Do not use Redis for cache_form (no performance difference).

> $conf['cache_class_cache_form'] = 'DrupalDatabaseCache';

> // Use Redis for Drupal locks (semaphore).

> $conf['lock_inc'] = $redis_path . '/redis.lock.inc';

Change $redis_path to match your environment path.

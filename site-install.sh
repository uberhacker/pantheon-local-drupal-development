#!/bin/bash

# Check for prerequisites
TERMINUS=$(which terminus)
if [ -z "$TERMINUS" ]; then
  echo "Terminus is not installed.  See https://github.com/pantheon-systems/cli."
  exit
fi
DRUSH=$(which drush)
if [ -z "$DRUSH" ]; then
  echo "Drush is not installed.  See http://www.drush.org/en/master/install."
  exit
fi

# Store command arguments
SITENAME=""
if test $1; then
  SITENAME=$1
fi
PROFILE=""
if test $2; then
  PROFILE=$2
fi
MULTISITE="default"
if test $3; then
  MULTISITE=$3
fi

# Retrieve stored Terminus credentials
EMAIL=""
PASSWORD=""
HTTPUSER=""
HTTPPASS=""
if [ -f $HOME/.terminus_auth ]; then
  while read line; do
    for pair in $line; do
      set -- $(echo $pair | tr '=' ' ')
      if [ "$1" == "email" ]; then
        EMAIL=${line#"$1="}
      fi
      if [ "$1" == "password" ]; then
        PASSWORD=${line#"$1="}
      fi
      if [ "$1" == "httpuser" ]; then
        HTTPUSER=${line#"$1="}
      fi
      if [ "$1" == "httppass" ]; then
        HTTPPASS=${line#"$1="}
      fi
    done
  done < $HOME/.terminus_auth
fi

# Terminus authentication prompts
LOGGEDIN=$(terminus auth whoami)
if [ "$LOGGEDIN" == "You are not logged in." ]; then
  if [ -z "$EMAIL" ]; then
    echo -n "Enter your Pantheon email address: "; read EMAIL
    if [ -z "$EMAIL" ]; then
      exit
    else
      echo -n "Save email address? (Y/n): "; read -n 1 SAVEMAIL
      if [ -z "$SAVEMAIL" ]; then
        SAVEMAIL=y
      fi
      if [ "$SAVEMAIL" == "Y" ]; then
        SAVEMAIL=y
      fi
      if [ "$SAVEMAIL" == "y" ]; then
        echo "email=$EMAIL" > $HOME/.terminus_auth
      fi
    fi
  fi
  if [ -z "$PASSWORD" ]; then
    echo -n "Enter your Pantheon password: "; read -s PASSWORD
    if [ -z "$PASSWORD" ]; then
      exit
    else
      echo -n "Save password? (y/N): "; read -n 1 SAVEPASS
      echo $'\n'
      if [ "$SAVEPASS" == "Y" ]; then
        SAVEPASS=y
      fi
      if [ "$SAVEPASS" == "y" ]; then
        echo "password=$PASSWORD" >> $HOME/.terminus_auth
      fi
    fi
  fi
  if [ -z "$HTTPUSER" ]; then
    echo -n "Enter the HTTP Basic Authentication username: "; read HTTPUSER
    if [ ! -z "$HTTPUSER" ]; then
      echo "httpuser=$HTTPUSER" >> $HOME/.terminus_auth
    fi
  fi
  if [ -z "$HTTPPASS" ]; then
    echo -n "Enter the HTTP Basic Authentication password: "; read -s HTTPPASS
    if [ ! -z "$HTTPPASS" ]; then
      echo "httppass=$HTTPPASS" >> $HOME/.terminus_auth
    fi
  fi
  # Change email to match commits to Pantheon
  GITEMAIL=$(git config --get user.email)
  if [ "$GITEMAIL" != "$EMAIL" ]; then
    git config --global user.email $EMAIL
  fi
  terminus auth login $EMAIL --password="$PASSWORD"
fi

# Remove saved credentials if unable to login
LOGGEDIN=$(terminus auth whoami)
if [ "$LOGGEDIN" == "You are not logged in." ]; then
  if [ -f $HOME/.terminus_auth ]; then
    rm -f $HOME/.terminus_auth
  fi
  exit
fi

# Prompt for the Pantheon Site Name
if [ -z "$SITENAME" ]; then
  echo ""
  echo -n "Enter the Pantheon Site Name: "; read SITENAME
  if [ -z "$SITENAME" ]; then
    exit
  fi
fi

# Validate the Pantheon Site Name
ID=$(terminus site info --site=$SITENAME --field=id)
if [ -z "$ID" ]; then
  echo ""
  echo "$SITENAME is not a valid Pantheon Site Name."
  echo ""
  exit
fi

# Remove existing site files if they exist
if [ -d /var/www/$SITENAME ]; then
  sudo rm -rf /var/www/$SITENAME
fi

# Clone the Pantheon git repository
cd /var/www
git clone "ssh://codeserver.dev.$ID@codeserver.dev.$ID.drush.in:2222/~/repository.git" $SITENAME
if [ -d /var/www/$SITENAME ]; then
  DBNAME=${SITENAME//-/_}
  if [ ! -f /etc/apache2/sites-available/$SITENAME ]; then
    # Create MySQL/MariaDB database
    echo "drop database if exists $DBNAME" | mysql -u root
    echo "create database $DBNAME" | mysql -u root
    echo "grant all on $DBNAME.* to drupal@localhost identified by 'drupal'" | mysql -u root
    echo "flush privileges" | mysql -u root

    # Create Apache virtual host
    cd /etc/apache2/sites-available
    sudo cp default $SITENAME
    head -1 $SITENAME > /tmp/$SITENAME
    echo "  ServerName $SITENAME.dev" >> /tmp/$SITENAME
    tail -$(($(cat $SITENAME | wc -l)-1)) $SITENAME >> /tmp/$SITENAME
    sed -i "s,\t,  ,g" /tmp/$SITENAME
    sed -i "s,/var/www,/var/www/$SITENAME,g" /tmp/$SITENAME
    sudo mv -f /tmp/$SITENAME $SITENAME
    head -10 $SITENAME > /tmp/$SITENAME
    echo "    Include /var/www/$SITENAME/.htaccess" >> /tmp/$SITENAME
    tail -$(($(cat $SITENAME | wc -l)-10)) $SITENAME >> /tmp/$SITENAME
    sed -i "s,error.log,$SITENAME-error.log,g" /tmp/$SITENAME
    sed -i "s,access.log,$SITENAME-access.log,g" /tmp/$SITENAME
    sudo mv -f /tmp/$SITENAME $SITENAME

    # Add synced folder
    FOLDER=$(grep -n "config.vm.synced_folder \"../$SITENAME\", \"/var/www/$SITENAME\"" /vagrant/Vagrantfile)
    if [ -z "$FOLDER" ]; then
      echo -n "Do you want to enable synced folders? (Y/n): "; read -n 1 SYNC
      echo $'\n'
      if [ -z "$SYNC" ]; then
        SYNC=y
      fi
      if [ "$SYNC" == "Y" ]; then
        SYNC=y
      fi
      if [ "$SYNC" == "y" ]; then
        POS=$(grep -n '# config.vm.synced_folder "../data", "/vagrant_data"' /vagrant/Vagrantfile | cut -d':' -f1)
        head -$POS /vagrant/Vagrantfile > /tmp/$SITENAME
        echo "  config.vm.synced_folder \"../$SITENAME\", \"/var/www/$SITENAME\"" >> /tmp/$SITENAME
        tail -$(($(cat /vagrant/Vagrantfile | wc -l)-$POS)) /vagrant/Vagrantfile >> /tmp/$SITENAME
        sudo mv -f /tmp/$SITENAME /vagrant/Vagrantfile
        echo ""
        echo "Synced folder configured from /var/www/$SITENAME to ../$SITENAME."
        echo ""
        echo "Before performing an installation with site-install, execute the following:"
        echo ""
        echo "vagrant@debian:~$ exit"
        echo "$ mkdir ../$SITENAME"
        echo "$ vagrant reload"
        echo "$ vagrant ssh"
        echo "vagrant@debian:~$ site-install $SITENAME"
        echo ""
        echo "Otherwise, the next time the VM is loaded with vagrant up, the existing site files will be removed."
        echo ""
        exit
      fi
    fi
  fi

  # Enable Apache virtual host
  if [ ! -f /etc/apache2/sites-enabled/$SITENAME ]; then
    sudo a2ensite $SITENAME
    sudo service apache2 restart
  fi

  # Set install profile
  PROFS=$(ls /var/www/$SITENAME/profiles)
  if [ -z "$PROFILE" ]; then
    echo ""
    echo "The following install profiles are available:"
    echo $PROFS
    echo ""
    echo -n "Enter the install profile: "; read PROFILE
    if [ -z "$PROFILE" ]; then
      exit
    fi
  fi
  VALID=no
  for PROF in $PROFS; do
    if [ "$PROF" == "$PROFILE" ]; then
      VALID=yes
    fi
  done
  if [ "$VALID" == "no" ]; then
    echo "$PROFILE is not a valid install profile."
    exit
  fi

  # Set multisite
  MULTISITES=""
  DEFAULTSITE="default"
  cd /var/www/$SITENAME/sites
  SITES=$(echo $(ls -d */) | sed 's,/,,g')
  for SITE in $SITES; do
    if [[ "$SITE" != "all" && -f "/var/www/$SITENAME/sites/$SITE/settings.php" ]]; then
      if [ -z "$MULTISITES" ]; then
        MULTISITES="$SITE"
      else
        MULTISITES="$MULTISITES $SITE"
      fi
      DEFAULTSITE="$SITE"
    fi
  done
  if [ "$DEFAULTSITE" == "$MULTISITES" ]; then
    MULTISITE="$DEFAULTSITE"
  fi
  if [[ "$MULTISITE" == "default" && "$MULTISITES" != "default" ]]; then
    echo ""
    echo "The following multisites are available:"
    echo $MULTISITES
    echo ""
    echo -n "Enter the multisite ($DEFAULTSITE): "; read MULTISITE
    if [ -z "$MULTISITE" ]; then
      MULTISITE="$DEFAULTSITE"
    fi
  fi
  if [ "$MULTISITE" != "$DEFAULTSITE" ]; then
    VALID=no
    for MULTI in $MULTISITES; do
      if [ "$MULTI" == "$MULTISITE" ]; then
        VALID=yes
      fi
    done
    if [ "$VALID" == "no" ]; then
      echo "$MULTISITE is not a valid multisite."
      exit
    fi
  fi

  # Perform the drush site install
  cd /var/www/$SITENAME
  drush site-install $PROFILE --account-name=admin --account-pass=admin --db-url=mysql://drupal:drupal@localhost/$DBNAME --site-name=$SITENAME --sites-subdir=$MULTISITE -v -y
  if [ -d /var/www/$SITENAME/sites/all/modules ]; then
    # Make sure essential directories exist
    if [ ! -d /var/www/$SITENAME/sites/all/modules/contrib ]; then
      mkdir /var/www/$SITENAME/sites/all/modules/contrib
    fi
    if [ ! -d /var/www/$SITENAME/sites/all/modules/custom ]; then
      mkdir /var/www/$SITENAME/sites/all/modules/custom
    fi
    if [ ! -d /var/www/$SITENAME/sites/all/modules/features ]; then
      mkdir /var/www/$SITENAME/sites/all/modules/features
    fi
    if [ ! -d /var/www/$SITENAME/sites/default/files ]; then
      mkdir /var/www/$SITENAME/sites/default/files
    fi

    # Fix file permissions
    for SITE in $SITES; do
      sudo chmod -R ug+w /var/www/$SITENAME/sites/$SITE
      if [ -d "/var/www/$SITENAME/sites/$SITE/files" ]; then
        sudo chown -R vagrant:www-data /var/www/$SITENAME/sites/$SITE/files
      fi
    done

    # Replace placeholder credentials if needed
    SETTINGS="/var/www/$SITENAME/sites/$MULTISITE/settings.php"
    sed -i "s/DATABASE/$DBNAME/g" $SETTINGS
    sed -i "s/USERNAME/drupal/g" $SETTINGS
    sed -i "s/PASSWORD/drupal/g" $SETTINGS

    # Create settings.local.php
    LOCALSETTINGS=${SETTINGS//settings.php/settings.local.php}
    cp $SETTINGS $LOCALSETTINGS
    git checkout $SETTINGS
    LOCAL="if (file_exists(dirname(__FILE__) . '/settings.local.php')) {
  include dirname(__FILE__) . '/settings.local.php';
}"
    LAST3=$(tail -3 $SETTINGS)
    if [ "$LAST3" != "$LOCAL" ]; then
      echo "" >> $SETTINGS
      echo "if (file_exists(dirname(__FILE__) . '/settings.local.php')) {" >> $SETTINGS
      echo "  include dirname(__FILE__) . '/settings.local.php';" >> $SETTINGS
      echo "}" >> $SETTINGS
    fi

    # Define drush based on multisite
    DRUSH="drush"
    if [ "$MULTISITE" != "default" ]; then
      DRUSH="drush -l $MULTISITE"
    fi

    # Prompt to enable Redis
    echo -n "Would you like to enable Redis? (Y/n): "; read -n 1 REDIS
    echo $'\n'
    if [ -z "$REDIS" ]; then
      REDIS=y
    fi
    if [ "$REDIS" == "Y" ]; then
      REDIS=y
    fi
    if [ "$REDIS" == "y" ]; then
      REDISAUTOLOAD=$(find sites/ -name redis.autoload.inc)
      REDISLOCK=$(find sites/ -name redis.lock.inc)
      if [[ -z "$REDISAUTOLOAD" || -z "$REDISLOCK" ]]; then
        $DRUSH dl -y redis
        REDISAUTOLOAD=$(find sites/ -name redis.autoload.inc)
        REDISLOCK=$(find sites/ -name redis.lock.inc)
      fi
      $DRUSH en -y redis
cat << EOF >> $LOCALSETTINGS
// Use Redis for caching.
\$conf['redis_client_interface'] = 'PhpRedis';
\$conf['cache_backends'][] = '$REDISAUTOLOAD';
\$conf['cache_default_class'] = 'Redis_Cache';
// Do not use Redis for cache_form (no performance difference).
\$conf['cache_class_cache_form'] = 'DrupalDatabaseCache';
// Use Redis for Drupal locks (semaphore).
\$conf['lock_inc'] = '$REDISLOCK';
EOF
    fi

    # Download and load the latest database backup if it exists
    DB=$(terminus site backup get --site=$SITENAME --env=dev --element=database --latest)
    if [ ! -z "$DB" ]; then
      echo "Downloading $DB to dev-$SITENAME.sql.gz..."
      curl --compress -o dev-$SITENAME.sql.gz $DB
      gunzip dev-$SITENAME.sql.gz
      echo "Loading dev-$SITENAME.sql..."
      $DRUSH sqlc < dev-$SITENAME.sql
      #rm -f dev-$SITENAME.sql
      # Make sure the Drupal admin user login is admin/admin
      $DRUSH sqlq "update users set name = 'admin' where uid = 1"
      $DRUSH upwd admin --password=admin
    fi

    # Enable development modules
    #$DRUSH dl -n migrate migrate_extras coder devel devel_themer hacked redis simplehtmldom-7.x-1.12 stage_file_proxy
    #$DRUSH en -y migrate_extras coder devel_themer hacked redis stage_file_proxy
    $DRUSH dl -n stage_file_proxy
    $DRUSH en -y stage_file_proxy
    DOMAIN=$(echo $(terminus site hostnames list --site=$SITENAME --env=dev) | cut -d" " -f4)
    if [ ! -z "$DOMAIN" ]; then
      $DRUSH vset stage_file_proxy_hotlink 1
      if [[ ! -z "$HTTPUSER" && ! -z "$HTTPPASS" ]]; then
        $DRUSH vset stage_file_proxy_origin "https://$HTTPUSER:$HTTPPASS@$DOMAIN"
      else
        $DRUSH vset stage_file_proxy_origin "https://$DOMAIN"
      fi
    fi

    # Output final message
    echo ""
    echo "Make sure '192.168.33.10 $SITENAME.dev' exists in your local hosts file and then open http://$SITENAME.dev in your browser."
    echo "The local hosts file is located at /etc/hosts (MAC/BSD/Linux) or C:\Windows\System32\drivers\etc\hosts (Windows)."
    echo ""
  else
    echo "drush site-install failed."
  fi
else
  echo "git clone failed."
fi

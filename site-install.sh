#!/bin/bash

# Check for prerequisites
GIT=$(which git)
if [ $? == 1 ]; then
  echo "Git is not installed.  See https://github.com/git/git."
  exit
fi
TERMINUS=$(which terminus)
if [ $? == 1 ]; then
  echo "Terminus is not installed.  See https://github.com/pantheon-systems/cli."
  exit
fi
DRUSH=$(which drush)
if [ $? == 1 ]; then
  echo "Drush is not installed.  See http://www.drush.org/en/master/install."
  exit
fi

# Store command arguments
SITE=""
if test $1; then
  SITE=$1
fi
ENV=dev
if test $2; then
  ENV=$2
fi
PROFILE=""
if test $3; then
  PROFILE=$3
fi
MULTISITE="default"
if test $4; then
  MULTISITE=$4
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
WHOAMI=$($TERMINUS auth whoami)
if [ $? == 1 ]; then
  if [ -z "$EMAIL" ]; then
    echo -n "Enter your Pantheon dashboard email address: "; read EMAIL
    if [ -z "$EMAIL" ]; then
      exit
    else
      echo -n "Save email address? (Y/n): "; read -n 1 SAVEMAIL
      echo ""
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
    echo -n "Enter your Pantheon dashboard password: "; read -s PASSWORD
    if [ -z "$PASSWORD" ]; then
      exit
    else
      echo -n "Save password? (y/N): "; read -n 1 SAVEPASS
      echo ""
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
  GITEMAIL=$($GIT config --get user.email)
  if [ "$GITEMAIL" != "$EMAIL" ]; then
    $GIT config --global user.email $EMAIL
  fi
  $TERMINUS auth login $EMAIL --password="$PASSWORD"
fi

# Remove saved credentials if unable to login
WHOAMI=$($TERMINUS auth whoami)
if [ $? == 1 ]; then
  if [ -f $HOME/.terminus_auth ]; then
    rm -f $HOME/.terminus_auth
  fi
  exit
fi

# Prompt for the Pantheon Site Name
if [ -z "$SITE" ]; then
  echo ""
  $TERMINUS sites list
  echo -n "Enter the Pantheon Site Name: "; read SITE
  if [ -z "$SITE" ]; then
    exit
  fi
fi

# Validate the Pantheon Site Name
ID=$($TERMINUS site info --site=$SITE --field=id)
if [ -z "$ID" ]; then
  echo ""
  echo "$SITE is not a valid Pantheon Site Name."
  echo ""
  exit
fi


# Validate the Pantheon environment
GIT_CMD=$($TERMINUS site connection-info --site=$SITE --env=$ENV --field=git_command)-$ENV
if [ $? == 1 ]; then
  echo "$ENV is not a cloneable Pantheon environment."
  exit
fi

# Remove existing site files if they exist
DIR="$SITE-$ENV"
if [ -d "/var/www/$DIR" ]; then
  sudo rm -rf /var/www/$DIR
fi

# Clone the Pantheon git repository
cd /var/www
$GIT_CMD
if [ -d /var/www/$DIR ]; then
  DBNAME=${DIR//-/_}
  if [ ! -f /etc/nginx/sites-available/$DIR ]; then
    # Create MySQL/MariaDB database
    echo "drop database if exists $DBNAME" | mysql -u root
    echo "create database $DBNAME" | mysql -u root
    echo "grant all on $DBNAME.* to drupal@localhost identified by 'drupal'" | mysql -u root
    echo "flush privileges" | mysql -u root

    # Create Nginx virtual host
    cp /etc/nginx/conf.d/drupal.conf.example /tmp/$DIR
    sed -i "s,example.com,$DIR.site,g" /tmp/$DIR
    sed -i "s,drupal7,$DIR,g" /tmp/$DIR
    sudo mv /tmp/$DIR /etc/nginx/sites-available/$DIR
    sudo ln -s /etc/nginx/sites-available/$DIR /etc/nginx/sites-enabled/$DIR

    # Add synced folder
    FOLDER=$(grep -n "config.vm.synced_folder \"../$DIR\", \"/var/www/$DIR\"" /vagrant/Vagrantfile)
    if [ -z "$FOLDER" ]; then
      echo ""
      echo -n "Do you want to enable synced folders? (Y/n): "; read -n 1 SYNC
      echo ""
      if [ -z "$SYNC" ]; then
        SYNC=y
      fi
      if [ "$SYNC" == "Y" ]; then
        SYNC=y
      fi
      if [ "$SYNC" == "y" ]; then
        echo ""
        echo -n "Do you want to enable NFS? (Y/n): "; read -n 1 NFS
        echo ""
        if [ -z "$NFS" ]; then
          NFS=y
        fi
        if [ "$NFS" == "Y" ]; then
          NFS=y
        fi
        POS=$(grep -n '# config.vm.synced_folder "../data", "/vagrant_data"' /vagrant/Vagrantfile | cut -d':' -f1)
        head -$POS /vagrant/Vagrantfile > /tmp/$DIR
        if [ "$NFS" == "y" ]; then
          echo "  config.vm.synced_folder \"../$DIR\", \"/var/www/$DIR\", type: \"nfs\"" >> /tmp/$DIR
        else
          echo "  config.vm.synced_folder \"../$DIR\", \"/var/www/$DIR\"" >> /tmp/$DIR
        fi
        tail -$(($(cat /vagrant/Vagrantfile | wc -l)-$POS)) /vagrant/Vagrantfile >> /tmp/$DIR
        sudo mv -f /tmp/$DIR /vagrant/Vagrantfile
        echo ""
        echo "Synced folder configured from /var/www/$DIR to ../$DIR."
        echo ""
        echo "Before performing an installation with site-install, execute the following:"
        echo ""
        echo "vagrant@debian:~$ exit"
        echo "$ mkdir ../$DIR"
        if [ "$NFS" == "y" ]; then
          echo "$ vagrant plugin install vagrant-winnfsd (Windows host only)"
        fi
        echo "$ vagrant reload"
        echo "$ vagrant ssh"
        echo "vagrant@debian:~$ site-install $SITE $ENV"
        echo ""
        echo "Otherwise, the next time the VM is loaded with vagrant up, the existing site files will be removed."
        echo ""
        exit
      fi
    fi
  fi

  # Set install profile
  PROFS=$(ls /var/www/$DIR/profiles)
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
  cd /var/www/$DIR/sites
  SITES=$(echo $(ls -d */) | sed 's,/,,g')
  for S in $SITES; do
    if [[ "$S" != "all" && -f "/var/www/$DIR/sites/$S/settings.php" ]]; then
      if [ -z "$MULTISITES" ]; then
        MULTISITES="$S"
      else
        MULTISITES="$MULTISITES $S"
      fi
      DEFAULTSITE="$S"
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

  # Replace placeholder credentials if needed
  SETTINGS="/var/www/$DIR/sites/$MULTISITE/settings.php"
  sed -i "s/DATABASE/$DBNAME/g" $SETTINGS
  sed -i "s/USERNAME/drupal/g" $SETTINGS
  sed -i "s/PASSWORD/drupal/g" $SETTINGS

  # Perform the drush site install
  cd /var/www/$DIR
  $DRUSH site-install $PROFILE --account-name=admin --account-pass=admin --db-url=mysql://drupal:drupal@localhost/$DBNAME --site-name=$DIR --sites-subdir=$MULTISITE -v -y
  if [ -d /var/www/$DIR/sites/all/modules ]; then
    # Make sure essential directories exist
    if [ ! -d /var/www/$DIR/sites/all/modules/contrib ]; then
      mkdir /var/www/$DIR/sites/all/modules/contrib
    fi
    if [ ! -d /var/www/$DIR/sites/all/modules/custom ]; then
      mkdir /var/www/$DIR/sites/all/modules/custom
    fi
    if [ ! -d /var/www/$DIR/sites/all/modules/features ]; then
      mkdir /var/www/$DIR/sites/all/modules/features
    fi
    if [ ! -d /var/www/$DIR/sites/default/files ]; then
      mkdir /var/www/$DIR/sites/default/files
    fi

    # Fix file permissions
    for S in $SITES; do
      sudo chmod -R ug+w /var/www/$DIR/sites/$S
      if [ -d "/var/www/$DIR/sites/$S/files" ]; then
        sudo chown -R vagrant:www-data /var/www/$DIR/sites/$S/files
      fi
    done

    # Create settings.local.php
    LOCALSETTINGS=${SETTINGS//settings.php/settings.local.php}
    cp $SETTINGS $LOCALSETTINGS
    $GIT checkout $SETTINGS
    LOCAL="if (file_exists(dirname(__FILE__) . '/settings.local.php')) {
  include dirname(__FILE__) . '/settings.local.php';
}"
    LAST3=$(tail -3 $SETTINGS)
    if [ "$LAST3" != "$LOCAL" ]; then
      echo "" >> $SETTINGS
      echo "if (file_exists(dirname(__FILE__) . '/settings.local.php')) {" >> $SETTINGS
      echo "  include dirname(__FILE__) . '/settings.local.php';" >> $SETTINGS
      echo "}" >> $SETTINGS
    else
      head -$(($(cat $LOCALSETTINGS | wc -l)-3)) $LOCALSETTINGS > /tmp/settings.local.php
      sudo mv -f /tmp/settings.local.php $LOCALSETTINGS
    fi

    # Install registry rebuild
    if [ ! -f "$HOME/.drush/registry_rebuild/registry_rebuild.php" ]; then
      $DRUSH dl registry_rebuild -y
      $DRUSH cc drush
    fi

    # Define drush based on multisite
    if [ "$MULTISITE" != "default" ]; then
      DRUSH="$DRUSH -l $MULTISITE"
    fi

    # Download and load the latest database backup if it exists
    DB=$($TERMINUS site backups get --site=$SITE --env=$ENV --element=db --latest)
    if [ ! -z "$DB" ]; then
      LABEL=${DB:0:11}
      if [ "$LABEL" == "Backup URL:" ]; then
        DB=${DB:12}
      fi
      NEW_DB="$DIR.sql"
      echo "Downloading latest database backup $DB to $NEW_DB.gz..."
      curl -o $NEW_DB.gz $DB
      gunzip $NEW_DB.gz
      $DRUSH sql-drop -y
      echo "Loading $NEW_DB..."
      $DRUSH sqlc < $NEW_DB
      # Make sure the Drupal admin user login is admin/admin
      $DRUSH sqlq "update users set name = 'admin' where uid = 1"
      $DRUSH upwd admin --password=admin
      $DRUSH rr
    fi

    # Make sure the Redis service is running
    REDIS_PID=$(pidof redis-server)
    if [ -z "$REDIS_PID" ]; then
      REDIS_PACKAGE=$(dpkg -l | grep redis-server)
      if [ -z "$REDIS_PACKAGE" ]; then
        sudo apt-get install redis-server -y
      else
        sudo service redis-server start
      fi
    fi

    # Prompt to enable Redis only if the service is running
    REDIS_PID=$(pidof redis-server)
    if [ ! -z "$REDIS_PID" ]; then
      echo ""
      echo -n "Would you like to enable Redis? (Y/n): "; read -n 1 REDIS
      echo ""
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
        REDIS_CONFIG=$(grep "Use Redis for caching." $LOCALSETTINGS)
        if [ -z "$REDIS_CONFIG" ]; then
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
      fi
    fi

    # Prompt to enable XHProf
    echo ""
    echo -n "Would you like to enable XHProf? (y/N): "; read -n 1 XHPROF
    echo ""
    if [ "$XHPROF" == "Y" ]; then
      XHPROF=y
    fi
    if [ "$XHPROF" == "y" ]; then
      XHPROF_MOD=$(dpkg -l | grep php5-xhprof)
      if [ -z "$XHPROF_MOD" ]; then
        /vagrant/xhprof-install.sh
      fi
      XHPROF_PATH="/var/www/$DIR/sites/all/modules/contrib/xhprof"
      if [ ! -d "$XHPROF_PATH" ]; then
        $DRUSH dl xhprof
      fi
      $DRUSH rr
      $DRUSH en -y xhprof
      # Apply patch to expose paths.  See https://www.drupal.org/node/2354853.
      if [ ! -f "$XHPROF_PATH/xhprof-2354853-paths-d7-4.patch" ]; then
        cd $XHPROF_PATH
        wget https://www.drupal.org/files/issues/xhprof-2354853-paths-d7-4.patch
        patch -p1 < xhprof-2354853-paths-d7-4.patch
      fi
      $DRUSH vset xhprof_default_class 'XHProfRunsFile'
      $DRUSH vset xhprof_disable_admin_paths 1
      $DRUSH vset xhprof_enabled 1
      $DRUSH vset xhprof_flags_cpu 1
      $DRUSH vset xhprof_flags_memory 1
      $DRUSH vset xhprof_interval ''
    fi

    # Prompt to enable Xdebug
    XDEBUG_MOD=$(dpkg -l | grep php5-xdebug)
    if [ -z "$XDEBUG_MOD" ]; then
      echo ""
      echo -n "Would you like to enable Xdebug? (y/N): "; read -n 1 XDEBUG
      echo ""
      if [ "$XDEBUG" == "Y" ]; then
        XDEBUG=y
      fi
      if [ "$XDEBUG" == "y" ]; then
        /vagrant/xdebug-install.sh
      fi
    fi

    # Prompt to enable Stage File Proxy
    echo ""
    echo -n "Would you like to enable Stage File Proxy? (Y/n): "; read -n 1 PROXY
    echo ""
    if [ -z "$PROXY" ]; then
      PROXY=y
    fi
    if [ "$PROXY" == "Y" ]; then
      PROXY=y
    fi
    if [ "$PROXY" == "y" ]; then
      $DRUSH dl -n stage_file_proxy
      $DRUSH en -y stage_file_proxy
      DOMAIN=$(echo $($TERMINUS site hostnames list --site=$SITE --env=$ENV) | cut -d" " -f4)
      if [ ! -z "$DOMAIN" ]; then
        $DRUSH vset stage_file_proxy_hotlink 1
        if [[ ! -z "$HTTPUSER" && ! -z "$HTTPPASS" ]]; then
          $DRUSH vset stage_file_proxy_origin "https://$HTTPUSER:$HTTPPASS@$DOMAIN"
        else
          $DRUSH vset stage_file_proxy_origin "https://$DOMAIN"
        fi
      fi
    else
      cd /var/www/$DIR/sites/$MULTISITE/files
      FILES=$($TERMINUS site backups get --site=$SITE --env=$ENV --element=files --latest)
      if [ ! -z "$FILES" ]; then
        LABEL=${FILES:0:11}
        if [ "$LABEL" == "Backup URL:" ]; then
          FILES=${FILES:12}
        fi
        NEW_FILES=$DIR-files.tar.gz
        echo "Downloading latest files backup $FILES to $NEW_FILES..."
        curl -o $NEW_FILES $FILES
        tar zxvf $NEW_FILES
        cp -r files_$ENV/* .
        rm -rf files_$ENV/
        cd ..
        sudo chown -R vagrant:www-data files/
        sudo chmod -R g+w files/
      fi
    fi

    # Enable development modules
    #$DRUSH dl -n migrate migrate_extras coder devel devel_themer hacked redis simplehtmldom-7.x-1.12 stage_file_proxy
    #$DRUSH en -y migrate_extras coder devel_themer hacked redis stage_file_proxy

    # Disable unused/unwanted modules
    $DRUSH dis -y overlay

    # Disable cron
    ELYSIA=$($DRUSH pml --status=Enabled | grep elysia_cron)
    if [ ! -z "$ELYSIA" ]; then
      $DRUSH vset elysia_cron_disabled 1
    fi
    $DRUSH vset cron_safe_threshold 0

    # Restart web services
    /vagrant/restart-lemp.sh

    # Output final message
    echo ""
    echo "Make sure '192.168.33.10 $DIR.site' exists in your local hosts file and then open http://$DIR.site in your browser."
    echo "The local hosts file is located at /etc/hosts (MAC/BSD/Linux) or C:\Windows\System32\drivers\etc\hosts (Windows)."
    echo ""
  else
    echo "drush site-install failed."
  fi
else
  echo "git clone failed."
fi

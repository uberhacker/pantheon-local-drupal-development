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

# Get the environment
ENV=dev
if test $2; then
  ENV=$2
fi

# Get the Pantheon site name
DIR=""
SITE=""
if test $1; then
  SITE=$1
  DIR=$SITE-$ENV
  # Check if the site directory exists
  if [ ! -d "/var/www/$DIR" ]; then
    echo "$DIR is not a valid site directory."
    exit
  fi
else
  ROOT=$($DRUSH status root --format=list)
  if [ ! -z $ROOT ]; then
    BASE=${ROOT:0:8}
    if [ $BASE == "/var/www" ]; then
      DIR=${ROOT:9}
      END="-$ENV"
      LEN=${#END}
      SITE=${DIR:0:(-$LEN)}
    fi
  fi
fi

if [[ ! -z "$SITE" && ! -z "$DIR" ]]; then
  # Validate the environment
  $TERMINUS site environment-info --site=$SITE --env=$ENV --field=id
  if [ $? == 1 ]; then
    $TERMINUS site environments --site=$SITE
    exit
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

  # Set multisite
  MULTISITE=""
  MULTISITES=""
  DEFAULTSITE="default"
  cd /var/www/$DIR/sites
  SITES=$(echo $(ls -d */) | sed 's,/,,g')
  for SITE in $SITES; do
    if [[ "$SITE" != "all" && -f "/var/www/$DIR/sites/$SITE/settings.php" ]]; then
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
  if [ ! -f $HOME/.drush/registry_rebuild/registry_rebuild.php ]; then
    $DRUSH dl registry_rebuild -y
    $DRUSH cc drush
  fi
  if [ ! -z "$MULTISITE" ]; then
    DRUSH="$DRUSH -l $MULTISITE"
  fi

  # Download the latest database backup
  cd /var/www/$DIR
  DB=$($TERMINUS site backups get --site=$SITE --env=$ENV --element=db --latest)
  if [ ! -z "$DB" ]; then
    LABEL=${DB:0:11}
    if [ "$LABEL" == "Backup URL:" ]; then
      DB=${DB:12}
    fi
    NEW_DB="$DIR.sql"
    rm -f $NEW_DB $NEW_DB.gz
    echo "Downloading $DB to $NEW_DB ..."
    curl -o $NEW_DB.gz $DB && gunzip $NEW_DB.gz
    $DRUSH sql-drop -y
    echo "Loading $NEW_DB ..."
    $DRUSH sqlc < $NEW_DB
  fi
  # Make sure the Drupal admin user login is admin/admin
  $DRUSH sqlq "update users set name = 'admin' where uid = 1"
  $DRUSH upwd admin --password=admin
  $DRUSH rr

  # Make sure the Redis service is running
  REDIS_PID=$(pidof redis-server)
  if [ -z "$REDIS_PID" ]; then
    REDIS_PKG=$(dpkg -l | grep redis-server)
    if [ -z "$REDIS_PKG" ]; then
      sudo apt-get install redis-server -y
    else
      sudo service redis-server start
    fi
  fi

  # Prompt to enable Redis only if the service is running
  REDIS_PID=$(pidof redis-server)
  if [ ! -z "$REDIS_PID" ]; then
    REDIS_MOD=$($DRUSH pml --status=Enabled | grep redis)
    if [ -z "$REDIS_MOD" ]; then
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

else
  echo ""
  echo "Purpose: Downloads the latest database and uploads to your local database"
  echo ""
  echo "Usage: $0 [site] [env] where [site] is a"
  echo "       valid Nginx virtual host or Pantheon Site Name"
  echo "       and [env] is the environment (dev, test or live)."
  echo ""
  echo "       The default [site] is the current Drupal root"
  echo "       and the default [env] is dev."
  echo ""
fi

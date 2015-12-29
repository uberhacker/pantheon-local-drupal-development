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

# Get the Pantheon site name
SITENAME=""
if test $1; then
  SITENAME=$1
else
  ROOT=$($DRUSH status root --format=list)
  if [ ! -z $ROOT ]; then
    BASE=${ROOT:0:8}
    if [ $BASE == "/var/www" ]; then
      SITENAME=${ROOT:9}
    fi
  fi
fi

# Set the environment
ENV=dev
if test $2; then
  ENV=$2
  if [[ $2 != "dev" && $2 != "test" && $2 != "live" ]]; then
    echo "Invalid environment $ENV."
    exit
  fi
fi

if [ ! -z $SITENAME ]; then
  # Check if the site directory exists
  if [ ! -d "/var/www/$SITENAME" ]; then
    echo "$SITENAME is not a valid site."
    exit
  fi

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
  AUTHENTICATED=${WHOAMI:0:25}
  if [ "$AUTHENTICATED" != "You are authenticated as:" ]; then
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
  AUTHENTICATED=${WHOAMI:0:25}
  if [ "$AUTHENTICATED" != "You are authenticated as:" ]; then
    if [ -f $HOME/.terminus_auth ]; then
      rm -f $HOME/.terminus_auth
    fi
    exit
  fi

  # Set multisite
  MULTISITE=""
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
  if [ ! -f $HOME/.drush/registry_rebuild/registry_rebuild.php ]; then
    $DRUSH dl registry_rebuild -y
    $DRUSH cc drush
  fi
  if [ ! -z "$MULTISITE" ]; then
    DRUSH="$DRUSH -l $MULTISITE"
  fi

  # Pull the latest code changes from master
  cd /var/www/$SITENAME
  $GIT pull

  # Download the latest database backup
  DB="$ENV-$SITENAME.sql"
  rm -f $DB $DB.gz
  LATEST=$($TERMINUS site backups get --site=$SITENAME --env=dev --element=db --latest)
  if [ ! -z "$LATEST" ]; then
    LABEL=${LATEST:0:11}
    if [ "$LABEL" == "Backup URL:" ]; then
      LATEST=${LATEST:12}
    fi
    echo "Downloading the latest database backup to $DB ..."
    curl -o $DB.gz $LATEST && gunzip $DB.gz
    $DRUSH sql-drop -y
    echo "Loading $DB ..."
    $DRUSH sqlc < $DB
  fi
  # Make sure the Drupal admin user login is admin/admin
  $DRUSH sqlq "update users set name = 'admin' where uid = 1"
  $DRUSH upwd admin --password=admin
  $DRUSH rr

  # Prompt to enable Stage File Proxy
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
    DOMAIN=$(echo $($TERMINUS site hostnames list --site=$SITENAME --env=dev) | cut -d" " -f4)
    if [ ! -z "$DOMAIN" ]; then
      $DRUSH vset stage_file_proxy_hotlink 1
      if [[ ! -z "$HTTPUSER" && ! -z "$HTTPPASS" ]]; then
        $DRUSH vset stage_file_proxy_origin "https://$HTTPUSER:$HTTPPASS@$DOMAIN"
      else
        $DRUSH vset stage_file_proxy_origin "https://$DOMAIN"
      fi
    fi
  else
    echo "Downloading latest files backup to dev-$SITENAME-files.tar.gz..."
    cd /var/www/$SITENAME/sites/$MULTISITE/files
    FILES=$($TERMINUS site backups get --site=$SITENAME --env=dev --element=files --latest)
    if [ ! -z "$FILES" ]; then
      LABEL=${FILES:0:11}
      if [ "$LABEL" == "Backup URL:" ]; then
        FILES=${FILES:12}
      fi
      curl -o dev-$SITENAME-files.tar.gz $FILES
      tar zxvf dev-$SITENAME-files.tar.gz
      sudo cp -r files_dev/* .
      sudo rm -rf files_dev/
      cd ..
      sudo chown -R vagrant:www-data files/
      sudo chmod -R g+w files/
    fi
  fi
else
  echo ""
  echo "Purpose: Downloads the latest code, files and database to your local environment"
  echo ""
  echo "Usage: $0 site where site is a valid Nginx virtual host or Pantheon Site Name"
  echo ""
fi

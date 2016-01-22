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
  if [ ! -z "$ROOT" ]; then
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
  if [ ! -f $HOME/.drush/registry_rebuild/registry_rebuild.php ]; then
    $DRUSH dl registry_rebuild -y
    $DRUSH cc drush
  fi
  if [ ! -z "$MULTISITE" ]; then
    DRUSH="$DRUSH -l $MULTISITE"
  fi

  # Prompt to enable Stage File Proxy
  cd /var/www/$DIR
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
      sudo cp -r files_$ENV/* .
      sudo rm -rf files_$ENV/
      cd ..
      sudo chown -R vagrant:www-data files/
      sudo chmod -R g+w files/
    fi
  fi
else
  echo ""
  echo "Purpose: Downloads the latest files backup to your local environment"
  echo ""
  echo "Usage: $0 [site] [env] where [site] is a"
  echo "       valid Nginx virtual host or Pantheon Site Name"
  echo "       and [env] is the environment (dev, test or live)."
  echo ""
  echo "       The default [site] is the current Drupal root"
  echo "       and the default [env] is dev."
  echo ""
fi

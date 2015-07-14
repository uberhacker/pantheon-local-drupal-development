#!/bin/bash

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

SITENAME=""
if test $1; then
  SITENAME=$1
fi
PROFILE=""
if test $2; then
  PROFILE=$2
fi

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

LOGGEDIN=$(terminus auth whoami)
if [ "$LOGGEDIN" == "You are not logged in." ]; then
  if [ -f $HOME/.terminus_auth ]; then
    rm -f $HOME/.terminus_auth
  fi
  exit
fi

if [ -z "$SITENAME" ]; then
  echo ""
  echo -n "Enter the Pantheon Site Name: "; read SITENAME
  if [ -z "$SITENAME" ]; then
    exit
  fi
fi

ID=$(terminus site info --site=$SITENAME --field=id)
if [ -z "$ID" ]; then
  echo ""
  echo "$SITENAME is not a valid Pantheon Site Name."
  echo ""
  exit
fi

if [ -d /var/www/$SITENAME ]; then
  sudo rm -rf /var/www/$SITENAME
fi
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
  fi
  if [ ! -f /etc/apache2/sites-enabled/$SITENAME ]; then
    sudo a2ensite $SITENAME
    sudo service apache2 restart
  fi
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
  cd /var/www/$SITENAME
  drush site-install $PROFILE --account-name=admin --account-pass=admin --db-url=mysql://drupal:drupal@localhost/$DBNAME --site-name=$SITENAME -v -y
  if [ -d /var/www/$SITENAME/sites/all/modules ]; then
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
    sudo chown vagrant:www-data /var/www/$SITENAME/sites/default/files
    sudo chmod g+w /var/www/$SITENAME/sites/default/files
    sed -i "s/DATABASE/$DBNAME/g" /var/www/$SITENAME/sites/default/settings.php
    sed -i "s/USERNAME/drupal/g" /var/www/$SITENAME/sites/default/settings.php
    sed -i "s/PASSWORD/drupal/g" /var/www/$SITENAME/sites/default/settings.php
    DB=$(terminus site backup get --site=jouer-cosmetics --env=dev --element=database --latest)
    if [ ! -z "$DB" ]; then
      curl --compress -o dev-$SITENAME.sql.gz $DB
      gunzip dev-$SITENAME.sql.gz
      drush sqlc < dev-$SITENAME.sql
      #rm -f dev-$SITENAME.sql
    fi
    #drush dl -n migrate migrate_extras coder devel devel_themer hacked redis simplehtmldom-7.x-1.12 stage_file_proxy
    #drush en -y migrate_extras coder devel_themer hacked redis stage_file_proxy
    drush dl -n stage_file_proxy
    drush en -y stage_file_proxy
    DOMAIN=$(echo $(terminus site hostnames list --site=$SITENAME --env=dev) | cut -d" " -f4)
    if [ ! -z "$DOMAIN" ]; then
      drush vset stage_file_proxy_hotlink 1
      if [[ ! -z "$HTTPUSER" && ! -z "$HTTPPASS" ]]; then
        drush vset stage_file_proxy_origin "https://$HTTPUSER:$HTTPPASS@$DOMAIN"
      else
        drush vset stage_file_proxy_origin "https://$DOMAIN"
      fi
    fi
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

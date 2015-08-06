#!/bin/bash
if test $1; then
  if [ ! -d "/var/www/$1" ]; then
    echo "$1 is not a valid site."
    exit
  fi
  SITENAME=$1
  ENV=dev
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
  cd /var/www/$SITENAME
  DB="$ENV-$SITENAME.sql"
  rm -f $DB $DB.gz
  echo "Downloading $DB ..."
  curl --compress -o $DB.gz $(terminus site backup get --site=$SITENAME --env=$ENV --element=database --latest) && gunzip $DB.gz
  echo "Loading $DB ..."
  drush -l $MULTISITE sqlc < $DB
else
  echo ""
  echo "Purpose: Downloads the latest database and uploads to your local database"
  echo ""
  echo "Usage: $0 site where site is a valid Apache virtual host or Pantheon Site Name"
  echo ""
fi

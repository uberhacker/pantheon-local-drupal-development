#!/bin/bash
# Get the environment
ENV=dev
if test $2; then
  ENV=$2
fi

# Get the Pantheon Site Name
if test $1; then
  SITE=$1
  DIR=$SITE-$ENV
  if [ ! -d /var/www/$DIR ]; then
    echo "$DIR is not a valid site directory."
    exit
  fi
else
  ROOT=$(drush status root --format=list)
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
  if [ ! -f $HOME/.drush/registry_rebuild/registry_rebuild.php ]; then
    drush dl registry_rebuild -y
    drush cc drush
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
  cd /var/www/$DIR
  # Make sure the directory is writable by Nginx so files can be saved.
  sudo chown -R vagrant:www-data sites/$MULTISITE/files
  sudo chmod -R g+w sites/$MULTISITE/files
  # Make sure the directory is writable by Nginx so features can be exported.
  if [ -d "/var/www/$DIR/sites/$MULTISITE/features" ]; then
    sudo chown -R vagrant:www-data sites/$MULTISITE/features
    sudo chmod -R g+w sites/$MULTISITE/features
  fi
  if [ -d "/var/www/$DIR/sites/$MULTISITE/modules/features" ]; then
    sudo chown -R vagrant:www-data sites/$MULTISITE/modules/features
    sudo chmod -R g+w sites/$MULTISITE/modules/features
  fi
  if [ -d "/var/www/$DIR/sites/$MULTISITE/modules/custom/features" ]; then
    sudo chown -R vagrant:www-data sites/$MULTISITE/modules/custom/features
    sudo chmod -R g+w sites/$MULTISITE/modules/custom/features
  fi
  drush -l $MULTISITE rr
else
  echo ""
  echo "Purpose: Repairs the site database and file permissions"
  echo ""
  echo "Usage: $0 [site] [env] where [site] is a"
  echo "       valid Nginx virtual host or Pantheon Site Name"
  echo "       and [env] is the environment (dev, test or live)."
  echo ""
  echo "       The default [site] is the current Drupal root"
  echo "       and the default [env] is dev."
  echo ""
fi

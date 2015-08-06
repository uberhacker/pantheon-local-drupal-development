#!/bin/bash
if test $1; then
  SITENAME=$1
  if [ ! -d /var/www/$SITENAME ]; then
    echo "$SITENAME is not a valid site."
    exit
  fi
  if [ ! -f $HOME/.drush/registry_rebuild/registry_rebuild.php ]; then
    drush dl registry_rebuild -y
    drush cc drush
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
  cd /var/www/$SITENAME
  # Make sure the directory is writable by Apache so files can be saved.
  sudo chown -R vagrant:www-data sites/$MULTISITE/files
  sudo chmod -R g+w sites/$MULTISITE/files
  # Make sure the directory is writable by Apache so features can be exported.
  if [ -d "/var/www/$SITENAME/sites/$MULTISITE/features" ]; then
    sudo chown -R vagrant:www-data sites/$MULTISITE/features
    sudo chmod -R g+w sites/$MULTISITE/features
  fi
  if [ -d "/var/www/$SITENAME/sites/$MULTISITE/modules/features" ]; then
    sudo chown -R vagrant:www-data sites/$MULTISITE/modules/features
    sudo chmod -R g+w sites/$MULTISITE/modules/features
  fi
  if [ -d "/var/www/$SITENAME/sites/$MULTISITE/modules/custom/features" ]; then
    sudo chown -R vagrant:www-data sites/$MULTISITE/modules/custom/features
    sudo chmod -R g+w sites/$MULTISITE/modules/custom/features
  fi
  drush -l $MULTISITE rr
else
  echo ""
  echo "Purpose: Repairs the site database and file permissions"
  echo ""
  echo "Usage: $0 site where site is a valid Apache virtual host or Pantheon Site Name"
  echo ""
fi

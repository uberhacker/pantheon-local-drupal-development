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
  cd /var/www/$SITENAME
  sudo chown -R vagrant:www-data sites/default/files
  sudo chmod -R g+w sites/default/files

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
  drush -l $MULTISITE rr
else
  echo ""
  echo "Purpose: Repairs the site database and file permissions"
  echo ""
  echo "Usage: $0 site where site is a valid Apache virtual host or Pantheon Site Name"
  echo ""
fi

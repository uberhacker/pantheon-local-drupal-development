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
  drush rr
else
  echo ""
  echo "Purpose: Repairs the site database and file permissions"
  echo ""
  echo "Usage: $0 site where site is a valid Apache virtual host or Pantheon Site Name"
  echo ""
fi

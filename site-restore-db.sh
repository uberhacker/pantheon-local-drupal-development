#!/bin/bash
if test $1; then
  SITENAME=$1
  if [ ! -d /var/www/$SITENAME ]; then
    echo "$SITENAME is not a valid site."
    exit
  fi
  if [ ! -f /var/www/$SITENAME/dev-$SITENAME.sql ]; then
    echo "Database dump file dev-$SITENAME.sql does not exist."
    exit
  fi
  cd /var/www/$SITENAME
  drush sqlc < dev-$SITENAME.sql
else
  echo ""
  echo "Purpose: Restores the database back to the state of the initial site install"
  echo ""
  echo "Usage: $0 site where site is a valid Apache virtual host or Pantheon Site Name"
  echo ""
fi

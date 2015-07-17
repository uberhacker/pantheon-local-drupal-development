#!/bin/bash
if test $1; then
  SITENAME=$1
  if [ ! -d /var/www/$SITENAME ]; then
    echo "$SITENAME is not a valid site."
    exit
  fi
  TYPE=error
  if test $2; then
    TYPE=$2
  fi
  if [[ "$TYPE" != "access" && "$TYPE" != "error" ]]; then
    echo "Valid options are access or error.  The default value is error."
    exit
  fi
  CMD=tail
  if test $3; then
    CMD=$3
  fi
  if [[ "$CMD" != "less" && "$CMD" != "tail" ]]; then
    echo "Valid options are less or tail.  The default value is tail."
    exit
  fi
  sudo $CMD /var/log/apache2/$SITENAME-$TYPE.log
else
  echo ""
  echo "Purpose: Display the Apache logs for a site"
  echo ""
  echo "Usage: $0 site [access|error] [less|tail] where site is a valid Apache virtual host or Pantheon Site Name"
  echo ""
fi

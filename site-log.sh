#!/bin/bash

# Get the Pantheon site name
SITE=""
if test $1; then
  SITE=$1
fi

# Get the environment
ENV=dev
if test $2; then
  ENV=$2
fi

# Set the Drupal root directory
ROOT=$($DRUSH status root --format=list)
if [ -z $ROOT ]; then
  ROOT=/var/www/$SITE-$ENV
fi

# Validate the Drupal root directory
if [ ! -d $ROOT ]; then
  echo "The Pantheon site cannot be located."
  exit
fi

# Get the Pantheon site name from Drupal root
if [ -z $SITE ]; then
  BASE=${ROOT:0:8}
  if [ $BASE == "/var/www" ]; then
    DIR=${ROOT:9}
    END="-$ENV"
    LEN=${#END}
    SITE=${DIR:0:(-$LEN)}
  fi
fi

if [ ! -z $SITE ]; then
  TYPE=error
  if test $3; then
    TYPE=$3
  fi
  if [[ "$TYPE" != "access" && "$TYPE" != "error" ]]; then
    echo "Valid options are access or error.  The default value is error."
    exit
  fi
  CMD=tail
  if test $4; then
    CMD=$4
  fi
  if [[ "$CMD" != "less" && "$CMD" != "tail" ]]; then
    echo "Valid options are less or tail.  The default value is tail."
    exit
  fi
  sudo $CMD /var/log/nginx/$SITE-$ENV-$TYPE.log
else
  echo ""
  echo "Purpose: Display the web server logs for a site"
  echo ""
  echo "Usage: $0 [site] [env] [access|error] [less|tail] where [site]"
  echo "       is a valid Nginx virtual host or Pantheon Site Name,"
  echo "       [env] is the environment (dev, test or live),"
  echo "       [access|error] is the log type and"
  echo "       [less|tail] is the command to execute."
  echo ""
  echo "       The default [site] is the current Drupal root,"
  echo "       the default [env] is dev, the default type is error"
  echo "       and the default command is tail."
  echo ""
fi

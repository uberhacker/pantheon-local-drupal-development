#!/bin/bash
MSG1="Precondition: This script must be run as administrator in Git Bash if the operating system is Windows"
MSG2="Usage: $0 [list|add] site where site is the Nginx virtual host or Pantheon Site Name"
if test $1; then
  if [[ "$1" != "list" && "$1" != "add" ]]; then
    echo $MSG1
    echo $MSG2
  else
    if [ "$OSTYPE" == "msys" ]; then
      HOSTS=/C/Windows/System32/drivers/etc/hosts
    else
      HOSTS=/etc/hosts
    fi
    if [ "$1" == "add" ]; then
      if test $2; then
        if [ "$OSTYPE" == "msys" ]; then
          echo $'\r\n'"192.168.33.10 $2.dev" >> $HOSTS
        else
          sudo sh -c "echo '192.168.33.10 $2.dev' >> $HOSTS"
        fi
      else
        echo $MSG1
        echo $MSG2
      fi
    else
      if [ "$OSTYPE" == "msys" ]; then
        notepad $HOSTS
      else
        cat $HOSTS
      fi
    fi
  fi
else
  echo $MSG1
  echo $MSG2
fi

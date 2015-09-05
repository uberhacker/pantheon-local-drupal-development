#!/bin/bash
if [ ! -f $HOME/.ssh/rsa_id.pub ]; then
  ssh-keygen -f $HOME/.ssh/id_rsa -t rsa -N ''
  echo ""
  echo "To enable passwordless access, add the public ssh key below to your Pantheon account.  See https://pantheon.io/docs/articles/users/loading-ssh-keys/."
  echo ""
  cat $HOME/.ssh/id_rsa.pub
  echo ""
fi

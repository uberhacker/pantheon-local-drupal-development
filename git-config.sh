#!/bin/bash
GIT=$(which git)
if [ -z "$GIT" ]; then
  echo "git is not installed."
  exit
fi
echo -n "Enter your full name: "; read NAME
if [ -z "$NAME" ]; then
  exit
fi
echo -n "Enter your email address: "; read EMAIL
if [ -z "$EMAIL" ]; then
  exit
fi
git config --global user.name $NAME
git config --global user.email $EMAIL
git config --global core.autocrlf input
git config --global core.editor vim
git config --global alias.amend 'commit --amend'
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.cl 'config --list'
git config --global alias.co checkout
git config --global alias.dc 'diff --cached'
git config --global alias.ds 'diff --staged'
git config --global alias.graph 'log --graph --oneline --decorate --pretty=format:"%cn %s %cr"'
git config --global alias.last 'log -1 HEAD'
git config --global alias.rb rebase
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global color.ui true
git config --global help.autocorrect 1
git config --global push.default matching

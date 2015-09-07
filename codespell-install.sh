#!/bin/bash
if [ -d "$HOME/.codespell" ]; then
  echo "Codespell is already installed."
  exit
fi
sudo apt-get install python3 -y
git clone https://github.com/lucasdemarchi/codespell.git $HOME/.codespell
cd $HOME/.codespell
sudo make install

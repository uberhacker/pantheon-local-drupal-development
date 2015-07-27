#!/bin/bash
sudo apt-get install python3 -y
git clone https://github.com/lucasdemarchi/codespell.git ~/.codespell
cd ~/.codespell
sudo make install

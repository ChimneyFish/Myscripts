#!/bin/bash

sudo -i
sudo apt update
sudo apt upgrade
install git 
wget https://github.com/goodtft/LCD-show.git > ~/
chmod -R 755 ~/LCD-show
./~/LCD-show/LCD35-show

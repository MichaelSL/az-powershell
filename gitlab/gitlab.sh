#!/bin/bash

sudo curl -fsSL get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo groupadd docker
sudo usermod -aG docker $USER

sudo curl -L https://github.com/docker/compose/releases/download/1.20.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo systemctl enable docker

sudo curl -L https://raw.githubusercontent.com/MichaelSL/az-powershell/gitlab-on-vm/gitlab/docker-compose.yml -o docker-compose.yml

IP=$(curl -s https://api.ipify.org)
sudo sed  -i -e "s/EXTURL/$IP/g" docker-compose.yml

sudo docker-compose up -d
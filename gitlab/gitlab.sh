#!/bin/bash

sudo curl -fsSL get.docker.com -o get-docker.sh |& tee cmd-output.txt
sudo sh get-docker.sh |& tee -a cmd-output.txt

sudo groupadd docker |& tee -a cmd-output.txt
sudo usermod -aG docker $USER |& tee -a cmd-output.txt

sudo curl -L https://github.com/docker/compose/releases/download/1.20.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose |& tee -a cmd-output.txt
sudo chmod +x /usr/local/bin/docker-compose |& tee -a cmd-output.txt

sudo systemctl enable docker |& tee -a cmd-output.txt

sudo curl -L https://raw.githubusercontent.com/MichaelSL/az-powershell/gitlab-on-vm/gitlab/docker-compose.yml -o docker-compose.yml |& tee -a cmd-output.txt

IP=$(curl -s https://api.ipify.org)
sudo sed  -i -e "s/EXTURL/$IP/g" docker-compose.yml |& tee -a cmd-output.txt

sudo docker-compose up -d |& tee -a cmd-output.txt
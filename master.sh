#!/bin/bash
sudo docker swarm init --advertise-addr=10.10.10.100
sudo docker swarm join-token worker | grep docker > /vagrant/worker.sh

# Criar um volume Docker
docker volume create my_vol_cluster

# Criar uma imagem Docker
cat <<EOF > Dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl
CMD echo "Hello World"
EOF

docker build -t my_image_cluster .

# Criar e iniciar um container usando o volume e a imagem
docker run -dit --name container_cluster -v my_vol_cluster:/data my_image_cluster
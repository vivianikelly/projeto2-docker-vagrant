# Projeto para criação cluster Swarm local com Vagrant.

Este projeto visa construir um cluster com nó manager do cluster (master) e outro Worker (node01).

Para execução do projeto, foi utilizado como base o GIT https://github.com/denilsonbonatti/docker-projeto2-cluster.

Definido no arquivo Vagrantfile as instruções para configurar a máquina virtual (VM):

```
# -*- mode: ruby -*-
# vi: set ft=ruby  :

machines = {
  "master" => {"memory" => "1024", "cpu" => "1", "ip" => "100", "image" => "bento/ubuntu-22.04"},
  "node01" => {"memory" => "1024", "cpu" => "1", "ip" => "101", "image" => "bento/ubuntu-22.04"}  
}

Vagrant.configure("2") do |config|

  machines.each do |name, conf|
    config.vm.define "#{name}" do |machine|
    config.vm.boot_timeout = 600    
      machine.vm.box = "#{conf["image"]}"
      machine.vm.hostname = "#{name}"
      machine.vm.network "private_network", ip: "10.10.10.#{conf["ip"]}"
      machine.vm.provider "virtualbox" do |vb|        
        vb.customize ["modifyvm", :id, "--firmware", "bios"]
        vb.name = "#{name}"
        vb.memory = conf["memory"]
        vb.cpus = conf["cpu"]
        
      end
      machine.vm.provision "shell", path: "docker.sh"
      
      if "#{name}" == "master"
        machine.vm.provision "shell", path: "master.sh"
      else
        machine.vm.provision "shell", path: "worker.sh"
      end

    end
  end
end
```
E criar três arquivos shell: docker.sh, master.sh e worker.sh. 

No arquivo docker.sh contém a instalação do docker nas VMs.

```
#!/bin/bash
curl -fsSL https://get.docker.com | sudo bash
sudo curl -fsSL "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker vagrant
```
O arquivo worker.sh contem o comando para adicionar um nó ao cluster Docker Swarm, ou seja, registra-se com um gerente (manager) de swarm.

```
    docker swarm join --token SWMTKN-1-1bbiq6k9h6omewv6nfggxwahbg6dmjbzkcmu55kiipb3yqpjme-0t5gytra54v40oig6cyemjakq 10.10.10.100:2377
```

E o arquivo master.sh, o qual cria um Swarm no nó gerente (master). Também foi incluído a criaçãpo de volume, imagem e inicialização de um container:

```
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
```



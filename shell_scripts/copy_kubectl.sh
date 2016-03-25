#!/bin/sh

machines="vagrant@192.168.205.11 vagrant@192.168.205.21 vagrant@192.168.205.22 vagrant@192.168.205.23 vagrant@192.168.205.24 vagrant@192.168.205.25 vagrant@192.168.205.26"

for i in ${machines}
do
  echo "scp ~/Documents/caicloud-kubernetes/platforms/linux/amd64/kubectl ${i}:~/"
  scp ~/Documents/caicloud-kubernetes/platforms/linux/amd64/kubectl ${i}:~/ 
  ssh ${i} "sudo cp /home/vagrant/kubectl /usr/local/bin; ls -al /usr/local/bin"
done


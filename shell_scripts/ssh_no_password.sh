#!/bin/sh

#machines="vagrant@192.168.205.11 vagrant@192.168.205.21 vagrant@192.168.205.22 vagrant@192.168.205.23 vagrant@192.168.205.24 vagrant@192.168.205.25 vagrant@192.168.205.26"
machines="vagrant@192.168.205.11 vagrant@192.168.205.21 vagrant@192.168.205.22 vagrant@192.168.205.23"
#machines="vagrant@192.168.205.26"

for i in ${machines}
do
  echo ""
  echo "making sshing without password for ${i}"
  cat ~/.ssh/id_rsa.pub | ssh ${i} "umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys"
  echo ""
done


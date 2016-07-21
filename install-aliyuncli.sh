#!/bin/bash

# Author: keontang <ikeontang@gmail.com>

#
# aliyuncli references:
#   Installation documentation: https://help.aliyun.com/document_detail/29995.html
#   Frequently asked questions: https://help.aliyun.com/document_detail/30017.html?spm=5176.product29991.4.27.uVLL8J
#   Source code: https://github.com/aliyun/aliyun-cli

# Check if aliyuncli is installed or not
aliyuncli_bin=`which aliyuncli`

if [[ ! -z ${aliyuncli_bin} ]]; then
  # aliyuncli is already installed
  exit 0
fi

set -e

os_distro=$(grep '^NAME=' /etc/os-release | sed s'/NAME=//' | sed s'/"//g' | awk '{print $1}' | tr '[:upper:]' '[:lower:]')

# Install requires
if [[ ${os_distro} == "ubuntu" ]]; then
  sudo apt-get install -y build-essential python-dev libxml2-dev libxslt1-dev zlib1g-dev libffi-dev libssl-dev python-pip
elif [[ ${os_distro} == "centos" ]]; then
  sudo yum install -y epel-release gcc g++ kernel-devel python-simplejson openssl-devel python-devel libffi-devel python-pip
  sudo yum clean all
fi

sudo pip install pyopenssl ndg-httpsclient pyasn1

# Install aliyuncli tool
sudo pip install aliyuncli

# Install aliyun SDK
sudo pip install aliyun-python-sdk-ecs
sudo pip install aliyun-python-sdk-slb

if [[ ${os_distro} == "ubuntu" ]]; then
  cp -r /usr/local/lib/python2.7/dist-packages/aliyun* /usr/lib/python2.7/dist-packages/
fi

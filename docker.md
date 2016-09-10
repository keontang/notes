##### docker-show-repo-tags.sh  
```sh
#!/bin/sh
#
# Simple script that will display docker repository tags.
#
# Usage:
#   $ docker-show-repo-tags.sh ubuntu centos
for Repo in $* ; do
  curl -s -S "https://registry.hub.docker.com/v2/repositories/library/$Repo/tags/" | \
    sed -e 's/,/,\n/g' -e 's/\[/\[\n/g' | \
    grep '"name"' | \
    awk -F\" '{print $4;}' | \
    sort -fu | \
    sed -e "s/^/${Repo}:/"
done

curl https://registry.hub.docker.com/v2/repositories/library/ubuntu/tags | python -mjson.tool

install docker: curl -sSL https://get.docker.com/ | sh
```
##### mac pro 上使用 docker
```
$ docker-machine ls
NAME ACTIVE DRIVER STATE URL SWARM
kube-dev - virtualbox Stopped
$ docker-machine start kube-dev
(kube-dev) OUT | Starting VM...
Started machines may have new IP addresses. You may need to re-run the `docker-machine env` command.
$ docker-machine env kube-dev
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/Users/morganwu/.docker/machine/machines/kube-dev"
export DOCKER_MACHINE_NAME="kube-dev"
# Run this command to configure your shell:
# eval "$(docker-machine env kube-dev)"
$ eval "$(docker-machine env kube-dev)"
$ docker ps
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
```

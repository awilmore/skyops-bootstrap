#!/bin/bash

set -e

echo " "
echo " ************************************************************ "
echo " ***                                                      *** "
echo " ***              INSTALLING RANCHER TOOLS                *** "
echo " ***                                                      *** "
echo " ************************************************************ "
echo " "

echo " * Download and install docker-compose..."
  curl -s -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
  chmod +x /usr/local/bin/docker-compose
echo " "
echo " * docker-compose --version : `docker-compose --version`"
echo " "

echo " * Download and install rancher-compose..."
  wget -q -O /tmp/rancher-compose.tgz https://github.com/rancher/rancher-compose/releases/download/v0.9.3-rc1/rancher-compose-linux-amd64-v0.9.3-rc1.tar.gz && \
  tar -zxvf /tmp/rancher-compose.tgz -C /var/lib && \
  ln -s /var/lib/rancher-compose-*/rancher-compose /usr/local/bin/rancher-compose
echo " "
echo " * rancher-compose --version : `rancher-compose --version`"
echo " "

echo " "
echo " ************************************************************ "
echo " ***                                                      *** "
echo " ***          RANCHER TOOLS INSTALLATION COMPLETE         *** "
echo " ***                                                      *** "
echo " ************************************************************ "
echo " "

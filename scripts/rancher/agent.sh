#!/bin/bash

IMAGE="rancher/agent:v0.11.0"


##########################
# EDIT THESE VALUES...

AGENT_NAME=""         # eg. skyops-aws-ubuntu-37
AGENT_LABELS="host-type-nonprod=true&somename=somevalue"
RANCHER_LINK_URL="http://rancher.host.com/v1/scripts/CB522431BD28FA0B19B0:1464660000000:7Rntk..."

##########################


if [ -z $AGENT_NAME ]; then
  echo "error: AGENT_NAME not set (use something like 'skyops-aws-ubuntu-37'). Aborting."
  exit 1
fi

# Lookup IP
AGENT_IP=$( ifconfig | awk '/inet addr/{print substr($2,6)}' | grep '10.139' )

if [ -z $AGENT_IP ]; then
  echo "error: IP address lookup failed. Aborting."
  exit 1
fi

# Clean up
echo "Removing state..."
rm -rf /var/lib/rancher/state

# Start agent
echo "Staring Agent (IP=$AGENT_IP): $IMAGE..."

CONTID=`docker run -d \
  --privileged \
  -e CATTLE_HOST_LABELS="name=$AGENT_NAME&$AGENT_LABELS" \
  -e CATTLE_AGENT_IP=$AGENT_IP \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/rancher:/var/lib/rancher \
  $IMAGE \
  $RANCHER_LINK_URL`

echo "Tailing logs (cancel with CTRL-C)..."
sleep 1

docker logs -f $CONTID

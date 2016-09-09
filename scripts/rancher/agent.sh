#!/bin/bash

IMAGE="rancher/agent:v1.0.1"


##########################
# EDIT THESE VALUES...

AGENT_NAME=""         # eg. skyops-aws-ubuntu-37
AGENT_LABELS="host-type-somethine=true&somename=somevalue"
RANCHER_LINK_URL="http://172.31.36.x:8080/v1/scripts/E97B5D01B..."

##########################


if [ -z $AGENT_NAME ]; then
  echo "error: AGENT_NAME not set (use something like 'skyops-aws-ubuntu-37'). Aborting."
  exit 1
fi

# Lookup IP
AGENT_IP=$( ifconfig | awk '/inet addr/{print substr($2,6)}' | grep '172.31' )

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

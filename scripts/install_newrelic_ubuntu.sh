#!/bin/bash

set -e

if [ $# != 1 ]; then
  echo "usage: $0 nr_key"
  exit 1
fi

NR_KEY=$1

# Update Apt config
echo "Updating apt config..."
sudo sh -c 'echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list'

echo "Installing gpg key..."
wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -

# Install newrelic agent
echo "Installing newrelic-sysmond..."
apt-get update && apt-get install newrelic-sysmond -y

# Apply license key
echo "Applying license key to settings..."
nrsysmond-config --set license_key=$NR_KEY

# Start service
echo "Starting newrelic-sysmond service..."
/etc/init.d/newrelic-sysmond start

echo "Done."


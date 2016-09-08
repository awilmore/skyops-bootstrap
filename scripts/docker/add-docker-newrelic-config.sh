#!/bin/bash

set -e

echo "Adding newrelic to docker group..."
usermod -a -G docker newrelic

echo "Restarting newrelic..."
service newrelic-sysmond restart

echo "Done."

#!/bin/bash

# Init file for our tests.

# Test email from local network
./buildnrun.sh
echo "---------------"
sleep 3 # warm up time for docker container to be usable.
./sendmail.sh
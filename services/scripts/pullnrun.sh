#!/bin/bash

echo "-------Saving current conf and pulling--------"
git stash
git pull
git stash pop

sleep 3 
echo "------- re run --------"
./stopnrun.sh
#!/bin/bash
set -euo pipefail

sudo apt update && sudo apt upgrade

sudo apt install git ufw

#lynis check for hardening
#cd ~ && sudo rm -rf ~/lynis && mkdir lynis && git clone https://github.com/CISOfy/lynis --depth=1 && sudo chown -R 0:0 lynis && cd lynis && sudo ./lynis audit system --pentest && cd ~ && sudo rm -rf ~/lynis


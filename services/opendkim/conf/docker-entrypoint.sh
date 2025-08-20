#! /bin/bash

echo "Starting key generation for ${MYHOSTNAME}"
opendkim-genkey -D /etc/dkimkeys -d ${MYHOSTNAME} -s 2025

exec opendkim -f
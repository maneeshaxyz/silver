#! /bin/bash

echo "Starting key generation for ${MYHOSTNAME}"
opendkim-genkey -D /etc/dkimkeys -d ${MYHOSTNAME} -s 2025

chown opendkim:opendkim /etc/dkimkeys/2025.private
chmod 600 /etc/dkimkeys/2025.private

exec opendkim -f
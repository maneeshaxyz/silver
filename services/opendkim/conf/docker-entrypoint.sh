#! /bin/bash

opendkim-genkey -D /etc/dkimkeys -d ${MYHOSTNAME} -s 2025

exec opendkim -f
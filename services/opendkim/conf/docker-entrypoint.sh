#! /bin/bash

opendkim opendkim-genkey -D /etc/dkimkeys -d ${MYHOSTNAME} -s 2025

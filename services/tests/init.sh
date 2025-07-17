#! /bin/bash

mkdir certs/mail.local.test
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout certs/mail.local.test/privkey.pem \
  -out certs/mail.local.test/fullchain.pem \
  -subj "/CN=mail.local.test"
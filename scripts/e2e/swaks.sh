#!/bin/bash

TEST_EMAIL=$1
PASSWORD=$2

swaks \
        --from hi@maneesha.dev \
        --to "${TEST_EMAIL}" \
        --server localhost \
        --port 587 \
        --auth plain \
        --tls \
        --auth-user hi \
        --auth-password "${PASSWORD}" \
        --header 'Subject: Test email' \
        --body "This is a test email."
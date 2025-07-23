#!/bin/bash

# Ensure required variables are set
if [[ -z "$EMAIL_TO" ]]; then
    echo "Missing required email parameters (EMAIL_TO)"
    exit 1
fi

# Send email using mail command
echo "$EMAIL_BODY" | mail -s "$EMAIL_SUBJECT" "$EMAIL_TO"

# Show mail queue
postqueue -p

# Sleep for 20s to allow email processing
sleep 20

# Check if the email queue is empty
if postqueue -p | grep -q 'Mail queue is empty'; then
    echo "Mail queue is empty."
    echo "Email sent successfully to $EMAIL_TO"
else
    echo "Mail queue is not empty. There are pending emails."
    postqueue -p
fi

# Keep the script running for a while to allow email processing
sleep 300

#!/bin/bash
set -e  # Exit if any command fails

# Resolve script base directory (so script works from anywhere)
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "---------------"
echo "Starting all services..."
echo "---------------"

# DKIM
echo "[DKIM] Starting..."
(cd "$BASE_DIR/dkim" && ./scripts/init.sh)
echo "[DKIM] Service initialized."
echo "---------------"

# IMAP
echo "[IMAP] Starting..."
(cd "$BASE_DIR/imap" && ./scripts/init.sh)
echo "[IMAP] Service initialized."
echo "---------------"

# SMTP
echo "[SMTP] Starting..."
(cd "$BASE_DIR/smtp" && ./scripts/init.sh)
echo "[SMTP] Service initialized."
echo "---------------"

# # DB
# if [ -f "$BASE_DIR/db/scripts/init.sh" ]; then
#     echo "[DB] Starting..."
#     (cd "$BASE_DIR/db" && ./scripts/init.sh)
#     echo "[DB] Service initialized."
#     echo "---------------"
# fi

# # SPAM
# if [ -f "$BASE_DIR/spam/scripts/init.sh" ]; then
#     echo "[SPAM] Starting..."
#     (cd "$BASE_DIR/spam" && ./scripts/init.sh)
#     echo "[SPAM] Service initialized."
#     echo "---------------"
# fi

echo "✅ All available services have been started."

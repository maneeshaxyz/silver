#!/usr/bin/env python3
import sys, email, sqlite3, os
from datetime import datetime
from email.utils import parsedate_to_datetime

# Use same path as your container setup
DB_FILE = "/app/data/mails.db"

# ---------------------------
# Helper functions
# ---------------------------

def sanitize_username(username):
    return "".join(c if c.isalnum() or c == "_" else "_" for c in username)

def get_user_table_name(username):
    sanitized = sanitize_username(username)
    return f"mails_{sanitized}"

def create_user_table(conn, username):
    table_name = get_user_table_name(username)
    schema = f"""
    CREATE TABLE IF NOT EXISTS {table_name} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT,
        sender TEXT,
        recipient TEXT,
        date_sent TEXT,
        raw_message TEXT,
        flags TEXT DEFAULT '',
        folder TEXT DEFAULT 'INBOX'
    );
    """
    conn.execute(schema)

    # Track user in metadata table
    conn.execute("""
        CREATE TABLE IF NOT EXISTS user_metadata (
            username TEXT PRIMARY KEY,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.execute("INSERT OR IGNORE INTO user_metadata (username) VALUES (?)", (username,))

    return table_name

# ---------------------------
# Main script
# ---------------------------

# Read full email
raw_msg = sys.stdin.read()
msg = email.message_from_string(raw_msg)

# Envelope
sender = sys.argv[sys.argv.index("-f")+1] if "-f" in sys.argv else ""
recipient = sys.argv[-1]

# Extract username from recipient email (before @)
username = recipient.split("@")[0] if "@" in recipient else recipient

# Headers
subject = msg.get("Subject", "")
mail_from = msg.get("From", sender)
mail_to = msg.get("To", recipient)
date_header = msg.get("Date", "")

# Normalize date → RFC3339
try:
    dt = parsedate_to_datetime(date_header)
    date_sent = dt.isoformat()
except Exception:
    date_sent = datetime.utcnow().isoformat()

# Connect DB and ensure user table
conn = sqlite3.connect(DB_FILE)
table_name = create_user_table(conn, username)

# Ensure folders table exists
conn.execute("""
    CREATE TABLE IF NOT EXISTS folders (
        name TEXT PRIMARY KEY,
        delimiter TEXT DEFAULT '/',
        attributes TEXT DEFAULT ''
    )
""")
conn.execute("INSERT OR IGNORE INTO folders (name) VALUES ('INBOX'), ('Sent'), ('Drafts'), ('Trash')")

# Insert message into user's table
conn.execute(f"""
    INSERT INTO {table_name} (subject, sender, recipient, date_sent, raw_message, folder)
    VALUES (?, ?, ?, ?, ?, ?)
""", (subject, mail_from, mail_to, date_sent, raw_msg, "INBOX"))

conn.commit()
conn.close()
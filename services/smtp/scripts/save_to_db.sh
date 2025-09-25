#!/usr/bin/env python3
import sys, email, sqlite3, os
from datetime import datetime

# Use same path as your container setup
DB_FILE = "/app/data/mails.db"

# Read full email
raw_msg = sys.stdin.read()
msg = email.message_from_string(raw_msg)

# Envelope
sender = sys.argv[sys.argv.index("-f")+1] if "-f" in sys.argv else ""
recipient = sys.argv[-1]

# Headers
subject = msg.get("Subject", "")
mail_from = msg.get("From", sender)
mail_to = msg.get("To", recipient)
date_header = msg.get("Date", "")

# Normalize date → RFC3339 (same as Go code)
try:
    # Parse if valid date
    from email.utils import parsedate_to_datetime
    dt = parsedate_to_datetime(date_header)
    date_sent = dt.isoformat()
except Exception:
    date_sent = datetime.utcnow().isoformat()

# Save into SQLite with Go-compatible schema
conn = sqlite3.connect(DB_FILE)
cur = conn.cursor()
cur.execute("""
    CREATE TABLE IF NOT EXISTS mails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT,
        sender TEXT,
        recipient TEXT,
        date_sent TEXT,
        raw_message TEXT,
        flags TEXT DEFAULT '',
        folder TEXT DEFAULT 'INBOX'
    )
""")
cur.execute("""
    CREATE TABLE IF NOT EXISTS folders (
        name TEXT PRIMARY KEY,
        delimiter TEXT DEFAULT '/',
        attributes TEXT DEFAULT ''
    )
""")
cur.execute("INSERT OR IGNORE INTO folders (name) VALUES ('INBOX'), ('Sent'), ('Drafts'), ('Trash')")

cur.execute("""
    INSERT INTO mails (subject, sender, recipient, date_sent, raw_message, folder)
    VALUES (?, ?, ?, ?, ?, ?)
""", (subject, mail_from, mail_to, date_sent, raw_msg, "INBOX"))

conn.commit()
conn.close()
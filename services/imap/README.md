# Dovecot IMAP Server in Docker

This project provides a Dockerized Dovecot IMAP server based on Ubuntu 22.04, allowing you to run an IMAP email server locally for testing and development.

---

## Building and Running Your Application

If you prefer to build and run manually:

```bash
docker build -t dovecot-test .
docker run -d -p 143:143 --name dovecot-test dovecot-test
```

<!-- ## Deploying Your Application to the Cloud

If your cloud uses a different CPU architecture than your development machine (e.g., Mac M1 vs amd64), build the image for the target platform:

```bash
docker build --platform=linux/amd64 -t myapp .
```

Then push the image to your registry:

```bash
docker push myregistry.com/myapp
```

Refer to Docker's getting started guide for more details. -->

## Testing the IMAP Server with Thunderbird

To test your Dovecot IMAP server:

1. Open **Thunderbird** and add a new email account.

2. Enter the following details:
   - **Your Name:** Any display name you prefer (e.g., "Test User")
   - **Email Address:** `testuser@example.com` (or the email you set)
   - **Password:** `testpass` (default from the Dockerfile)

3. When Thunderbird cannot auto-configure, click **Manual Config**.

4. Enter these manual settings:

| Setting | Value |
|---------|-------|
| Incoming Protocol | IMAP |
| Server Hostname | localhost |
| Port | 143 |
| SSL | None |
| Authentication | Normal password |
| Username | testuser |

5. Complete the setup. Thunderbird will connect to your IMAP server running inside Docker.

6. To test new emails:
   - Create new mail files and copy them into the container's Maildir folder:

```bash
docker cp newmail1 dovecot-test:/home/testuser/Maildir/new/$(date +%s).M001234.localhost
docker exec dovecot-test chown testuser:testuser /home/testuser/Maildir/new/*
```

   - Refresh your Thunderbird inbox to see the new mail.

<!-- ## Optional Next Steps

- Enable **SSL/TLS** for secure IMAP (IMAPS on port 993).
- Add an SMTP server (e.g., Postfix) to send and receive mail.
- Configure automatic mail delivery.
- Use a webmail client for browser-based access.

Feel free to reach out if you need help with these or any other customizations!# Dovecot IMAP Server in Docker

This project provides a Dockerized Dovecot IMAP server based on Ubuntu 22.04, allowing you to run an IMAP email server locally for testing and development.

---

## Building and Running Your Application

To build and start your application, run:

```bash
docker compose up --build
```

Or, if you prefer to build and run manually:

```bash
docker build -t dovecot-test .
docker run -d -p 143:143 --name dovecot-test dovecot-test
```

## Deploying Your Application to the Cloud

If your cloud uses a different CPU architecture than your development machine (e.g., Mac M1 vs amd64), build the image for the target platform:

```bash
docker build --platform=linux/amd64 -t myapp .
```

Then push the image to your registry:

```bash
docker push myregistry.com/myapp
```

Refer to Docker's getting started guide for more details.

## Testing the IMAP Server with Thunderbird

To test your Dovecot IMAP server:

1. Open **Thunderbird** and add a new email account.

2. Enter the following details:
   - **Your Name:** Any display name you prefer (e.g., "Test User")
   - **Email Address:** `testuser@example.com` (or the email you set)
   - **Password:** `testpass` (default from the Dockerfile)

3. When Thunderbird cannot auto-configure, click **Manual Config**.

4. Enter these manual settings:

| Setting | Value |
|---------|-------|
| Incoming Protocol | IMAP |
| Server Hostname | localhost |
| Port | 143 |
| SSL | None |
| Authentication | Normal password |
| Username | testuser |

5. Complete the setup. Thunderbird will connect to your IMAP server running inside Docker.

6. To test new emails:
   - Create new mail files and copy them into the container's Maildir folder:

```bash
docker cp newmail1 dovecot-test:/home/testuser/Maildir/new/$(date +%s).M001234.localhost
docker exec dovecot-test chown testuser:testuser /home/testuser/Maildir/new/*
```

   - Refresh your Thunderbird inbox to see the new mail.

## Optional Next Steps

- Enable **SSL/TLS** for secure IMAP (IMAPS on port 993).
- Add an SMTP server (e.g., Postfix) to send and receive mail.
- Configure automatic mail delivery.
- Use a webmail client for browser-based access.
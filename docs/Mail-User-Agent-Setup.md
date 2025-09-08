# How to setup Mail User Agent (MUA) for Silver Mail Server

This guide will help you set up a Mail User Agent (MUA) to interact with your Silver Mail Server. A MUA is an application that allows users to send, receive, and manage their email.

## Thunderbird Setup

1. Download and install [Mozilla Thunderbird](https://www.thunderbird.net/).
2. Open Thunderbird and go to `Account Settings` from the menu.
3. Click on `New Account` and select `Mail Account`.
4. Enter your name, email address.
5. Click on `Continue`. Thunderbird will attempt to automatically configure the account settings.
6. If automatic configuration passes, click `Continue` and then enter your password when prompted and click `Continue`.
7. If automatic configuration fails, click on `Manual config` and enter the following settings:
    - Incoming: IMAP, `mail.yourdomain.com`, Port: 143, SSL: STARTTLS, Authentication: Normal password
    - Outgoing: SMTP, `mail.yourdomain.com`, Port: 587, SSL: STARTTLS, Authentication: Normal password
8. Click on `Re-test` to verify the settings.
9. Once verified, click on `Continue` to finish the setup.

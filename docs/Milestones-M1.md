# Milestones

The first 3 product milestones of Silver will consist of building an "Email 1.0" product.  

Email 1.0 means the functionality of email products like GMail and OutLook, as of End-of-2024. This product will be the basis of building "Email 2.0", which will have next-evolution functionality.

This is (sort of) what Copper (previous incarnation of Silver) was supposed to be.

...

|  | Description | Details/Comments | Expected Completion |
| :---: | :---- | :---- | :---- |
| **M1** | Build email 1.0 backend (and reuse existing email client)  | Deploy for LSF to use  | Jul 31, 2025   |
| **M2** | Build \<phone\#\>@phone.”email 1.0”.org | Will have a simple User Client | Oct 31, 2025 |
| **M3** | Self-hostable SaaS product with Admin Client for Email 1.0 | Robust/ enough for LK govt to use | Jan 31, 2026 |

## Detailed Deliverables for M1

*Note, May will include both LG Elections (May 6\) and Vesak (May 12-13).*

|  | Description | What we will Build | How to Test | Follow-up Questions | Expected Completion (as Fridays) |
| :---: | ----- | ----- | ----- | ----- | ----- |
| **01** | **Public Domain \+ DNS Setup** | Purchase a real domain (e.g., mail.lk) Set up A, MX, SPF, DKIM (optional), and DMARC records Issue valid TLS certificate with Let’s Encrypt  | Use DNS tools (e.g., MXToolbox) to verify DNS config  | Did the message arrive in Inbox or Spam? Do email headers look clean and correct? Any trouble with DNS propagation or TLS validation? | May 2, 2025 - We should buy the domain, *before* @Maneesha arrives |
| **02** | **Authenticated SMTP with Encrypted Delivery**  | SMTP server with LOGIN/PLAIN auth over STARTTLS Make SMTP reachable via public domain Store real email data (e.g., SQLite) One internal user can send mail using a real client (e.g., Thunderbird) | Manual: Send email using real client over TLS Unit: Validate auth flow, message parsing, storage integrity Send mail from your SMTP server to Gmail Check if mail arrives and how headers look Confirm TLS handshake and message appears in storage | Did the email client connect easily? Was setup (server, TLS, auth) straightforward? Did the message arrive and appear correctly? | May 9, 2025  |
| **03** | **Encrypted IMAP Access to Stored Mail** | Real IMAP server with user auth and STARTTLS Expose real messages from SMTP storage Client should be able to view email sent in M1.1 | Configure client to fetch email via IMAP Integration: Send → Store → Read Confirm folder structure and message integrity | Did the message show up properly in the client? Was the IMAP setup smooth? Did the client sync or behave unexpectedly? | May 9, 2025 |
| **04** | **Containerized Mail Stack for Deployment** | Dockerize SMTP, IMAP and DB Add docker-compose for local and cloud deployment Deploy to AWS EC2 instance with Docker | Run containers locally and on EC2 Test sending mail from a remote client Confirm persistence and logs across restarts | Was setup repeatable on AWS? Any problems configuring the client remotely? Would you feel confident deploying this again?What happens when we crash AWS? | May 16, 2025 |
| **05** | **Multi-User Support \+ Auth Backend** | Multi-user auth (hashed passwords, user table) Add user management via CLI or admin script Ensure strict access control in SMTP/IMAP | Manual: test with two users sending to each other Unit: test auth edge cases, invalid logins, isolation Try to access another user’s inbox (should fail) | Was adding a new user easy? Did isolation work as expected? Did one user ever see another’s mail?  | May 23, 2025 |
| **06** | **MIME \+ Attachment Handling** | Add MIME parsing for text, HTML, and attachments Store attachments securely Expose via IMAP as part of the message  | Send attachments (PDF, image) and download via client Test malformed MIME emails Unit test for MIME boundary handling  | Did attachments open properly in the client? Any errors when downloading or syncing? Any file types that failed?  | May 30, 2025 |
| **07** | **IMAP Folders and Sent Mail Handling** | Add folder support to IMAP: Inbox, Sent, Spam When user sends a message, store a copy in Sent Create Spam folder (for future use) | Send message from client and check Sent folder Move messages between folders Manual test of folder sync | Do folders appear correctly in the client? Are “Sent” messages reliably saved? Any confusion with default vs custom folders? | Jun 6, 2025 |
| **08** | **External Email Delivery** | Enable external delivery via SMTP relay or direct delivery Handle TLS, delivery status, and bounce handling | Send email to Gmail, reply back, and confirm delivery Inspect headers and check spam score Use test accounts to validate reply flow | Did external email arrive successfully? Did it go to spam? Was the reply received properly? | Jun 13, 2025 |
| **09** | **Spam Filtering \+ Throttling** | Integrate spam filtering (Rspamd or SpamAssassin) Add rate limiting per user/IP for abuse prevention | Send spammy content and check spam folder Try rate-limiting edge cases (e.g., spam flood) Confirm legitimate emails aren’t flagged | Did any real mail get marked as spam? Is rate limiting too aggressive or too weak? Would you trust the filter? | Jun 20, 2025 |
| **10** | **Web-Based Admin Panel** | Secure web dashboard (e.g., Flask or Express) User management, delivery logs, status checks Enforce HTTPS and admin auth | Add and remove users via web interface Reset passwords, monitor delivery Test access control and permissions | Is the admin UI intuitive? What would you expect to see that’s missing? Could a non-technical person use it? | Jun 27, 2025 |
| **11** | **User Privacy Tools \+ Audit Logs** | Track login/auth/access logs per user Add data export and account deletion endpoints Store logs securely and tamper-resistant  | Export account data and verify completeness Delete account and confirm all traces removed Test access log output for accuracy | Does this meet your expectations for data privacy? Was deletion or export clear and complete? Would you trust this with your own mail? | Jul 4, 2025This is the week @Aravinda is scheduled to arrive. We will need to find a smooth way of merging him.  |
| **12** | **Final Validation and End-to-End Testing** | Perform full system integration tests Harden against brute force, downgrade, MITM, relay abuse Deploy to AWS and invite real testers | Simulate real usage: multiple users, attachments, external mail Use test tools for security validation Run test matrix across clients/devices | Would you trust this system for production use? What’s missing or frustrating? What would make this 10x better? | Jul 11, 2025 |

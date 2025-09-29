## 📌 Description
<!-- Provide a clear, concise description of what this PR does. -->

- Closes #<issue-number>

---

## 🔍 Changes Made
<!-- List key changes in bullet points. -->
- 

---

## ✅ Checklist (Email System)
- [ ] Core services tested (SMTP, IMAP, mail storage, end-to-end delivery)
- [ ] Security & compliance verified (auth via Thunder IDP, TLS, DKIM/SPF/DMARC, spam/virus filtering)
- [ ] Configuration & deployment checked (configs generated, Docker/Compose updated)
- [ ] Reliability confirmed (error handling, logging, monitoring)
- [ ] Documentation & usage notes updated (README, deployment, API)

---

## 🧪 Testing Instructions
<!-- Explain how reviewers can test your changes locally. -->
1. Run `docker-compose up`
2. Send a test email using SMTP
3. Fetch the same email via IMAP client (Thunderbird, Outlook, etc.)
4. Check logs for errors/warnings

---

## 📷 Screenshots / Logs (if applicable)
<!-- Add screenshots of client tests, log snippets, etc. -->

---

## ⚠️ Notes for Reviewers
<!-- Add special notes for reviewers (e.g., schema changes, ports affected, config updates). -->
# Silver
Email 2.0 platform
## About
Silver aims to be an email platform that aims to be significantly more productive and user-friendly than current email systems.

The first phase of development, is Email 1.0 or "good old email," is a traditional email service that allows organizations to easily manage and control their email infrastructure.

## Table of contents
- [Silver](#silver)
  - [About](#about)
  - [Table of contents](#table-of-contents)
  - [Documents](#documents)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [DNS setup](#dns-setup)
    - [Setup](#setup)
    - [Configuration](#configuration)
    - [Running](#running)
    - [Final DNS setup](#final-dns-setup)
    - [Testing your setup](#testing-your-setup)
  - [Miscellaneous](#miscellaneous)

## Documents
- [Milestones](docs/Milestones-M1.md)
- [“GitHub for Everything” Playbook](docs/GitHub-For-Everything.md)
- ["Email 2.0" Vision](https://docs.google.com/document/d/1UhHqHrKbZYFzUngQCGakBcmqluxVOoHgMthrG8ySJ88/) `GoogleDoc`
- [Repo Structure - For Email Stack](https://docs.google.com/document/d/1iRFtq-M2M4U8a_87zbNJb7XHrJsIFGZJKfUYu1rlUHY) `GoogleDoc`

## Getting Started

### Prerequisites
- A server you manage
- Domain with DNS control

### DNS setup
You just bought <a>example.com</a> and want to send mail as person@example.com. You will need to add a few records to your DNS control panel.

| DNS Record | Value | What it does |
|----------|----------|----------|
| A   | Your server ip   | resolves the name of your mail server |
| MX   | mail.example.com   | specifies the mail server responsible for receiving email messages for a domain   |
| PTR(rDNS)   | mail.example.com   | tells us the name of what domain the our ip address resolves to |

### Setup
- Ensure you have [git](https://git-scm.com/downloads/linux) and [Docker Engine](https://docs.docker.com/engine/install/) installed
-  Then clone the repo and change the directory to the services folder.

```bash
git clone https://github.com/LSFLK/silver.git
cd silver/services
```

### Configuration 
- Create a .env file with your domain name.

```bash
echo "DOMAIN=example.com" > .env
```

### Running
- Ensure you are in the services folder and run 

```bash
docker compose up -d
```

### Final DNS setup

- We now need to add our authentication records [SPF,DKIM & DMARC](https://www.cloudflare.com/learning/email-security/dmarc-dkim-spf/) 

| DNS Record | Value | What it does |
|----------|----------|----------|
| SPF   | "v=spf1 ip4:<your_server_ip> ~all"  | Authorizes your server to send mail for your domain |
|  DKIM  | Our DKIM key that was generated  | Cryptographic signature to verify message integrity |
| DMARC  | "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"   | Policy for handling failed SPF/DKIM checks |

### Testing your setup

- Now that you have a working mail server, you can test your configuration using the following scripts/links.

  - [mail-tester](https://www.mail-tester.com/)
  - [mxtoolbox](https://mxtoolbox.com/SuperTool.aspx)





## Miscellaneous

- [Interesting Email Products to Emerge Recently](docs/New-Email-Products.md)
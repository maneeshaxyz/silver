# Silver
Email 2.0 platform
## About
Silver aims to be an email platform that aims to be significantly more productive and user-friendly than current email systems.

The first phase of development, is Email 1.0 or "good old email," is a traditional email service that allows organizations to easily manage, control and scale their email infrastructure to their specific needs.

## Table of contents
- [Silver](#silver)
  - [About](#about)
  - [Table of contents](#table-of-contents)
  - [Documents](#documents)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [DNS setup](#dns-setup)
    - [Server Setup](#server-setup)
      - [Configuration](#configuration)
      - [Running](#running)
    - [Final DNS setup](#final-dns-setup)
    - [Testing your setup](#testing-your-setup)
  - [Contributing](#contributing)
  - [License](#license)
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
| PTR(rDNS)   | mail.example.com   | tells us the name of what hostname the our ip address resolves to |

> [!Tip]
> PTR records usually are set through your hosting provider.

### Server Setup
- Ensure you have [git](https://git-scm.com/downloads/linux) and [Docker Engine](https://docs.docker.com/engine/install/) installed
-  Then clone the repo and change the directory to the services folder.

```bash
git clone https://github.com/LSFLK/silver.git
cd silver/services
```

#### Configuration
- Give permission to the init.sh file and run it.

```bash
chmod +x init.sh
./init.sh
```

- Enter your domain name and proceed with adding one admin user for your mail server.

#### Running
- Ensure you are in the services folder and run 

```bash
docker compose up -d
```

### Final DNS setup

- We now need to add our authentication records [SPF,DKIM & DMARC](https://www.cloudflare.com/learning/email-security/dmarc-dkim-spf/) 

| DNS Record | Value | What it does |
|----------|----------|----------|
| SPF   | "v=spf1 ip4:<your_server_ip> ~all"  | verifies that your server can send mail for your domain |
|  DKIM  | Our DKIM key that was generated  | Cryptographic signature to verify message integrity |
| DMARC  | "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"   | Policy for handling failed SPF/DKIM checks |

### Testing your setup
- Now that you have a working mail server, you can test your configuration using the following links/scripts.

  - [mail-tester](https://www.mail-tester.com/)
  - [mxtoolbox](https://mxtoolbox.com/SuperTool.aspx)

## Contributing

Thank you for wanting to contribute to our project. Please see [CONTRIBUTING.md](https://github.com/maneeshaxyz/silver/blob/main/docs/CONTRIBUTING.md) for more details.


## License 

Distributed under the Apache 2.0 License. See [LICENSE](https://github.com/LSFLK/silver/blob/main/LICENSE) for more information.

## Miscellaneous

- [Interesting Email Products to Emerge Recently](docs/New-Email-Products.md)
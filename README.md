# Silver
The Silver project aims to reinvent email and digital communication that is suitable for government scale deployment. We are looking to make it in two stages: 1.0 to just provide "regular" email and 2.0 to reinvent communication and collaboration.

## Table of contents
- [Silver](#silver)
  - [Table of contents](#table-of-contents)
  - [Documents](#documents)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [DNS setup](#dns-setup)
    - [Server Setup](#server-setup)
    - [Configuration](#configuration)
    - [Adding users](#adding-users)
    - [Testing your setup](#testing-your-setup)
  - [Software](#software)
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
You just bought <a>example.com</a> and want to send mail as person@example.com.

You will need to add a few records to your DNS control panel.

> [!Note]
> Replace example.com and your-ip-address in the below example with your domain and ip address.

| DNS Record | Name | Value |
|----------|----------|----------|
| A   | mail  | your-ip-address |
| MX   |  example.com  | mail.example.com   |
| TXT   | example.com  | "v=spf1 ip4:your-ip-address ~all"|
| TXT  | example.com  | "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"  |
| PTR   | your-ip-address | mail.example.com |

> [!Tip]
> PTR records usually are set through your hosting provider. 

### Server Setup
- Ensure you have [git](https://git-scm.com/downloads/linux) and [Docker Engine](https://docs.docker.com/engine/install/) installed
-  Clone the repository and navigate to the services folder.

```bash
git clone https://github.com/LSFLK/silver.git
cd silver/services
```

### Configuration
- Give permission to the init.sh file and run it.

```bash
chmod +x init.sh
./init.sh
```

- Enter your domain name and proceed with adding one admin user for your mail server.

- Then add the dkim value generated to your DNS records.

| DNS Record | Name | Value |
|----------|----------|----------|
| TXT   | mail._domainkey | "v=DKIM1; h=sha256; k=rsa; your-dkim-value-here" |


> [!Tip]
>  Now you should have a fully functional mail server!

### Adding users

```bash
# silver/services
./add-users.sh
```

### Testing your setup
- Now that you have a working mail server, you can test your configuration using the following links/scripts.

  - [mail-tester](https://www.mail-tester.com/)
  - [mxtoolbox](https://mxtoolbox.com/SuperTool.aspx)

## Software

Silver is built using opensource software. 

- [Postfix](https://www.postfix.org/) - handles sending and receiving mail.
- [Dovecot](https://doc.dovecot.org/2.3/) - handles the retrieval of mails.
- [Thunder](https://github.com/asgardeo/thunder) - Identity provider and user manager
- [Rspamd](https://rspamd.com/) - spam filtering system.
- [ClamAV](https://docs.clamav.net/Introduction.html) -  virus scanning system.


## Contributing

Thank you for wanting to contribute to our project. Please see [CONTRIBUTING.md](https://github.com/maneeshaxyz/silver/blob/main/docs/CONTRIBUTING.md) for more details.


## License 

Distributed under the Apache 2.0 License. See [LICENSE](https://github.com/LSFLK/silver/blob/main/LICENSE) for more information.

## Miscellaneous

- [Interesting Email Products to Emerge Recently](docs/New-Email-Products.md)

# Services
This folder contains all the services required for running your own mail server. 

## Quick Start

- Ensure your DNS records (A, MX, SPF, DKIM, DMARC) are set and valid on your nameserver.

- Ensure [git](https://git-scm.com/downloads/linux) and the [Docker Engine](https://docs.docker.com/engine/install/) are installed.

- Add your domain and email into the .env file.

```
  git clone https://github.com/Aravinda-HWK/silver
  cd silver/services
  docker compose up -d --build
```

#### For creating appplication and user in Thunder server

- Run the following command 
```bash
chmod +x ./thunder/scripts/init.sh
./thunder/scripts/init.sh
```

## Info
Each service is self-contained and meant to be stateless. This allows for nicer separation, better testing and allows for changing services if they don't fit your needs.

Each service follows the following file structure but please refer to each service's readme for any deviations.

## Service File Structure

```

services
└───servicename
│   │   DockerFile
│   │   README.Docker.md
|   └───scripts/
│   └───conf/
│       │   config_file_1.cf
│       │   ...
│       │   ...
│   ...
  docker-compose.yaml
  README.md

```


## Software
- Postfix - handles sending and receiving mail (MTA)
- Dovecot - handles the storing of mails (MDA)
- Thunder - Identity Provider(WSO2)
- Rspamd -  spam filtering system





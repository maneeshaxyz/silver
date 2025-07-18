# Test Scripts

This directory contains a set of scripts designed to build, run, and test our local email functionality in a containerized environment.

## Dependencies
- Running these tests require [Docker](https://www.docker.com/products/docker-desktop/) installed and running. 

## Quick Start

### Local setup 

### Running the tests
- To run the complete test sequence, ensure the scripts are executable and run them from the services directory:

```bash
cd services/tests
find . -type f -name "*.sh" -exec chmod +x {} \;
./scripts/init.sh
```

This will generate self signed certificates for local testing

#/bin/bash

# Provision containers for integration tests
docker-compose -f spec/docker-compose.yml build --parallel
docker-compose -f spec/docker-compose.yml up -d

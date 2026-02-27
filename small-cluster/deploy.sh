#!/bin/bash
export $(grep -v '^#' .env | xargs)
docker stack deploy --detach=true -c docker-compose.yaml cyclos

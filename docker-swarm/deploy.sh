#!/bin/bash
set -e
set -a; source .env; set +a
docker stack deploy --detach=true -c docker-compose.yaml cyclos

echo "Done. Use 'docker service logs -f cyclos_cyclos' to follow startup."
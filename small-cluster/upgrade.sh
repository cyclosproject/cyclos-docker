#!/bin/bash
export $(grep -v '^#' .env | xargs)

# Scale down to avoid running mixed versions
echo "Scaling down Cyclos service to 0 replicas..."
docker service scale cyclos_cyclos=0

# Force pull of the latest image on all nodes
echo "Updating Cyclos service to the latest image..."
docker service update --image cyclos/cyclos:${CYCLOS_VERSION} --force cyclos_cyclos

# Scale back up
echo "Scaling up Cyclos service to ${REPLICAS:-1} replicas..."
docker service scale cyclos_cyclos=${REPLICAS:-1}
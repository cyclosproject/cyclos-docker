#!/bin/bash
set -e
set -a; source .env; set +a

# Confirm before proceeding
read -p "This will stop all Cyclos replicas. Proceed? [y/N] " confirm
[[ "${confirm}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

# Scale down to avoid running mixed versions
echo "Scaling down Cyclos service to 0 replicas..."
docker service scale cyclos_cyclos=0

# Pull the latest image on this (manager) node to resolve the current digest for the tag.
# This is necessary for mutable tags (e.g. "5"): without an explicit pull, worker nodes
# may reuse a locally cached image even if the registry has a newer version under the same tag.
echo "Pulling cyclos/cyclos:${CYCLOS_VERSION} on manager node..."
docker pull cyclos/cyclos:${CYCLOS_VERSION}

# Resolve the pulled image to its digest so the service update references an immutable image.
# Workers that have a different (older) digest cached will pull the new one automatically.
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' cyclos/cyclos:${CYCLOS_VERSION})
echo "Resolved digest: ${DIGEST}"

# Update the service image to the resolved digest
echo "Updating Cyclos service image..."
docker service update --image "${DIGEST}" cyclos_cyclos

# Scale back up
echo "Scaling up Cyclos service to ${REPLICAS:-1} replicas..."
docker service scale cyclos_cyclos=${REPLICAS:-1}

echo "Done. Use 'docker service logs -f cyclos_cyclos' to follow startup."
Cyclos Docker installation
==========================

This project contains production-ready examples for deploying [Cyclos 5+](https://cyclos.org/) as a Docker image. See https://documentation.cyclos.org/current/cyclos-reference/ for details on the provided Docker image.

This applies to Cyclos version 5 onwards. Starting with 5, Docker image tags follow a two-level alias scheme: `cyclos/cyclos:5` always points to the latest 5.x.y release. `cyclos/cyclos:5.1` to the latest 5.1.x release, and so on.

This project is oriented towards distinct project scales, each corresponding to a subfolder. Carefully review the `README.md` file in each folder for specific instructions:

* `single-host`: Contains a production-ready example for small projects, using a single host, to deploy Cyclos using Docker Compose, with Traefik as reverse proxy, Cyclos and a PostgreSQL database.
* `docker-swarm`: Contains a production-ready example using Docker Swarm. It is easier to setup for bare-metal cluster deployments than Kubernetes, for example, and can easily serve a small Cyclos cluster (2 - 5 hosts). It expects an external load balancer and PostgreSQL services.
* `kubernetes`: Will be provided in the future with configurations to deploy Cyclos as a Kubernetes service.

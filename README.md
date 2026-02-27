Cyclos Docker installation
==========================

This project contains production-ready examples for deploying [Cyclos](https://cyclos.org/) as a Docker image. See https://documentation.cyclos.org/current/cyclos-reference/ for details on the provided Docker image.

This applies to Cyclos version 4.17 onwards. Starting with 4.17, Docker image tags follow a two-level alias scheme: `cyclos/cyclos:4.17` always points to the latest 4.17.x release. From version 5 onwards, Cyclos adopts semantic versioning: the tag `cyclos/cyclos:5` will point to the latest 5.x.y release, `cyclos/cyclos:5.1` to the latest 5.1.x release, and so on.

This project is oriented towards distinct project scales, each corresponding to a subfolder. Carefully review the `README.md` file in each folder for specific instructions:

* `single-host`: Contains a production-ready example for small projects, using a single host, to deploy Cyclos using Docker Compose, with Traefik as reverse proxy, Cyclos and a PostgreSQL database.
* `small-cluster`: Contains a production-ready example for medium-large projects, using a small cluster (2 - 5 hosts). It uses Docker Swarm and expects an external PostgreSQL service.

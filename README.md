Cyclos Docker installation
==========================

This project contains production-ready examples for deploying [Cyclos](https://cyclos.org/) as a Docker image. See https://documentation.cyclos.org/current/cyclos-reference/ for details on the provided Docker image.

This applies to Cyclos version `4.17` onwards. Note that major versions after `4.17` will follow semantic versioning, with the next one being `5.0.0`. Bugfix releases will be `5.0.1`, `5.0.2`, and, if minor new functionality is introduced, `5.1.0`, etc. The following major releases will be `6.0.0`, `7.0.0`, etc. Also, starting with `4.17`, the main Docker image tag will be updated on minor releases, so, for example, `cyclos/cyclos:4.17` will be an alias to the last released version in the `4.17.x` series. For future releases, this will apply on 2 levels: `cyclos/cyclos:5` will be the latest published image in the `5.x.y` version, and `5.1` will be the latest `5.1.x` version.

This project is oriented towards distinct project scales, each corresponding to a subfolder. Carefully review the `README.md` file in each folder for specific instructions:

* `single-host`: Contains a production-ready example for small projects, using a single host, to deploy Cyclos using Docker Compose, creating the frontend, Cyclos and a database.
* `small-cluster`: Contains a production-ready example for medium-large projects, using a small cluster (2 - 5 hosts). It uses Docker Swarm and expects an external PostgreSQL service.

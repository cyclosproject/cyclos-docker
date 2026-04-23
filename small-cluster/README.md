Small cluster example
=====================

This folder contains a minimal Docker Swarm example to run Cyclos (5+) in a production cluster.
This works for a small cluster (2-5) nodes. For larger clusters, Kubernetes is better suited instead.
It is assumed that the load balancer and database will be provided externally.

**Load balancer**

Most cloud providers offer managed load balancers. To work with this setup, the load balancer:

* Must support the HTTP/2 protocol. With HTTP/1 the Cyclos frontend will be quite slow;
* Must handle TLS (HTTPS connection);
* Must add the common proxy headers: `X-Forwarded-For` and `X-Forwarded-Proto`;
* Must know each of the docker swarm nodes, and distribute load among them.
  There is no need for Sticky sessions or similar 'smart' routing.

**Database**

The PostgreSQL database, it must be accessible by hostname with a user and password.
A cloud-provider managed PostgreSQL server is recommended.

If you will use a database cluster with a hot standby server (whose replication MUST be
synchronous to avoid data inconsistencies), you can configure Cyclos to perform read-only
requests to the hot standby server, reducing the load in the master server. Configuring
this is just a matter of adding to `docker-compose.yaml`:
`-Dcyclos.datasource.readOnly.dataSource.serverName=${DB_HOST_READONLY}` and setting the
`DB_HOST_READONLY` variable in your `.env` file. See
https://documentation.cyclos.org/dev/cyclos-reference/#setup-scalability-db-read-standby
for more details.

**Performance tuning**

Scaling from a single host deployment to a clustered deployment will likely require attention
on more points. See https://documentation.cyclos.org/dev/cyclos-reference/#setup-scalability
for reference. One of the mentioned points there is using the hot standby database server,
as mentioned above, but there are other points, such as deploying an OpenSearch server to
handle searches faster.

**Logging**

As Cyclos instances (replicas) will be scattered in the cluster, it also makes less sense for
storing Cyclos logs in files. For this reason, the logging is by default configured in
`docker-compose.yaml` to generate logs to the console, which is automatically collected by
Docker, and the `docker service logs -f cyclos_cyclos` will show an aggregated view of logs in
all instances. If you prefer to store logs in the database instead, configure as
https://documentation.cyclos.org/dev/cyclos-reference/#setup-adjustments-logging.

**Creating the Docker swarm cluster**

The minimum Docker Engine version is 20.10.0, however the latest LTS version is recommended.
It already includes Swarm natively.

To create a cluster, SSH into one of the nodes and type in:

```bash
docker swarm init
```

This will present a command to run in other nodes to join. Take note, as the token will never be
displayed again. Then, in other nodes, run that command. Once you have your cluster, go back to
the first node and run:

```bash
docker node ls
```

It will present something like this:

```
ID                            HOSTNAME      STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
x2loyuqtm07uizoyodlkhvs7n     cyclos2       Ready     Active                          29.2.1
iuytsaghd34kjnasapo1341sq     cyclos3       Ready     Active                          29.2.1
t9g39g9q5bdc3ub3qcw8hs32j *   cyclos1       Ready     Active         Leader           29.2.1
```

Then, copy this project, especially the `small-cluster` folder to your Leader node. Here is an example
for locally creating a tarball file and sending it via SSH:

```bash
cd <path/to>/cyclos-docker

# Compress and send the file
tar cvzf small-cluster.tar.gz small-cluster
scp -i <your-key-file> small-cluster.tar.gz <user>@<public-leader-node-ip>:

# Connect to the server and extract the file
ssh -i <your-key-file> <user>@<public-leader-node-ip>
tar xvzf small-cluster.tar.gz
```

Then you will be ready to start deploying your stack. A little bit of Docker swarm terminology:

- **Node**: A node is a physical host connected to the Swarm cluster.
- **Stack**: Is a group of services, often ran together for a complete application. In this case,
  our stack has a single service.
- **Service**: A service is a component of the stack, and points to a Docker image. You can set the
  desired number of replicas, and Swarm will do its best to have that number of replicas running.
- **Task**: A task is an instance of a service. For example, each Cyclos instance is task.
- **Overlay network**: This is a virtual network created by Swarm in which all tasks participate,
  even when running between distinct nodes. Each task has an unique IP address in this network.
- **Secret**: A secret is a sensitive information (such as passwords, API keys, etc) that shouldn't
  be plainly stored in configuration files. Docker can create a secret from a one-time input, store
  it securely, then mount it in files under running tasks.

**Running the cluster**

Once in the Leader node, make sure you are in the `small-cluster` folder. Then:

1. Copy example env and edit it to your settings:
```bash
cp .env.example .env
# Edit the .env file, for example: nano .env
```

Make sure you set `REPLICAS` to be the number of nodes in your cluster.

2. Create secrets:

At least the `db_password` secret is required. If you configure additional services, such as
storing files in an external provider, using OpenSearch, etc, you should handle the respective
secrets similarly.

Choose one of the methods below:

```bash
# Option 1: Use a temporary file
nano /tmp/db_password.txt # Write the password into the file
docker secret create db_password /tmp/db_password.txt
rm /tmp/db_password.txt # Delete the file

# Option 2: From standard input
set +o history # Temporarily disable bash history
echo "your-db-password" | docker secret create db_password -
set -o history # Re-enable bash history
```

3. Deploy the stack:

Distinct from `docker compose`, `docker stack` doesn't automatically processes the `.env` file.
For this reason, a script is provided to apply the `.env` file and start the cluster:

```bash
./deploy.sh
```

Note that this script calls the stack `cyclos`. As the service in `docker-compose.yaml` is
also defined as `cyclos`, the task name will be `cyclos_cyclos`.

4. Review the logs:

```bash
docker service logs -f cyclos_cyclos
```

The `-f` flag will lock the console and stream updates to logs. Press `Ctrl+C` to exit.

**Dynamically rescaling**

If you need to add or remove cluster nodes, you can rescale the service without needing
to stop any node. Just run:

```bash
docker service scale cyclos_cyclos=4
```

**Upgrading Cyclos**

When running in a cluster, Cyclos DO NOT support upgrading a node while others are in the old version,
because the database schema changes between versions, and that would cause errors in running instances.
So it is always required to remove the entire stack, update the version and start again.

To upgrade between major versions, always carefully inspect the release notes in https://license.cyclos.org.
Also, before upgrading, it is always recommended to backup your database.

To upgrade, SSH into your Leader node, go to the `small-cluster` directory and edit your `.env` file with the
new `CYCLOS_VERSION`. Note that minor and patch versions are published in the same tag, so, if you are set it to
`5`, it will also updated for `5.0.1`, `5.0.2`, etc, as well as `5.1.0`, `5.1.1`, etc.

Then, run the following in the Leader node, in the `small-cluster` directory:

```bash
./upgrade.sh
```

The `upgrade.sh` script does the following:

- Reads the same `.env` file for `CYCLOS_VERSION` and `REPLICAS`;
- Scales down the service to zero replicas, completely stopping the cluster;
- Forces the `cyclos/cyclos:${CYCLOS_VERSION}` image to be updated in all nodes;
- Scales back the service to the desired number of replicas. Note that if you had previously
  scaled the cluster with `docker service scale cyclos_cyclos=4` and didn't update the `REPLICAS`
  variable in `.env`, make sure it is updated before running the script.

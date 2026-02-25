Small Docker deployment for Cyclos
==================================

This is a minimal, production-ready single-host Docker Compose project for small Cyclos installations. It deploys all services to a single host, which is suitable for a quick start into production, but lacks fault tolerance (if the host is down, the service will be offline). Services deployed:

* Traefik as a load balancer, handling TLS (automatically requests and renews a Let's Encrypt certificate) and HTTP/2.
* Cyclos.
* A PostgreSQL with PostGIS database.

**Prerequisites**
- Docker version 20.10.0 with the Compose plugin installed. See https://docs.docker.com/compose/install/.
- Docker Hardened Images are used. They are free for everyone to use, but require a logging in before pulling images. You need to create a user in https://hub.docker.com/.
- A public DNS A/AAAA record pointing your domain to this host. A Let's Encrypt certificate will be requested and automatically renewed. You just need to fill in your domain name and administration email (see below).
- An optional backup (dump) of your Cyclos database. Most systems will use a local Cyclos installation to initialize the license and do the initial setup. See the step below for requirements for this file to work.
- Currently, the host architecture must be `amd64`. Cyclos provides images for `arm64`, but currently, PostGIS only provides `amd64` images. Track this issue regarding `arm64` availability: https://github.com/postgis/docker-postgis/issues/216.

**Quick setup (copy & paste in a terminal)**

1. Make sure your current directory is `single-host`:
```bash
cd single-host
```

2. Copy example env and edit it to your settings:
```bash
cp .env.example .env
# Edit the .env file, for example: nano .env
```

3. Create a file containing the database password:
```bash
touch secrets/db_password.txt
chmod 600 secrets/db_password.txt
# Edit the secrets/db_password.txt file, for example: nano secrets/db_password.txt
```

4. If you have initial SQL dump(s) for a pre-configured installation, place your `*.sql` file into `./db/init/` before starting (optional). The database will be imported on the first time the service starts. **IMPORTANT!** Either the owner of all db objects MUST be `cyclos` OR the dump MUST have been created with the `psql --no-owner --no-acl` flags, otherwise, there will be errors that the user isn't found and the database won't work. If the file isn't found, Cyclos will start with a blank database, which will require the creation of a new Cyclos license.

5. Login to dhi.io: In order to pull Docker Hardened Images, you must be authenticated. Note that the authentication expires after some minutes, so you may need this periodically if new images are pulled:

```bash
docker login dhi.io
```

If you prefer, instead of having to type in your password all the time, you can create a 'Personal access token' in https://app.docker.com/ under the 'Account settings' menu, and then login with (replacing both `your-personal-access-token` and `your-username`):

```bash
echo 'your-personal-access-token' | docker login dhi.io -u your-username --password-stdin
```

6. Pull all required images from remote repositories
```bash
docker compose pull
```

7. Start everything:
```bash
docker compose up -d
```

8. Verify Traefik logs and certificate issuance:
```bash
docker compose logs -f traefik
# Check that ACME completed and certificates are present in acme.json
```

9. Verify PostgreSQL logs:
```bash
docker compose logs -f db
```

10. Verify Cyclos logs:
```bash
docker compose logs -f cyclos
```

11. Configure the Cyclos root URL:
If you have imported the dump from a previous setup, probably the global configuration won't match your new deployment URL. Especially the new frontend, which is default for regular users, is subject to errors when the configured URL doesn't match the one used for access. To fix this, login to `https://your-domain.com/global` with a global administrator, and in System > System configuration > Configurations, in the global default configuration, set the correct value for Main URL.

**Backing up the database**
You should periodically backup the database to an external server to avoid data loss in case the host machine is damaged / lost. To create a database dump, run the following:

```bash
docker compose exec db pg_dump -U cyclos -d cyclos > cyclos-$(date +%F).sql
```

You can change the filename (the portion after `>`). In this example, it will create a file with the date pattern, in the current path.

**Upgrading Cyclos**
- To upgrade between major versions, always carefully inspect the release notes in https://license.cyclos.org
- Also, before upgrading, it is always recommended to backup your database (as described above)
- Edit your `.env` file and set the `CYCLOS_VERSION` variable. Note that updated versions are pushed in Docker under the generic tag. For example: tag `4.17` is updated on versions `4.17.1`, `4.17.2`, etc. Also, major versions like `5` are also updated for `5.0.1`, `5.0.2`, etc, as well as `5.1.0`, `5.1.1`, etc.
- Either case (updating to a new minor version under the same symbolic tag or to a major version), run the following:
```bash
# fetch new image
docker compose pull cyclos

# recreate/start cyclos only (do not restart db/traefik)
docker compose up -d --no-deps --no-build --force-recreate cyclos
```

**Where logs and data live on the host**
- Cyclos logs: `cyclos/logs`
- Tomcat logs inside Cyclos: `cyclos/tomcat-logs`
- Postgres data: `db/data/pgdata`
- Traefik ACME storage: `traefik/acme.json`

Note that these folders / files will probably be owned by different users (the ones running on each container).
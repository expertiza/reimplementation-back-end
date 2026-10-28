# Expertiza Reimplementation Back-End

This repository contains the Ruby on Rails back-end for the Expertiza reimplementation project.

The application uses Docker Compose to simplify local setup and provide separate development and production configurations.

The Docker setup supports:

- Separate development and production profiles
- Local MySQL for development and testing
- External database connectivity for production
- Automatic development database initialization
- Redis persistence and service health checks
- Container log rotation
- Non-root application execution
- RSpec testing inside Docker containers

---

## 1. Quick Start — Local Development


### Prerequisites

Make sure the following are installed:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (running)
- Git

Ruby, Bundler, and MySQL do not need to be installed separately on your computer for Docker-based development.

### Clone the Repository

```bash
git clone https://github.com/expertiza/reimplementation-back-end.git
cd reimplementation-back-end
```

### Configure Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Open `.env` and replace the placeholder passwords and other configuration values with appropriate local values.

The development database settings should follow this structure:

```dotenv
RAILS_ENV=development

DATABASE_URL=mysql2://dev:change_me@db:3306/reimplementation_development
TEST_DATABASE_URL=mysql2://dev:change_me@db:3306/reimplementation_test

MYSQL_USER=dev
MYSQL_PASSWORD=change_me
MYSQL_ROOT_PASSWORD=change_me
MYSQL_DATABASE=reimplementation_development
```

Replace `change_me` with your chosen local credentials. The password in both database URLs must match `MYSQL_PASSWORD`. If the password contains URL-special characters, URL-encode it in the connection URLs.


`CACHE_STORE` is passed to the Redis cache configuration in `config/application.rb`. Within Docker Compose, the Redis connection URL is `redis://redis:6380/0`.

Development currently uses `:null_store` or `:memory_store` instead of Redis caching. The existing `:redis_store` adapter could not be loaded in the current application image, so Redis-backed Rails caching requires a separate configuration fix and validation before production use.


**Do not commit `.env` to Git.** It contains environment-specific credentials.

### Start the Development Environment

```bash
docker compose --profile dev up -d --build
```

This builds the application image and starts the development services.

On a fresh MySQL volume, the database initialization process creates the required development and test databases.

### Verify the Services

```bash
docker compose --profile dev ps
```

The expected services are:

| Service | Description |
|---|---|
| `app` | Ruby on Rails back-end |
| `db` | Local MySQL database |
| `redis` | Redis service |

MySQL and Redis should report healthy status when their health checks have completed.

### Access the Application

Open:

http://localhost:3002

If the application is not responding, inspect its logs:

```bash
docker compose --profile dev logs -f app
```

---

## 2. Development Environment

### Technology Stack

The Docker configuration uses the following components.
Refer to the configuration files for their current versions.

| Component | Version / Configuration |
|---|---|
| Ruby | Defined in `Dockerfile` |
| Bundler | Defined in `Dockerfile` and `Gemfile.lock` |
| MySQL | Defined in `docker-compose.yml` |
| Redis | Defined in `docker-compose.yml` |
| Application host port | `3002` |
| MySQL host port | `3307` (localhost only) |

Application dependencies are installed into the Docker image during the build process.

### Development Startup Behavior

The development profile starts three services:

- `app` — Rails application
- `db` — MySQL database
- `redis` — Redis service

Docker Compose uses health checks to wait for MySQL and Redis to become ready before starting the application.

The startup script first checks the installed Ruby dependencies:

```bash
bundle check || bundle install || exit 1
```

This avoids reinstalling dependencies unnecessarily.

It then prepares the development database using:

```bash
bundle exec rails db:prepare
```

`db:prepare` handles the initial database setup and pending migrations. On a fresh database, it also loads the configured seed data.

On subsequent starts, an already prepared database is not unnecessarily reseeded.

### Useful Development Commands

**Start or rebuild the environment:**

```bash
docker compose --profile dev up -d --build
```

**Check container status:**

```bash
docker compose --profile dev ps
```

**View application logs:**

```bash
docker compose --profile dev logs -f app
```

**Access the application container:**

```bash
docker compose --profile dev exec app bash
```

**Stop development containers:**

```bash
docker compose --profile dev down
```

A normal `down` preserves the named MySQL and Redis volumes.

**Important:** Do not use `docker compose down -v` unless you intentionally want to remove the development database and Redis volumes. Removing volumes can permanently delete local data.

---

## 3. Database Configuration

### Database Naming Convention

The project follows the `reimplementation_<environment>` naming convention.

| Environment | Database name |
|---|---|
| Development | `reimplementation_development` |
| Test | `reimplementation_test` |
| Production | Externally configured production database |

### How Development Databases Are Created

The development Docker Compose configuration passes `MYSQL_DATABASE` to the official MySQL container.

```dotenv
MYSQL_DATABASE=reimplementation_development
```

On the initial startup of a fresh MySQL volume, the MySQL image automatically creates this development database and grants the configured `MYSQL_USER` access to it.

The additional file:

```text
db/init_databases.sh
```

creates `reimplementation_test`, if necessary, and grants the configured application user the required database privileges.

The initialization script replaces the earlier `db/init_databases.sql` file.

**These MySQL initialization operations run when a fresh database volume is initialized.** Changing `MYSQL_DATABASE` later does not automatically rename databases in an existing volume.

### Rails Database Connections

The application uses explicit environment-specific connection URLs.

**Development:**

```dotenv
DATABASE_URL=mysql2://dev:change_me@db:3306/reimplementation_development
```

**Testing:**

```dotenv
TEST_DATABASE_URL=mysql2://dev:change_me@db:3306/reimplementation_test
```

The Rails database configuration reads these URLs directly instead of modifying the database name using string replacement.

This makes the environment-specific database connections easier to understand and configure.

### Database Hostnames and Ports

When the application runs inside Docker:

- MySQL hostname: `db`
- MySQL internal port: `3306`

When accessing MySQL from the host computer:

- Hostname: `localhost`
- Port: `3307`

The application containers should use `db:3306`, not `localhost:3307`.

### Database Persistence

MySQL stores its data in a named Docker volume.

This preserves the database across ordinary container restarts and recreation.

The development database can also support database migration and anonymization testing, which should never be performed directly against the production database without appropriate safeguards.

---

## 4. Running RSpec Tests

RSpec tests can be executed using the development Docker profile.

First, ensure the development database and Redis are running:

```bash
docker compose --profile dev up -d
```

Run the full test suite in a separate application container:

```bash
docker compose --profile dev run --rm \
  -e RAILS_ENV=test \
  app bundle exec rspec
```

The test environment uses `TEST_DATABASE_URL` from the application configuration.

The startup script prepares the test database and skips automatic development-data seeding in test mode.

This helps keep the test environment separate from the development database.

### Run a Specific Test File

For example:

```bash
docker compose --profile dev run --rm \
  -e RAILS_ENV=test \
  app bundle exec rspec spec/models/user_spec.rb
```

Replace the example spec path with the desired test file.

### Test Configuration in GitHub Actions

The CI workflow configures a dedicated MySQL test database and supplies `TEST_DATABASE_URL` for RSpec execution.

Changes should pass the applicable automated tests before being merged.

### Previously Verified Test Results

During validation of the Docker improvements after incorporating upstream changes, the RSpec suite completed with:

- 951 examples
- 0 failures
- 2 pending
- 69.57% code coverage

These are recorded validation results, not a guarantee of results for future commits.

---

## 5. Production Environment

### Production Profile

The production configuration is separate from the development environment.

The production profile defines:

| Service | Description |
|---|---|
| `app-prod` | Rails application configured for production |
| `redis` | Redis service |

**The production profile does not start a local MySQL database.**

This follows the deployment architecture in which the production database is hosted separately.

### Production Database Connection

The production deployment must provide:

```dotenv
PROD_DATABASE_URL=mysql2://user:password@external-host:3306/database_name
```

This is only an illustrative example. Actual production connection information and credentials must be supplied securely through the deployment environment.

Docker Compose maps `PROD_DATABASE_URL` to the application's `DATABASE_URL`.

### Production Startup Behavior

Unlike development, the production startup script does not automatically execute:

```bash
rails db:create
rails db:migrate
rails db:seed
```

Database migrations and other production database operations must be managed separately through an approved deployment process.

The application relies on the gems installed during the Docker image build rather than running Bundler installation at production startup.

### Verify Production Services

Without starting the production containers, inspect the configured services:

```bash
docker compose --profile prod config --services
```

Expected:

```text
redis
app-prod
```

The `db` service should not appear.

### Validate the Production Configuration

```bash
docker compose --profile prod config --quiet
```

### Production Entry Point — Local Dry Run

The production startup behavior can be checked without connecting to a real production database:

```bash
docker compose --profile prod run --rm --no-deps \
  -e DATABASE_URL=mysql2://demo:demo@127.0.0.1:3306/demo \
  app-prod /bin/echo "Production entrypoint passed"
```

This checks the entrypoint logic without launching the Rails server.

Expected output includes:

```text
Production environment detected.
Skipping automatic database creation, migration, and seeding.
Production entrypoint passed
```

**Important:** This is a startup-script validation, not a complete production deployment test.

A real production deployment additionally requires the correct external database, Rails secrets, networking, infrastructure configuration, and operational validation.

---

## 6. Docker Security

### Non-Root Application Execution

The Dockerfile creates a dedicated application user named `rails`.

The application runs with UID 1000 instead of running as root.

This reduces the privileges available to the Rails process inside the container.

The Docker image also configures writable runtime directories for application logs, temporary files, storage, and installed gems.

### Verify the Container User

For development:

```bash
docker compose --profile dev run --rm --no-deps \
  --entrypoint id app
```

For production:

```bash
docker compose --profile prod run --rm --no-deps \
  --entrypoint id app-prod
```

Expected output resembles:

```text
uid=1000(rails) gid=1000(rails) groups=1000(rails)
```

The non-root configuration has been validated locally for development and production Docker images.

File permissions may still require attention on different host operating systems, particularly when using bind mounts.

### Environment and Secret Handling

Sensitive credentials should be stored in local environment files or a suitable deployment secret-management mechanism.

The `.env` file must not be committed to Git.

The Docker build context excludes configured sensitive files through `.dockerignore`.

Production credentials should not be embedded directly into the Docker image or committed configuration files.

---

## 7. Service Health Checks

Docker Compose defines health checks to determine whether services are responsive.

### MySQL

The MySQL service uses:

```bash
mysqladmin ping
```

The development application waits for MySQL to become healthy before starting.

### Redis

The Redis service uses:

```bash
redis-cli -p 6380 ping
```

Redis is expected to respond with:

```text
PONG
```

The application also waits for Redis to become healthy.

These checks reduce startup failures caused by dependent services not being ready.

---

## 8. Redis Persistence

Redis is configured with append-only persistence.

Its data is stored in a named Docker volume mounted at:

```text
/data
```

This allows Redis to retain persisted data across ordinary container restarts.

Redis is used internally by the application and is not exposed through a host port in the current Docker Compose configuration.

The configured Redis service listens on port `6380` inside the Docker network.

---

## 9. Logging

Docker Compose uses the `json-file` logging driver with log rotation.

The configured limits are:

| Setting | Value |
|---|---|
| Maximum size per log file | `10m` |
| Maximum retained files | `3` |

These settings help prevent container logs from growing indefinitely.

View logs using:

```bash
docker compose --profile dev logs -f app
```

To view MySQL logs:

```bash
docker compose --profile dev logs db
```

To view Redis logs:

```bash
docker compose --profile dev logs redis
```

---

## 10. Docker Networking

The Docker Compose configuration defines two networks:

| Network | Purpose |
|---|---|
| `public` | Application-facing communication |
| `private` | Communication between application services |

The Rails application connects to the appropriate networks, while MySQL and Redis communicate through the private network.

Redis is not published to a host port.

The development MySQL service is accessible from the host through `127.0.0.1:3307`. Binding to localhost allows local database tools to connect without exposing MySQL on all host network interfaces.

These network definitions organize service communication but are not, by themselves, a complete production network-security policy.

---

## 11. Troubleshooting

### Check Running Containers

```bash
docker compose --profile dev ps
```

### View Application Logs

```bash
docker compose --profile dev logs app
```

### View Database Logs

```bash
docker compose --profile dev logs db
```

### View Redis Logs

```bash
docker compose --profile dev logs redis
```

### Validate Docker Compose Configuration

```bash
docker compose --profile dev config --quiet
```

### Rebuild After Application Changes

```bash
docker compose --profile dev up -d --build
```

### Clean Up Unused Docker Images

Docker may retain unused images after rebuilding the application.

To remove dangling Docker images:

```bash
docker image prune
```

This removes dangling images across Docker, not just Expertiza. It does not remove the named MySQL or Redis volumes.

Avoid using `docker image prune -a` unless you understand which additional unused images will be removed.

### Database Connection Errors

If Rails cannot connect to MySQL:

1. Confirm that the MySQL container is running and healthy.
2. Verify `MYSQL_USER`, `MYSQL_PASSWORD`, and `MYSQL_DATABASE` in `.env`.
3. Ensure `DATABASE_URL` uses `db:3306`.
4. Ensure the password in `DATABASE_URL` matches `MYSQL_PASSWORD`.
5. Check the MySQL logs for authentication or permission errors.

For test database errors, check `TEST_DATABASE_URL` separately.

### Database Name Mismatch

The expected local database names are:

```text
reimplementation_development
reimplementation_test
```

If MYSQL_DATABASE is changed after the MySQL volume has already been initialized, Docker will not automatically create the renamed database or update the existing user's permissions.

For existing development environments, the new database may need to be created manually and the application user granted access. Fresh installations using the updated configuration will initialize the databases automatically.

Do not delete existing Docker volumes just to resolve a database naming issue, as this may result in data loss.

### Redis Connection Problems

Check the Redis service:

```bash
docker compose --profile dev ps
```

Inspect Redis logs:

```bash
docker compose --profile dev logs redis
```

You can also test the Redis server:

```bash
docker compose --profile dev exec redis \
  redis-cli -p 6380 ping
```

Expected:

```text
PONG
```

### Port Conflicts

The development and production application services both publish host port `3002`, so they cannot run simultaneously with their default port mappings.

Two separate local checkouts of Expertiza can also cause port conflicts, even if they use different Docker Compose project names.

For example, two development environments cannot both bind to `localhost:3002` or `127.0.0.1:3307`.

If a port is already occupied, stop the conflicting environment or update the host-port mapping for one of the installations.

Redis is not exposed through a host port and communicates internally through the Docker network.

### View Enabled Services

Development:

```bash
docker compose --profile dev config --services
```

Production:

```bash
docker compose --profile prod config --services
```

### Important: Preserving Database Data

To stop the environment while keeping the named volumes:

```bash
docker compose --profile dev down
```

Avoid:

```bash
docker compose --profile dev down -v
```

unless you intentionally want to remove the Compose-managed volumes.

---

## 12. Notes for Contributors

- Use the `dev` profile for local development and testing.
- Use the `prod` profile only in an appropriately configured deployment environment.
- Follow the `reimplementation_<environment>` database naming convention.
- Keep `DATABASE_URL` and `TEST_DATABASE_URL` configured for their respective environments.
- Do not commit `.env` files or real credentials.
- Use fresh, isolated database volumes when validating initial database setup.
- Avoid resetting existing development volumes without backing up important data.
- Production database migrations should be managed separately from application startup.
- Run relevant RSpec tests before submitting changes.
- Validate Docker Compose configuration after modifying services or environment variables.
- Keep Docker images and runtime configuration free of unnecessary privileges and embedded secrets.

For code contributions, create a branch and submit a pull request to the official Expertiza repository.

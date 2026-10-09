# Expertiza Reimplementation Back-End

This repository contains the Ruby on Rails back-end for the Expertiza reimplementation project.

The application uses Docker Compose to simplify environment setup and provide consistent development and deployment configurations.

## Development Environment

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- Git
- Access to this repository

The application currently uses:

- Ruby 3.4.5
- Bundler 2.4.14
- MySQL 8.4
- Redis

Ruby and application dependencies are installed inside the Docker image, so a separate local Ruby installation is not required for Docker-based development.

### Clone the Repository

```bash
git clone https://github.com/expertiza/reimplementation-back-end.git
cd reimplementation-back-end
```

### Environment Configuration

Create your local environment configuration by copying the provided example file:

```bash
cp .env.example .env
```

Update `.env` with the required values.

The development environment uses the following variables:

| Variable | Purpose |
|---|---|
| `RAILS_ENV` | Rails environment, typically `development` |
| `DATABASE_URL` | Development database connection URL |
| `TEST_DATABASE_URL` | Test database connection URL |
| `CACHE_STORE` | Rails cache configuration |
| `MYSQL_USER` | Username for the local MySQL container |
| `MYSQL_PASSWORD` | Password for the local MySQL user |
| `MYSQL_ROOT_PASSWORD` | Root password for the local MySQL container |

For development, database URLs should reference the Docker Compose service hostname `db` and MySQL's internal port `3306`, rather than `localhost`.

Make sure the database credentials in the connection URLs match the local MySQL configuration.

**Important:** The `.env` file may contain sensitive credentials and must not be committed to Git. Production database credentials must also be supplied securely and never committed to the repository.

## Docker Compose Profiles

The application supports separate development and production Docker Compose profiles.

These profiles determine whether the application starts a local database container or connects to an external database server.

### Development Profile

The development profile starts the following services:

| Service | Description |
|---|---|
| `app` | Ruby on Rails back-end |
| `db` | Local MySQL 8.4 database |
| `redis` | Redis service |

The development environment uses Docker Compose to manage the local database. It also supports development and testing of database anonymization functionality.

#### Start the Development Environment

```bash
docker compose --profile dev up -d --build
```

This builds the application image and starts the development services.

The application waits for the database and Redis health checks before starting.

The development startup script also performs database creation, migrations, and seeding.

#### Check Running Services

```bash
docker compose --profile dev ps
```

The expected services are:

- `app`
- `db`
- `redis`

#### Access the Application

Once the application has started, open:

http://localhost:3002

#### View Application Logs

```bash
docker compose --profile dev logs -f app
```

#### Access the Application Container

```bash
docker compose --profile dev exec app bash
```

#### Stop the Development Environment

```bash
docker compose --profile dev down
```

This stops and removes the Compose containers while preserving named database and Redis volumes.

### Production Profile

The production profile is configured differently from development.

In production, the database runs on a separate server rather than inside the Docker Compose stack.

The production profile currently defines:

| Service | Description |
|---|---|
| `app-prod` | Production Rails application |
| `redis` | Redis service |

**A local MySQL container is not started in the production profile.**

The application connects to an existing external database using `PROD_DATABASE_URL`, which is mapped to the application's `DATABASE_URL` environment variable.

Production database credentials must be supplied securely by the deployment environment.

#### Production Startup Behavior

Unlike development, the production startup script does not automatically execute:

- `db:create`
- `db:migrate`
- `db:seed`

Production database migrations must be performed separately through an approved deployment process.

The production application uses the dependencies installed in the Docker image rather than running Bundler installation during startup.

#### Validate the Production Configuration

To inspect which services belong to the production profile without starting them:

```bash
docker compose --profile prod config --services
```

Expected services:

```text
redis
app-prod
```

The `db` service should not appear.

To validate the Compose configuration:

```bash
docker compose --profile prod config --quiet
```

The production profile should only be started after the external database connection, Rails secrets, and other required deployment settings have been configured and validated.

The presence of a production Compose profile does not, by itself, mean the configuration is ready for deployment to a production server.

## Running Tests in Docker

RSpec tests can be executed inside the development application container.

Start the development environment first:

```bash
docker compose --profile dev up -d
```

Then run the test suite against the test database:

```bash
docker compose --profile dev exec app sh -lc \
  'RAILS_ENV=test DATABASE_URL="$TEST_DATABASE_URL" bundle exec rspec'
```

This explicitly selects the Rails test environment and the configured test database.

Avoid running the test suite without selecting the correct database, since it may otherwise use the development database connection.

## Database Configuration

### Development Database

The development profile runs MySQL 8.4 as a Docker Compose service.

- Docker Compose hostname: `db`
- Internal MySQL port: `3306`
- Host port: `3307`

The MySQL data is stored in a named Docker volume so that it persists across normal container restarts.

The local development database is also intended to support database refresh and anonymization work.

Database anonymization and refresh operations should be tested in the development environment, not directly against the production database.

### Production Database

The production database is hosted on a separate server.

The production application accesses it using an externally supplied database connection URL.

The production Compose profile does not start or manage a local MySQL container.

## Service Health Checks

Docker Compose uses health checks to verify that dependent services are ready.

### MySQL

The MySQL health check uses `mysqladmin ping` to check database availability.

The development application waits until MySQL is reported healthy before startup.

### Redis

Redis uses a `redis-cli` health check.

The application waits until Redis is healthy before startup.

These checks help prevent the Rails application from starting before its dependencies are ready.

## Logging

Docker Compose configures log rotation for container logs using the `json-file` logging driver.

Each log file is limited to:

- Maximum file size: `10m`
- Maximum retained files: `3`

This prevents Docker container logs from growing indefinitely.

## Docker Networking

The Compose configuration defines two networks:

- `public` — used by the application for externally accessible communication
- `private` — used for communication between application services

MySQL and Redis communicate with the application through the private network.

Redis is not exposed through a host port.

The development MySQL container currently exposes port `3307` on the host for local database access.

## Troubleshooting

### Check Container Status

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

### Rebuild the Application Image

If Dockerfile or dependency changes require a rebuild:

```bash
docker compose --profile dev up -d --build
```

### Validate the Compose File

```bash
docker compose --profile dev config --quiet
```

### Verify Active Services

Development:

```bash
docker compose --profile dev config --services
```

Production:

```bash
docker compose --profile prod config --services
```

Do not run both application profiles simultaneously using the same host port, since `app` and `app-prod` are both configured to use port `3002`.

## Notes for Contributors

- Use the development profile for local development, testing, and database anonymization work.
- Do not commit `.env` or real database credentials.
- Ensure local environment files are excluded from Docker build contexts using `.dockerignore`.
- Avoid committing generated database schema changes unless they are associated with intentional database changes.
- Production database migrations should be managed separately from application startup.
- Validate Docker Compose configuration and run relevant tests before submitting changes.

For project changes, create a branch and submit a pull request to the official Expertiza repository.

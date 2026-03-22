# Expertiza Backend Re-Implementation

Rails API backend for the Expertiza reimplementation project.

## Stack

- Ruby `3.4.5`
- Rails `8.0`
- MySQL `8.0`
- Redis
- Docker Compose

## Run With Docker

### Prerequisites

- Docker Desktop installed and running
- Docker Compose available as `docker compose`

### Start the app

```bash
docker compose up --build
```

This starts:

- `app` on `http://localhost:3002`
- MySQL on host port `3307`
- Redis on host port `6380`

On startup the app container will:

1. wait for MySQL to become healthy
2. run `bin/rails db:create` and `bin/rails db:migrate`
3. start Rails on port `3002`

The database is not seeded by default. To seed it once during startup:

```bash
SEED_DB=true docker compose up --build
```

Use seeding carefully: the current seed file is sample-data oriented and is not intended to run on every restart.

## Database Access

### App database settings inside Docker

- host: `db`
- port: `3306`
- username: `root`
- password: `expertiza`
- development database: `reimplementation_development`
- test database: `reimplementation_test`
- production database: `reimplementation_production`

### Connect from the host machine

```bash
mysql -h 127.0.0.1 -P 3307 -u root -pexpertiza reimplementation_development
```

### Connect through the container

```bash
docker compose exec db mysql -uroot -pexpertiza reimplementation_development
```

### Useful database commands

```bash
docker compose exec app bin/rails db:create
docker compose exec app bin/rails db:migrate
docker compose exec app bin/rails db:seed
docker compose exec app bin/rails dbconsole
```

## Notes

- MySQL data is persisted in the `expertiza-mysql` Docker volume.
- Redis data is persisted in the `expertiza-redis` Docker volume.
- If you run Rails outside Docker, point it at the Dockerized MySQL instance with `DB_HOST=127.0.0.1` and `DB_PORT=3307`.

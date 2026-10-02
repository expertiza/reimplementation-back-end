# Expertiza Backend Re-Implementation

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version - 3.4.5

## Development Environment

### Prerequisites
- Verify that [Docker Desktop](https://www.docker.com/products/docker-desktop/) is installed and running.


### Video Tutorial

<a href="http://www.youtube.com/watch?feature=player_embedded&v=BHniRaZ0_JE
" target="_blank"><img src="http://img.youtube.com/vi/BHniRaZ0_JE/maxresdefault.jpg" 
alt="IMAGE ALT TEXT HERE" width="560" height="315" border="10" /></a>

### Environment Configuration

Copy the example environment file before starting the containers:

```bash
cp .env.example .env
```

Update the database credentials and other local configuration values in `.env` as needed.

The `.env` file is ignored by Git and should not be committed.

### Running tests in Docker

The Docker container uses the development environment by default.

To run RSpec against the test database, use:

```bash
docker compose exec app sh -lc 'RAILS_ENV=test DATABASE_URL="$TEST_DATABASE_URL" bundle exec rspec'
```

This is safer than just:

```bash
docker compose exec app bundle exec rspec
```

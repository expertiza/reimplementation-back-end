# Expertiza Backend Re-Implementation

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version - 3.4.5

## Development Environment

### Prerequisites
- Verify that [Docker Desktop](https://www.docker.com/products/docker-desktop/) is installed and running.
- [Download](https://www.jetbrains.com/ruby/download/) RubyMine
- Make sure that the Docker plugin [is enabled](https://www.jetbrains.com/help/ruby/docker.html#enable_docker).


### Instructions
Tutorial: [Docker Compose as a remote interpreter](https://www.jetbrains.com/help/ruby/using-docker-compose-as-a-remote-interpreter.html)

### Video Tutorial

<a href="http://www.youtube.com/watch?feature=player_embedded&v=BHniRaZ0_JE
" target="_blank"><img src="http://img.youtube.com/vi/BHniRaZ0_JE/maxresdefault.jpg" 
alt="IMAGE ALT TEXT HERE" width="560" height="315" border="10" /></a>

### Database Credentials
- username: root
- password: expertiza

## Legacy Expertiza Data Migration

The repository includes a repeatable procedure for loading the historical
anonymized Expertiza data set (the ~700 MB dump in `anon_db/`, old Expertiza
schema) into the development database. It translates the dump onto the
reimplementation schema through the guarded 2026 bridge + convergence
migrations, so the development database ends up in the canonical schema shape.

> WARNING: The procedure **deletes the current development database contents**
> (Docker volume reset) and replaces them with the legacy data.

The full runbook (script usage, manual steps, verification, caveats) lives in
[docs/legacy-expertiza-migration.md](docs/legacy-expertiza-migration.md).

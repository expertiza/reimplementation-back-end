# Expertiza Backend Re-Implementation

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version - 3.4.5

---

## Environment Configuration

Before running the application, you need to configure environment variables:

1. **Copy the sample environment file:**
   ```bash
   cp sample.env .env
   ```

2. **Configure Frontend URL Settings:**
   
   Edit the `.env` file and set the following frontend variables based on your environment. These settings will override the defaults defined in `config/environments/(development|test|production).rb`:
   
   - **`FRONTEND_SCHEME`**: Should be `http://` for development/test or `https://` for production
   - **`FRONTEND_DOMAIN`**: The domain where your frontend is hosted
     - **Development/Test**: Defaults to `localhost` if not set (configured in `config/environments/development.rb` and `config/environments/test.rb`)
     - **Staging**: Requires explicit configuration via `.env`
     - **Production**: Defaults to `expertiza.ncsu.com` if not set (configured in `config/environments/production.rb`), can be overridden via `.env`
   - **`FRONTEND_PORT`**: Optional port number
     - **Development/Test**: Defaults to `3000` if not set (configured in `config/environments/development.rb` and `config/environments/test.rb`)
     - Leave blank for standard ports (80 for HTTP, 443 for HTTPS)
     - Set to custom port if needed (e.g., `8443` for custom HTTPS)
   
   **Example for local development** (using defaults, no .env needed):
   ```bash
   # No need to set anything - defaults will be used
   # FRONTEND_DOMAIN defaults to 'localhost'
   # FRONTEND_PORT defaults to 3000
   ```
   
   **Example for local development** (overriding defaults via .env):
   ```env
   FRONTEND_SCHEME='http://'
   FRONTEND_DOMAIN='localhost'
   FRONTEND_PORT=3000
   ```
   
   **Note:** `FRONTEND_DOMAIN` must be explicitly configured via `.env` in staging environments. In production, it defaults to `expertiza.ncsu.com` but can be overridden if needed. The application will fail to start if `FRONTEND_DOMAIN` is not set in staging.

3. **Load environment variables** (optional, only needed if running outside of Docker):
   > **Note:**
   > 
   > If you're using Docker Compose, the `.env` file is automatically loaded, so you don't need to source it manually.

   
   When running the Rails server outside of Docker (e.g., `rails s`), you may need to source the `.env` file to load environment variables:
   
   **Linux/macOS:**
   
   rails s
   ```
   
   **Windows (PowerShell):**
   ```powershell
   Get-Content .env | ForEach-Object { if ($_ -and !$_.StartsWith("#")) { $key, $value = $_ -split '=', 2; [Environment]::SetEnvironmentVariable($key, $value) } }
   rails s
   ```

---

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

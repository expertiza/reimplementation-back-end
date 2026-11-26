
#!/usr/bin/env bash
set -euo pipefail

# MariaDB runs this script on first initialization of a new data volume.

: "${MARIADB_USER:?MARIADB_USER must be configured}"
: "${MARIADB_ROOT_PASSWORD:?MARIADB_ROOT_PASSWORD must be configured}"

# Validate the username before inserting it into SQL.
if [[ ! "$MARIADB_USER" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid MARIADB_USER" >&2
  exit 1
fi

# Connect as root through the temporary MariaDB server's socket.
MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`reimplementation_test\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON \`reimplementation\\_test\`.* TO '${MARIADB_USER}'@'%';
SQL


#!/usr/bin/env bash
set -euo pipefail

# MySQL initializes this script on a fresh database volume.

: "${MYSQL_USER:?MYSQL_USER must be configured}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD must be configured}"

# Validate the username before inserting it into SQL.
if [[ ! "$MYSQL_USER" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid MYSQL_USER" >&2
  exit 1
fi

# Connect as root through the temporary MySQL server's socket.
MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`reimplementation_test\`;
GRANT ALL PRIVILEGES ON \`reimplementation\\_test\`.* TO '${MYSQL_USER}'@'%';
SQL

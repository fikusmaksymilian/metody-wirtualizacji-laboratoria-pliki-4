#!/bin/sh
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
CREATE ROLE breach_app LOGIN PASSWORD '$APP_DB_PASSWORD';
GRANT CONNECT ON DATABASE "$POSTGRES_DB" TO breach_app;
GRANT SELECT ON leaked_hashes TO breach_app;
EOSQL

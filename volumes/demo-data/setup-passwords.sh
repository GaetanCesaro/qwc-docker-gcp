#!/bin/bash
set -e

echo "Setting up passwords for QWC users..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DATABASE" <<-EOSQL
    ALTER USER qwc_admin WITH PASSWORD '$QWC_ADMIN_PASSWORD';
    ALTER USER qwc_service WITH PASSWORD '$QWC_SERVICE_PASSWORD';
    ALTER USER qwc_service_write WITH PASSWORD '$QWC_SERVICE_WRITE_PASSWORD';
EOSQL

echo "Passwords configured successfully."
#!/bin/bash
set -e

qwc_config_schema=${QWC_CONFIG_SCHEMA:-qwc_config}
qwc_geodb_schema=${QWC_GEODB_SCHEMA:-qwc_geodb}

echo "qwc_config_schema is $qwc_config_schema"
echo "qwc_geodb_schema is $qwc_geodb_schema"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  DROP SCHEMA IF EXISTS ${qwc_config_schema} CASCADE;
  DROP SCHEMA IF EXISTS ${qwc_geodb_schema} CASCADE;

  DROP ROLE IF EXISTS qwc_admin;
  DROP ROLE IF EXISTS qwc_service;
  DROP ROLE IF EXISTS qwc_service_write;

  CREATE ROLE qwc_admin LOGIN PASSWORD '$QWC_ADMIN_PASSWORD';
  CREATE ROLE qwc_service LOGIN PASSWORD '$QWC_SERVICE_PASSWORD';
  CREATE ROLE qwc_service_write LOGIN PASSWORD '$QWC_SERVICE_WRITE_PASSWORD';

  COMMENT ON DATABASE $POSTGRES_DATABASE IS 'DB for qwc-services';
  
  GRANT qwc_admin TO $POSTGRES_USER;
  GRANT qwc_service TO $POSTGRES_USER;
  GRANT qwc_service_write TO $POSTGRES_USER;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "$POSTGRES_DATABASE" <<-EOSQL
  CREATE SCHEMA ${qwc_config_schema} AUTHORIZATION qwc_admin;
  COMMENT ON SCHEMA ${qwc_config_schema} IS 'ConfigDB for qwc-services';
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "$POSTGRES_DATABASE" <<-EOSQL
  CREATE EXTENSION IF NOT EXISTS postgis;
  GRANT SELECT ON TABLE geometry_columns TO PUBLIC;
  GRANT SELECT ON TABLE geography_columns TO PUBLIC;
  GRANT SELECT ON TABLE spatial_ref_sys TO PUBLIC;
EOSQL
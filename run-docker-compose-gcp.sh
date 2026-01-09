#!/usr/bin/env sh

if [ $# != 1 ];
then
    echo "Usage : run-docker-compose-gcp.sh <environment>"
    exit 1
fi

ENVIRONMENT=$1

set -e

cat docker-compose-gcp.yml | sed -f run_"$ENVIRONMENT".sed | docker compose -f - up
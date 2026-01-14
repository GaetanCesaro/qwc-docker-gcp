#!/bin/sh

echo "Attente du proxy Cloud SQL..."
sleep 5

echo "=== Liste des schémas ==="
psql service=qwc_configdb -c "\dn"

echo "=== Vérification du schéma eauphrate ==="
if psql service=qwc_configdb -t -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name='eauphrate'" | grep -q eauphrate; then
  echo "Schéma eauphrate trouvé, liste des tables :"
  psql service=qwc_configdb -c "\dt eauphrate.*"
else
  echo "Schéma eauphrate non trouvé"
fi

echo "=== Fin de l analyse ==="

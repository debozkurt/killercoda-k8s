#!/bin/bash
# Checks: database-creds is an Opaque Secret carrying DB_PASSWORD (base64 in data).
TYPE=$(kubectl get secret database-creds -n provisioning -o jsonpath='{.type}' 2>/dev/null)
PW=$(kubectl get secret database-creds -n provisioning -o jsonpath='{.data.DB_PASSWORD}' 2>/dev/null)
if [ "$TYPE" != "Opaque" ] || [ -z "$PW" ]; then
  echo "Secret provisioning/database-creds missing or not Opaque (type='$TYPE'). Expected the baseline Secret." >&2
  exit 1
fi
echo "✓ database-creds is an Opaque Secret with a base64 DB_PASSWORD value"
exit 0

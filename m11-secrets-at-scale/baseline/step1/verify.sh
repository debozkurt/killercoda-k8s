#!/bin/bash
# Checks: both SecretSyncs report Ready=True in .status — the pipeline's declarative
# inputs are present and the operator has reconciled them. Defensive baseline check.
DB=$(kubectl get secretsync db-credentials -n provisioning -o jsonpath='{.status.ready}' 2>/dev/null)
PA=$(kubectl get secretsync partner-api -n media -o jsonpath='{.status.ready}' 2>/dev/null)
if [ "$DB" != "True" ] || [ "$PA" != "True" ]; then
  echo "SecretSyncs aren't both Ready yet (db-credentials='$DB', partner-api='$PA'). The operator reconciles every ~10s — the cluster may still be coming up; wait a few seconds and retry." >&2
  exit 1
fi
echo "✓ Both SecretSyncs report Ready=True — the store is readable and each named key resolved"
exit 0

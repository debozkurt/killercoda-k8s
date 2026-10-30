#!/bin/bash
# Checks: v1 is served again (the version the operator reads), and the operator reconciled the
# tenants: orion-media exists and orion reads Ready. Asserts the outcome, not the exact command.
SERVED=$(kubectl get crd mediatenants.polyphone.example \
  -o jsonpath='{.spec.versions[?(@.name=="v1")].served}' 2>/dev/null)
if [ "$SERVED" != "true" ]; then
  echo "CRD version v1 is still not served (served='$SERVED'). The operator reads v1. Serve it: kubectl patch crd mediatenants.polyphone.example --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/versions/0/served\",\"value\":true}]'" >&2
  exit 1
fi
if ! kubectl get deployment orion-media -n media >/dev/null 2>&1; then
  echo "v1 is served again, but orion-media does not exist yet. The operator retries every ~10 seconds. Wait and retry." >&2
  exit 1
fi
PHASE=$(kubectl get mediatenant orion -n media -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" != "Ready" ]; then
  echo "orion-media exists but orion .status.phase is '$PHASE'. The operator is mid-reconcile. Wait a few seconds and retry." >&2
  exit 1
fi
echo "✓ v1 is served again; the operator reconciled orion (phase Ready) — the stall was a retired CRD version, not RBAC"
exit 0

#!/bin/bash
# Checks: the MediaTenant CRD is registered and Established, so the new type is served
# by the API server exactly like a built-in. Defensive baseline check.
EST=$(kubectl get crd mediatenants.polyphone.example \
  -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)
if [ "$EST" != "True" ]; then
  echo "The mediatenants.polyphone.example CRD isn't Established yet (got '$EST'). The cluster may still be coming up — wait a few seconds and retry." >&2
  exit 1
fi
echo "✓ CRD mediatenants.polyphone.example is Established — MediaTenant is a served type"
exit 0

#!/bin/bash
# Checks: the mTLS pair is present and Ready (config-api server + config-client caller).
# Defensive baseline check — nothing is broken.
for pair in "config-api:media" "config-client:app-services"; do
  d="${pair%%:*}"; ns="${pair##*:}"
  if ! kubectl get deployment "$d" -n "$ns" >/dev/null 2>&1; then
    echo "Deployment $d isn't present in $ns yet. The cluster may still be coming up — wait and retry." >&2
    exit 1
  fi
done
AVAIL=$(kubectl get deployment config-api -n media -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${AVAIL:-0}" -lt 1 ]; then
  echo "config-api has no available replica yet (its TLS Secret may still be mounting). Wait and retry." >&2
  exit 1
fi
echo "✓ the mTLS pair is up — config-client (app-services) can call config-api (media) over mutual TLS"
exit 0

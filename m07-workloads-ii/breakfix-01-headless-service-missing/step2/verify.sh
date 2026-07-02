#!/bin/bash
# Checks: the governing Service `session-store` now exists, is HEADLESS (clusterIP
# None), and selects the Pods (its EndpointSlice has addresses) — the conditions
# under which cluster DNS publishes the per-Pod records. Asserts the outcome, not
# the exact command used.
CIP=$(kubectl get svc session-store -n app-services -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CIP" ]; then
  echo "No session-store Service in app-services yet. Create the headless Service the StatefulSet's serviceName points at, e.g.: kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata: { name: session-store, namespace: app-services }
spec: { clusterIP: None, selector: { app: session-store }, ports: [{ port: 80 }] }
EOF" >&2
  exit 1
fi
if [ "$CIP" != "None" ]; then
  echo "session-store Service exists but is NOT headless (clusterIP=$CIP). Per-Pod DNS records only come from a headless Service — recreate it with clusterIP: None." >&2
  exit 1
fi
ENDPOINTS=$(kubectl get endpointslices -n app-services -l kubernetes.io/service-name=session-store \
  -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | grep -c .)
if [ "$ENDPOINTS" -lt 1 ]; then
  echo "The session-store headless Service has no endpoints — its selector must match the Pods' label (app: session-store)." >&2
  exit 1
fi
echo "✓ Headless Service session-store exists (clusterIP None) with $ENDPOINTS endpoint(s) — per-Pod DNS resolves"
exit 0

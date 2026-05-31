#!/bin/bash
# Checks: sip-app has all three probes configured and Endpoints are populated.
PROBES=$(kubectl get deploy sip-app -n app-services -o json 2>/dev/null \
  | grep -c -E '"livenessProbe"|"readinessProbe"|"startupProbe"')
[ "$PROBES" -ge 3 ] || { echo "Expected 3 probes (liveness/readiness/startup) on sip-app, found $PROBES" >&2; exit 1; }

EPS=$(kubectl get endpoints sip-app -n app-services -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null | wc -w)
[ "$EPS" -ge 1 ] || { echo "sip-app Service has no ready endpoints; readiness may be failing" >&2; exit 1; }

echo "✓ All three probes configured; $EPS ready endpoint(s) behind the sip-app Service"
exit 0

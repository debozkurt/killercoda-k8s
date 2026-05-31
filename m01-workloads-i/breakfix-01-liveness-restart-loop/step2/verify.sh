#!/bin/bash
# Checks: route-engine's liveness probe no longer points at the bogus /healthz
# (corrected to a served path, or removed), and the Deployment is available.
PROBE_PATH=$(kubectl get deploy route-engine -n call-routing -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null)
if [ "$PROBE_PATH" = "/healthz" ]; then
  echo "Liveness probe still targets /healthz — nginx 404s that, so the kill loop continues. Point it at '/' or remove the probe:" >&2
  echo "  kubectl patch deployment route-engine -n call-routing --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/livenessProbe/httpGet/path\",\"value\":\"/\"}]'" >&2
  exit 1
fi

AVAIL=$(kubectl get deploy route-engine -n call-routing -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ -n "$AVAIL" ] && [ "$AVAIL" -ge 1 ] 2>/dev/null || { echo "route-engine has $AVAIL available replicas; the rollout may still be in flight — re-check in a few seconds" >&2; exit 1; }

echo "✓ Liveness probe fixed (path='${PROBE_PATH:-<removed>}'), route-engine available with $AVAIL replica(s)"
exit 0

#!/bin/bash
# Checks: directory's readiness probe no longer targets the bogus 8080, and the
# Service has at least one ready endpoint again (the real proof traffic flows).
PROBE_PORT=$(kubectl get deploy directory -n app-services -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
if [ "$PROBE_PORT" = "8080" ]; then
  echo "Readiness probe still targets port 8080 — the app serves :80, so it stays not-Ready and the Service stays empty. Point it at 'http' (or 80):" >&2
  echo "  kubectl patch deployment directory -n app-services --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/port\",\"value\":\"http\"}]'" >&2
  exit 1
fi

EPS=$(kubectl get endpoints directory -n app-services -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null | wc -w)
[ "$EPS" -ge 1 ] || { echo "directory Service still has 0 ready endpoints; the rollout may still be settling — re-check in a few seconds" >&2; exit 1; }

echo "✓ Readiness probe fixed (port='$PROBE_PORT'); $EPS endpoint(s) back behind the directory Service"
exit 0

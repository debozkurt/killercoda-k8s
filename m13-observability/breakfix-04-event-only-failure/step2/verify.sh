#!/bin/bash
# Checks: rate-loader is Available, so its Pod mounted its volume and started. Either
# fix passes: pointing the volume at rate-table, or creating rate-table-v2.
if ! kubectl wait --for=condition=Available deployment/rate-loader -n call-routing --timeout=90s >/dev/null 2>&1; then
  echo "rate-loader is not Available yet. Its Pod cannot mount a ConfigMap that does not exist." >&2
  echo "  Read the cause with: kubectl events -n call-routing --types=Warning" >&2
  echo "  Fix it with: kubectl patch deployment rate-loader -n call-routing --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/volumes/0/configMap/name\",\"value\":\"rate-table\"}]'" >&2
  exit 1
fi
echo "✓ rate-loader is Available: its Pod mounted the ConfigMap and started"
exit 0

#!/bin/bash
# Checks: the call-metrics Service lists at least one endpoint address, so a
# Service-based scraper finds a target. Deterministic field check.
EP=$(kubectl get endpoints call-metrics -n analytics -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ -z "$EP" ]; then
  echo "The Service call-metrics still has no endpoints. Its selector must match the Pod's label (app=call-metrics)." >&2
  echo "  Fix it with: kubectl patch service call-metrics -n analytics -p '{\"spec\":{\"selector\":{\"app\":\"call-metrics\"}}}'" >&2
  exit 1
fi
echo "✓ the Service call-metrics lists an endpoint ($EP), so a scraper can find the target"
exit 0

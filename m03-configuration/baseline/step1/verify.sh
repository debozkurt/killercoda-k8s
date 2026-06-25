#!/bin/bash
# Checks: the app-config ConfigMap exists in media with the LOG_LEVEL key the
# baseline tours. Defensive — should always pass on a healthy baseline.
VAL=$(kubectl get configmap app-config -n media -o jsonpath='{.data.LOG_LEVEL}' 2>/dev/null)
if [ -z "$VAL" ]; then
  echo "ConfigMap media/app-config or its LOG_LEVEL key is missing. The fleet may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ ConfigMap media/app-config present (LOG_LEVEL=$VAL)"
exit 0

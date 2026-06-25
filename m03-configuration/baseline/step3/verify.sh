#!/bin/bash
# Checks: session-broker mounts app-config as files at /etc/app-config.
MP=$(kubectl get deploy session-broker -n media \
  -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="app-config")].mountPath}' 2>/dev/null)
if [ "$MP" != "/etc/app-config" ]; then
  echo "session-broker does not mount app-config at /etc/app-config (got '$MP'). Expected the baseline volume wiring." >&2
  exit 1
fi
echo "✓ session-broker mounts app-config as files at /etc/app-config"
exit 0

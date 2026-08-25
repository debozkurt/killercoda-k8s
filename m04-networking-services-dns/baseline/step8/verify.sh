#!/bin/bash
# Checks: session-broker still has at least one endpoint address after the
# scale up and back down. Defensive baseline check.
ADDR=$(kubectl get endpointslice -n media \
  -l kubernetes.io/service-name=session-broker \
  -o jsonpath='{.items[0].endpoints[0].addresses[0]}' 2>/dev/null)
if [ -z "$ADDR" ]; then
  echo "session-broker has no endpoint addresses yet — wait for the Pod to be Ready and retry." >&2
  exit 1
fi
echo "✓ session-broker backed by $ADDR"
exit 0

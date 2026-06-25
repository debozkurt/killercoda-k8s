#!/bin/bash
# Checks: session-broker is Ready again. Asserts the OUTCOME (the pod runs), not
# the method — fixing the env key, adding the key to the ConfigMap, or marking
# the reference optional are all valid ways to get here.
READY=$(kubectl get pod -n media -l app=session-broker -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$READY" != "true" ]; then
  STATE=$(kubectl get pod -n media -l app=session-broker -o jsonpath='{.items[0].status.containerStatuses[0].state}' 2>/dev/null)
  echo "session-broker is not Ready yet (state: ${STATE:-unknown})." >&2
  echo "Make its env reference resolve — point it at a key that exists, or add the key:" >&2
  echo "  kubectl patch deployment session-broker -n media --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/env/0/valueFrom/configMapKeyRef/key\",\"value\":\"MAX_SESSIONS\"}]'" >&2
  exit 1
fi
echo "✓ session-broker is Ready — its env reference resolves to an existing key"
exit 0

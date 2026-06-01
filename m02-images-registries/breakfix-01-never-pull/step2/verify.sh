#!/bin/bash
# Checks: metrics-aggregator is Ready again. Asserts the OUTCOME (the pod runs),
# not the method — letting the kubelet pull (policy change) and pre-loading +
# keeping Never (revert to a cached tag) are both valid fixes.
READY=$(kubectl get pod -n analytics -l app=metrics-aggregator -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$READY" != "true" ]; then
  STATE=$(kubectl get pod -n analytics -l app=metrics-aggregator -o jsonpath='{.items[0].status.containerStatuses[0].state}' 2>/dev/null)
  echo "metrics-aggregator is not Ready yet (state: ${STATE:-unknown})." >&2
  echo "Either let the kubelet pull (set imagePullPolicy to IfNotPresent/Always) or pin a cached image:" >&2
  echo "  kubectl patch deployment metrics-aggregator -n analytics --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/imagePullPolicy\",\"value\":\"IfNotPresent\"}]'" >&2
  exit 1
fi
echo "✓ metrics-aggregator is Ready — the image is on the node and the pod is running"
exit 0

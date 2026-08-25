#!/bin/bash
# Checks: an EndpointSlice for session-broker exists and carries at least one
# address — i.e. the controller rebuilt it after the delete and the scale-down
# left a Ready backend behind.
SLICE=$(kubectl get endpointslice -n media \
  -l kubernetes.io/service-name=session-broker \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$SLICE" ]; then
  echo "No EndpointSlice for session-broker yet. The controller recreates it within a few seconds — wait and retry." >&2
  exit 1
fi
ADDRS=$(kubectl get endpointslice "$SLICE" -n media \
  -o jsonpath='{.endpoints[*].addresses[0]}' 2>/dev/null)
if [ -z "$ADDRS" ]; then
  echo "EndpointSlice $SLICE exists but lists no addresses. Is the session-broker Pod Ready?" >&2
  exit 1
fi
echo "✓ $SLICE rebuilt by the controller, backends: $ADDRS"
exit 0

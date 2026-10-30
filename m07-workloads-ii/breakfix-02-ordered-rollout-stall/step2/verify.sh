#!/bin/bash
# Checks: session-store now reports 3 ready replicas — ordinal 0 passed its (corrected)
# readiness probe, so OrderedReady unblocked and created ordinals 1 and 2. Asserts the
# outcome, not the exact command used.
READY=$(kubectl get statefulset session-store -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
READY=${READY:-0}
if [ "$READY" -lt 3 ]; then
  PROBE_PORT=$(kubectl get statefulset session-store -n app-services -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
  if [ "$PROBE_PORT" != "80" ]; then
    echo "session-store has $READY/3 ready and its readiness probe still targets port '$PROBE_PORT'. Point it at the port the container serves (80), e.g.: kubectl patch statefulset session-store -n app-services --type=json -p '[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/port\",\"value\":80}]'" >&2
  else
    echo "Probe port is fixed (80) but only $READY/3 ready. OrderedReady does not replace an un-Ready Pod on its own, so delete the Pod that still runs the old template: kubectl delete pod session-store-0 -n app-services. Then wait for the ordinals: kubectl rollout status statefulset/session-store -n app-services" >&2
  fi
  exit 1
fi
echo "✓ session-store is 3/3 ready — ordinal 0 passed its probe and OrderedReady created ordinals 1 and 2"
exit 0

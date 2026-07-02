#!/bin/bash
# Checks: session-cache is 3/3 Ready again and its readiness probe targets port 80,
# so the OrderedReady set unwedged. Asserts the outcome.
PORT=$(kubectl get statefulset session-cache -n media \
  -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
if [ "$PORT" = "8080" ]; then
  echo "The readiness probe still targets port 8080 (nginx serves on 80). Patch it to 80 so ordinal 0 can become Ready." >&2
  exit 1
fi
READY=$(kubectl get statefulset session-cache -n media -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY" != "3" ]; then
  echo "session-cache is at ${READY:-0}/3 Ready. After fixing the probe, wait for the ordered cascade to finish (kubectl rollout status statefulset session-cache -n media)." >&2
  exit 1
fi
echo "✓ session-cache is 3/3 Ready with the readiness probe on port $PORT — the OrderedReady set unwedged"
exit 0

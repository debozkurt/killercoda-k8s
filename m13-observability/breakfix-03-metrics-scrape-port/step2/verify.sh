#!/bin/bash
# Checks: every call-metrics Pod advertises the port the container serves
# (prometheus.io/port == containerPort) and the Pod is Ready, so the verify
# cannot pass on the old Pod before the rollout. Deterministic.
CPORT=$(kubectl get deploy call-metrics -n analytics \
  -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}' 2>/dev/null)
if [ -z "$CPORT" ]; then
  echo "Cannot read the call-metrics container port. Is the workload present?" >&2
  echo "  Check it with: kubectl get deployment call-metrics -n analytics" >&2
  exit 1
fi
PORTS=$(kubectl get pods -n analytics -l app=call-metrics \
  -o jsonpath='{range .items[*]}{.metadata.annotations.prometheus\.io/port}{"\n"}{end}' 2>/dev/null)
if [ -z "$PORTS" ] || echo "$PORTS" | grep -qvx "$CPORT"; then
  echo "A call-metrics Pod still advertises a port other than $CPORT (the port /metrics is served on)." >&2
  echo "  Fix it with: kubectl patch deployment call-metrics -n analytics -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"prometheus.io/port\":\"$CPORT\"}}}}}'" >&2
  echo "  Then wait for the rollout: kubectl rollout status deployment call-metrics -n analytics" >&2
  exit 1
fi
if ! kubectl wait --for=condition=Ready pod -l app=call-metrics -n analytics --timeout=60s >/dev/null 2>&1; then
  echo "The annotation is right, but the call-metrics Pod is not Ready yet. Wait for the rollout:" >&2
  echo "  kubectl rollout status deployment call-metrics -n analytics" >&2
  exit 1
fi
echo "✓ the call-metrics Pod advertises port $CPORT, the port it serves /metrics on"
exit 0

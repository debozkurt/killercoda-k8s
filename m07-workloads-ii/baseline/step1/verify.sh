#!/bin/bash
# Checks: the fleet's StatefulSets and the sbc-edge DaemonSet exist, so the
# controller-contrast this step teaches holds. Defensive baseline check.
STS=$(kubectl get statefulset -A --no-headers 2>/dev/null | grep -c .)
DS=$(kubectl get daemonset -n edge sbc-edge --no-headers 2>/dev/null | grep -c .)
if [ "$STS" -lt 4 ]; then
  echo "Expected at least 4 StatefulSets in the fleet, found $STS. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
if [ "$DS" -lt 1 ]; then
  echo "sbc-edge DaemonSet not found yet — the cluster may still be coming up. Wait and retry." >&2
  exit 1
fi
echo "✓ Fleet StatefulSets present ($STS) and the sbc-edge DaemonSet exists"
exit 0

#!/bin/bash
# Checks: names resolve again from media (the DNS egress allow works) AND the lockdown
# policy is still present (isolation kept). Asserts the outcome, not a specific command.
if ! kubectl get networkpolicy restrict-egress-to-namespace -n media >/dev/null 2>&1; then
  echo "restrict-egress-to-namespace is gone. Do not delete the lockdown. Add an allow for DNS beside it." >&2
  exit 1
fi
OUT=$(kubectl run bf04-verify --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=8 http://session-broker.media.svc.cluster.local./ 2>/dev/null)
if echo "$OUT" | grep -qi "nginx\|Welcome"; then
  echo "✓ names resolve from media again, and the egress lockdown is still in place"
  exit 0
fi
echo "Name lookups from media still fail. Add an egress allow to the kube-dns Pods in kube-system on port 53 (UDP and TCP). Wait a few seconds and retry." >&2
exit 1

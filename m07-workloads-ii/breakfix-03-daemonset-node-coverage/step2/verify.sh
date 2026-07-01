#!/bin/bash
# Checks: rtp-probe now covers both nodes — desiredNumberScheduled == 2 (the tainted
# control-plane node became eligible) and both Pods are Ready. Asserts the outcome,
# not the exact command used.
DESIRED=$(kubectl get ds rtp-probe -n edge -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
READY=$(kubectl get ds rtp-probe -n edge -o jsonpath='{.status.numberReady}' 2>/dev/null)
DESIRED=${DESIRED:-0}; READY=${READY:-0}
if [ "$DESIRED" -lt 2 ]; then
  echo "rtp-probe still reports DESIRED $DESIRED — the control-plane node isn't eligible yet. Add a toleration for its taint, e.g.: kubectl patch daemonset rtp-probe -n edge --type=json -p '[{\"op\":\"add\",\"path\":\"/spec/template/spec/tolerations\",\"value\":[{\"key\":\"node-role.kubernetes.io/control-plane\",\"operator\":\"Exists\",\"effect\":\"NoSchedule\"}]}]'" >&2
  exit 1
fi
if [ "$READY" -lt 2 ]; then
  echo "rtp-probe is now eligible on both nodes (DESIRED $DESIRED) but only $READY Ready — the control-plane Pod may still be starting. Wait a few seconds and retry." >&2
  exit 1
fi
echo "✓ rtp-probe covers both nodes (DESIRED 2, READY 2) — the control-plane toleration made the tainted node eligible"
exit 0

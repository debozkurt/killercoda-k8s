#!/bin/bash
# Checks: disk-exporter has one Ready Pod (the worker is the only fast-disk node), and no
# node was relabeled disktype=nvme to satisfy the selector. Asserts the outcome, not the
# exact command used.
if kubectl get nodes -l disktype=nvme --no-headers 2>/dev/null | grep -q .; then
  echo "A node now carries disktype=nvme. That label claims hardware the node does not have. Remove it and fix the selector instead:" >&2
  echo "  kubectl label nodes -l disktype=nvme disktype=ssd --overwrite" >&2
  exit 1
fi
DESIRED=$(kubectl get ds disk-exporter -n media -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
READY=$(kubectl get ds disk-exporter -n media -o jsonpath='{.status.numberReady}' 2>/dev/null)
DESIRED=${DESIRED:-0}; READY=${READY:-0}
if [ "$DESIRED" -lt 1 ]; then
  echo "disk-exporter still reports DESIRED $DESIRED, so no node is eligible. Point its selector at a label a node carries:" >&2
  echo "  kubectl patch daemonset disk-exporter -n media -p '{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"disktype\":\"ssd\"}}}}}'" >&2
  exit 1
fi
if [ "$READY" -lt "$DESIRED" ]; then
  echo "disk-exporter is eligible on $DESIRED node(s) but only $READY Ready. The Pod may still be starting. Wait a few seconds and retry." >&2
  exit 1
fi
echo "✓ disk-exporter covers the fast-disk node (DESIRED $DESIRED, READY $READY); its selector matches a label the worker really carries"
exit 0

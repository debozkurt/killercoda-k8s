#!/bin/bash
# Checks: kube-proxy is running and session-broker still has a ClusterIP, so the
# rules this step reads are present to be read. Defensive baseline check.
SVC_IP=$(kubectl get svc session-broker -n media -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$SVC_IP" ]; then
  echo "session-broker has no ClusterIP — re-check the Service and retry." >&2
  exit 1
fi
READY=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy \
  --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d ' ')
if [ "$READY" -lt 1 ]; then
  echo "No kube-proxy Pod is Running — without it no node has Service rules." >&2
  exit 1
fi
echo "✓ ClusterIP $SVC_IP present, kube-proxy Running on $READY node(s)"
exit 0

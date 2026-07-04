#!/bin/bash
# Checks: rtp-ingress is a NodePort with externalTrafficPolicy Cluster and has an
# endpoint, so it is reachable from any node. Defensive baseline check.
TYPE=$(kubectl get svc rtp-ingress -n media -o jsonpath='{.spec.type}' 2>/dev/null)
ETP=$(kubectl get svc rtp-ingress -n media -o jsonpath='{.spec.externalTrafficPolicy}' 2>/dev/null)
EP=$(kubectl get endpoints rtp-ingress -n media -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
if [ "$TYPE" != "NodePort" ]; then
  echo "rtp-ingress isn't a NodePort yet (type='$TYPE') — wait and retry." >&2
  exit 1
fi
if [ "$ETP" != "Cluster" ]; then
  echo "rtp-ingress externalTrafficPolicy is '$ETP', expected Cluster for the healthy tour." >&2
  exit 1
fi
if [ -z "$EP" ]; then
  echo "rtp-ingress has no endpoints yet — its Pod may still be coming up. Wait and retry." >&2
  exit 1
fi
echo "✓ rtp-ingress is a NodePort (ETP=Cluster) with a backend at $EP — reachable from any node"
exit 0

#!/bin/bash
# Checks: the mesh-client sidecar actually has session-broker programmed into its Envoy
# config (a 'stable' cluster with endpoints) — proving istioctl reads the live dataplane.
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ]; then
  echo "mesh-client pod not found yet — wait for it to be Running and retry." >&2
  exit 1
fi
EP=$(istioctl proxy-config endpoints "$POD" -n media 2>/dev/null | grep 'session-broker' | grep ':80')
if [ -n "$EP" ]; then
  echo "✓ mesh-client's Envoy has session-broker endpoints programmed (istioctl reads the live config)"
  exit 0
fi
echo "No session-broker endpoints in mesh-client's Envoy config yet. istiod may still be pushing" >&2
echo "config to the sidecar (check 'istioctl proxy-status' for SYNCED) — wait and retry." >&2
exit 1

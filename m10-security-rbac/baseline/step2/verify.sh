#!/bin/bash
# Checks: the built-in 'view' ClusterRole is present, so the RBAC walkthrough
# in this step holds. Defensive baseline check.
if ! kubectl get clusterrole view >/dev/null 2>&1; then
  echo "The built-in 'view' ClusterRole isn't present yet. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ built-in ClusterRole 'view' exists — the read-only role you grant per namespace"
exit 0

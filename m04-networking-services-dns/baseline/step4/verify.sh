#!/bin/bash
# Checks: cluster DNS is healthy — the kube-dns Service has CoreDNS endpoints
# behind it. Defensive baseline check.
EP=$(kubectl get endpoints kube-dns -n kube-system -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
if [ -z "$EP" ]; then
  echo "kube-dns has no endpoints — CoreDNS may still be starting. Wait and retry." >&2
  exit 1
fi
echo "✓ Cluster DNS is up: kube-dns is backed by CoreDNS at $EP"
exit 0

#!/bin/bash
# Checks: the default-deny-ingress policy exists in `media` and selects all pods
# (no matchLabels on its podSelector) — the flip that makes the namespace
# default-deny for ingress.
if ! kubectl get networkpolicy default-deny-ingress -n media >/dev/null 2>&1; then
  echo "default-deny-ingress not found in 'media' yet. The setup may still be applying policies — wait and retry." >&2
  exit 1
fi
# An all-pods policy has no matchLabels on its podSelector; a targeted one does.
ML=$(kubectl get networkpolicy default-deny-ingress -n media -o jsonpath='{.spec.podSelector.matchLabels}' 2>/dev/null)
if [ -n "$ML" ]; then
  echo "default-deny-ingress selects only '$ML'; expected an empty podSelector (all pods in the namespace)." >&2
  exit 1
fi
echo "✓ default-deny-ingress selects all pods in 'media' — the namespace is default-deny for ingress"
exit 0

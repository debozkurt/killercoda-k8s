#!/bin/bash
# Checks: dialplan is back at 2 (Flux reverted the drift) and voicemail is back at 2.
REPLICAS=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "2" ] || { echo "dialplan wants ${REPLICAS:-no} replicas, git declares 2. Run:" >&2; echo "  flux reconcile kustomization apps" >&2; exit 1; }

VM=$(kubectl get deploy voicemail -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$VM" = "2" ] || { echo "voicemail wants ${VM:-no} replicas; the HelmRelease does not revert it. Run:" >&2; echo "  kubectl scale deployment voicemail -n app-services --replicas=2" >&2; exit 1; }

echo "✓ Flux reverted dialplan to 2; voicemail is back at 2 by hand"
exit 0

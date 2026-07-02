#!/bin/bash
# Checks: payments-api now has an available replica — i.e. its Pod passed PodSecurity
# admission under enforce=restricted, which it can only do with a compliant securityContext.
AVAIL=$(kubectl get deploy payments-api -n payments -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAIL" != "1" ]; then
  echo "payments-api still has no available replica (availableReplicas='$AVAIL'). Its Pods are rejected by PodSecurity 'restricted'. Add a compliant securityContext: pod-level runAsNonRoot=true + runAsUser=1000 + seccompProfile.type=RuntimeDefault, and container-level allowPrivilegeEscalation=false + capabilities.drop=[ALL]." >&2
  exit 1
fi
echo "✓ payments-api is Available (1/1) — its Pod satisfies the restricted Pod Security Standard"
exit 0

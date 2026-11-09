#!/bin/bash
# Checks: the source has an artifact, apps applied it, and all three GitOps
# workloads are ready. Accepts any existing branch that delivers them.
REV=$(kubectl get gitrepository polyphone-config -n flux-system -o jsonpath='{.status.artifact.revision}' 2>/dev/null)
[ -n "$REV" ] || { echo "GitRepository polyphone-config has no artifact. Point it at an existing branch:" >&2; echo "  kubectl patch gitrepository polyphone-config -n flux-system --type=merge -p '{\"spec\":{\"ref\":{\"branch\":\"main\"}}}'" >&2; exit 1; }

APPLIED=$(kubectl get kustomization apps -n flux-system -o jsonpath='{.status.lastAppliedRevision}' 2>/dev/null)
[ "$APPLIED" = "$REV" ] || { echo "apps applied ${APPLIED:-nothing}, the source holds $REV. Run:" >&2; echo "  flux reconcile kustomization apps" >&2; exit 1; }

for d in dialplan message-store voicemail; do
  RR=$(kubectl get deploy "$d" -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  [ -n "$RR" ] && [ "$RR" -ge 1 ] || { echo "Deployment $d has no ready replicas yet. Wait a minute, then run:" >&2; echo "  flux get helmreleases" >&2; exit 1; }
done

echo "✓ Source stored $REV; apps applied it; dialplan, message-store and voicemail are ready"
exit 0

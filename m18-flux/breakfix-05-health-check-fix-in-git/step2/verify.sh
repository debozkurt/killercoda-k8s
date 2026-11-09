#!/bin/bash
# Checks: the fix went through git. The source holds a commit newer than the
# bad release commit, apps applied that revision and is Ready, and dialplan
# runs a pullable image with 2 ready replicas. A kubectl-only fix fails here.
BAD=$(cat /tmp/.m18-bad-rev 2>/dev/null)
SRC=$(kubectl get gitrepository polyphone-config -n flux-system -o jsonpath='{.status.artifact.revision}' 2>/dev/null)
case "$SRC" in
  *"$BAD"*) echo "The source still holds the bad release commit. Fix dialplan.yaml in git, then push:" >&2
            echo "  cd /root/polyphone-config && git revert --no-edit HEAD && git push" >&2; exit 1 ;;
esac

SUSPEND=$(kubectl get kustomization apps -n flux-system -o jsonpath='{.spec.suspend}' 2>/dev/null)
[ "$SUSPEND" = "true" ] && { echo "Kustomization apps is suspended. Run:" >&2; echo "  flux resume kustomization apps" >&2; exit 1; }

READY=$(kubectl get kustomization apps -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
APPLIED=$(kubectl get kustomization apps -n flux-system -o jsonpath='{.status.lastAppliedRevision}' 2>/dev/null)
[ "$READY" = "True" ] && [ "$APPLIED" = "$SRC" ] || { echo "apps is Ready=${READY:-none} at ${APPLIED:-nothing}; the source holds $SRC. Run:" >&2; echo "  flux reconcile kustomization apps --with-source" >&2; exit 1; }

IMAGE=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
RR=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
UP=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)
[ "$IMAGE" != "nginx:1.25-polyphone" ] && [ "$RR" = "2" ] && [ "$UP" = "2" ] \
  || { echo "dialplan runs $IMAGE with ${RR:-0} ready and ${UP:-0} updated replicas. Wait for the rollout:" >&2; echo "  kubectl rollout status deployment/dialplan -n app-services" >&2; exit 1; }

echo "✓ The fix is in git: apps applied $SRC, and dialplan runs $IMAGE with 2 ready replicas"
exit 0

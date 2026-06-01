#!/bin/bash
# Checks: directory is Ready and no longer pinned to the bogus all-zeros digest.
# Both re-pinning a real digest and falling back to the tag are valid fixes.
IMG=$(kubectl get deploy directory -n app-services -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
case "$IMG" in
  *sha256:0000000000000000000000000000000000000000000000000000000000000000*)
    echo "Image still pinned to the non-existent digest: $IMG" >&2
    echo "Re-pin to a real digest or the tag, e.g.:  kubectl set image deployment/directory app=nginx@\$(crane digest nginx:1.25) -n app-services" >&2
    exit 1 ;;
esac
READY=$(kubectl get pod -n app-services -l app=directory -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
[ "$READY" = "true" ] || { echo "directory is not Ready yet (the new pod may still be pulling). Current image: $IMG" >&2; exit 1; }
echo "✓ directory is Ready; reference resolves: $IMG"
exit 0

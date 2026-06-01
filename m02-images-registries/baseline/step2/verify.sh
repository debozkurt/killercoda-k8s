#!/bin/bash
# Checks: a running pod resolved its tag to an immutable digest (imageID carries
# a sha256), demonstrating tag -> digest resolution.
IMGID=$(kubectl get pod -n analytics -l app=metrics-aggregator -o jsonpath='{.items[0].status.containerStatuses[0].imageID}' 2>/dev/null)
case "$IMGID" in
  *@sha256:*) ;;
  *) echo "metrics-aggregator imageID is '$IMGID', expected a ...@sha256:... digest. Is the pod Running yet?" >&2; exit 1 ;;
esac
echo "✓ Tag resolved to an immutable digest: $IMGID"
exit 0

#!/bin/bash
# Checks: cdr-archive now completes (succeeded=1) and the log-shipper is a native
# sidecar (an initContainer), not an ordinary blocking container.
SUCCEEDED=$(kubectl get job cdr-archive -n cdr-storage -o jsonpath='{.status.succeeded}' 2>/dev/null)
if [ "$SUCCEEDED" != "1" ]; then
  echo "cdr-archive succeeded=$SUCCEEDED, expected 1. If a long-running helper is still in spec.containers, the Pod can't complete. Move log-shipper to initContainers with restartPolicy: Always and recreate (see step 2). If you just recreated, give it a few seconds." >&2
  exit 1
fi

# Confirm the durable fix: log-shipper should be a native sidecar (initContainer
# with restartPolicy: Always), not back in spec.containers.
INIT=$(kubectl get job cdr-archive -n cdr-storage -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="log-shipper")].restartPolicy}' 2>/dev/null)
if [ "$INIT" != "Always" ]; then
  echo "Job completed, but log-shipper is not a native sidecar. The durable fix is an initContainer with restartPolicy: Always so the helper stops when the archive finishes (don't just delete the sidecar)." >&2
  exit 1
fi

echo "✓ Sidecar fixed: cdr-archive succeeded=1, log-shipper is a native sidecar (initContainer + restartPolicy: Always)"
exit 0

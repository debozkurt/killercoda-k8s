#!/bin/bash
# Checks: the fleet namespace 'media' carries no PodSecurity enforce label, so it
# runs under the default Privileged standard (the healthy baseline this step
# contrasts against psa-demo). Defensive; independent of the psa-demo cleanup.
LABEL=$(kubectl get ns media -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ -n "$LABEL" ]; then
  echo "namespace media unexpectedly enforces '$LABEL'. The baseline fleet namespaces should carry no enforce label." >&2
  exit 1
fi
echo "✓ media enforces no Pod Security Standard (default Privileged) — the unrestricted baseline"
exit 0

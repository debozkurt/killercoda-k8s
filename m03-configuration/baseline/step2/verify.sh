#!/bin/bash
# Checks: session-broker consumes app-config as env via envFrom. Reads the spec,
# not a live exec, so it asserts the wiring regardless of pod scheduling timing.
REF=$(kubectl get deploy session-broker -n media \
  -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
if [ "$REF" != "app-config" ]; then
  echo "session-broker is not wired to app-config via envFrom (got '$REF'). Expected the baseline env wiring." >&2
  exit 1
fi
echo "✓ session-broker injects app-config as env vars (envFrom)"
exit 0

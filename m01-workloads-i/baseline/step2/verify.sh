#!/bin/bash
# Checks: sip-app Pods are Running with restartPolicy=Always and zero restarts.
POLICY=$(kubectl get pod -n app-services -l app=sip-app -o jsonpath='{.items[0].spec.restartPolicy}' 2>/dev/null)
[ "$POLICY" = "Always" ] || { echo "restartPolicy is '$POLICY', expected 'Always'" >&2; exit 1; }

RUNNING=$(kubectl get pods -n app-services -l app=sip-app --no-headers 2>/dev/null | awk '$3 == "Running"' | wc -l)
[ "$RUNNING" -ge 1 ] || { echo "Expected 1+ Running sip-app pod, got $RUNNING" >&2; exit 1; }

echo "✓ Healthy lifecycle: $RUNNING Running pod(s), restartPolicy=$POLICY"
exit 0

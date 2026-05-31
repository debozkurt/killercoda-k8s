#!/bin/bash
# Checks: sip-app has a sane grace period (>=10s) and a preStop hook configured.
GRACE=$(kubectl get deploy sip-app -n app-services -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}' 2>/dev/null)
[ -n "$GRACE" ] && [ "$GRACE" -ge 10 ] 2>/dev/null || { echo "terminationGracePeriodSeconds is '$GRACE', expected >=10 for a graceful drain" >&2; exit 1; }

PRESTOP=$(kubectl get deploy sip-app -n app-services -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop}' 2>/dev/null)
[ -n "$PRESTOP" ] || { echo "No preStop hook configured on sip-app" >&2; exit 1; }

echo "✓ Graceful shutdown configured: grace=${GRACE}s, preStop hook present"
exit 0

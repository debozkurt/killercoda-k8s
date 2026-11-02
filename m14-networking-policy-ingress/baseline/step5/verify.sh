#!/bin/bash
# Checks: the learner removed the extra allow and left the original policies in place.
# Defensive baseline check: nothing is broken.
if kubectl get networkpolicy allow-broker-from-signaling -n media >/dev/null 2>&1; then
  echo "allow-broker-from-signaling still exists, so signaling can still reach session-broker." >&2
  echo "  Remove it: kubectl delete networkpolicy allow-broker-from-signaling -n media" >&2
  exit 1
fi
if ! kubectl get networkpolicy default-deny-ingress allow-broker-from-app -n media >/dev/null 2>&1; then
  echo "A baseline policy is missing in media. Only the extra allow should be removed." >&2
  exit 1
fi
echo "✓ the extra allow is gone and the baseline policies are intact"
exit 0

#!/bin/bash
# Checks: the base renders, the generated ConfigMap carries a content-hash
# suffix, and the Deployment's envFrom reference was rewritten to that hashed
# name (the name-match rewrite that breakfix-02 breaks). Asserts the render,
# not any command the learner typed.
BASE=/root/edge-relay/base

RENDER=$(kubectl kustomize "$BASE" 2>/dev/null)
[ -n "$RENDER" ] || { echo "kubectl kustomize $BASE produced no output — does the base render?" >&2; exit 1; }

# The generated ConfigMap name = edge-relay-config-<hash>
CM=$(echo "$RENDER" | grep -oE 'edge-relay-config-[a-z0-9]+' | head -1)
[ -n "$CM" ] || { echo "No hash-suffixed ConfigMap (edge-relay-config-<hash>) in the render." >&2; exit 1; }

# The Deployment's envFrom must reference that SAME hashed name.
echo "$RENDER" | grep -q "name: $CM" || {
  echo "The Deployment reference was not rewritten to the hashed ConfigMap name ($CM)." >&2; exit 1;
}
REFS=$(echo "$RENDER" | grep -c "name: $CM")
[ "$REFS" -ge 2 ] || { echo "Expected the generator name and the rewritten reference to match ($CM)." >&2; exit 1; }

echo "✓ Base renders; generator produced $CM and the Deployment reference was rewritten to it."
exit 0

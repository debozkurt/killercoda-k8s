#!/bin/bash
# Checks: media-recorder carries the defaulted imagePullPolicy for a non-latest
# tag (IfNotPresent), confirming the defaulting rule the step teaches.
POLICY=$(kubectl get pod -n media -l app=media-recorder -o jsonpath='{.items[0].spec.containers[0].imagePullPolicy}' 2>/dev/null)
[ "$POLICY" = "IfNotPresent" ] || { echo "media-recorder imagePullPolicy is '$POLICY', expected 'IfNotPresent' (the default for a non-:latest tag)." >&2; exit 1; }
echo "✓ imagePullPolicy defaulted to IfNotPresent for the pinned tag"
exit 0

#!/bin/bash
# Checks: the private-registry image reference is present on media-recorder
# (the layered M02 workload), so the learner can read a full reference off it.
IMG=$(kubectl get pod -n media -l app=media-recorder -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null)
case "$IMG" in
  localhost:5000/polyphone/media-recorder:*) ;;
  *) echo "media-recorder image is '$IMG', expected localhost:5000/polyphone/media-recorder:<tag>. Registry setup may still be running — wait and retry." >&2; exit 1 ;;
esac
echo "✓ media-recorder references the private registry: $IMG"
exit 0

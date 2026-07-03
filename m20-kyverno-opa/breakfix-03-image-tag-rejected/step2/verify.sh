#!/bin/bash
# Checks: call-recorder now rolls out — its Pod passes disallow-latest-tag because the image
# is pinned to a non-latest tag. Asserts the outcome (a Ready Pod on a non-latest image).
AVAIL=$(kubectl get deploy call-recorder -n tenant-apps -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
IMG=$(kubectl get deploy call-recorder -n tenant-apps \
  -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "${AVAIL:-0}" -ge 1 ] 2>/dev/null && [ -n "$IMG" ] && ! echo "$IMG" | grep -q ':latest$'; then
  echo "✓ call-recorder is Available on a pinned image ($IMG) — it now passes disallow-latest-tag"
  exit 0
fi
echo "call-recorder isn't Available on a pinned image yet (image: '${IMG:-<none>}'). Pin the tag to an explicit non-latest version (e.g. nginx:1.25), then wait for the rollout and retry." >&2
exit 1

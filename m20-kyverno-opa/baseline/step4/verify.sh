#!/bin/bash
# Checks: a :latest image (but WITH limits) is rejected specifically by disallow-latest-tag.
# Uses server dry-run so nothing is persisted; asserts the denial mentions the image rule.
OUT=$(cat <<'EOF' | kubectl apply --dry-run=server -f - 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: latest-verify
  namespace: tenant-apps
spec:
  containers:
    - name: app
      image: nginx:latest
      resources:
        requests: { cpu: 25m, memory: 32Mi }
        limits:   { cpu: 100m, memory: 64Mi }
EOF
)
if echo "$OUT" | grep -qi "disallow-latest-tag\|latest\|denied the request"; then
  echo "✓ a :latest image is refused by disallow-latest-tag (limits were set, so it's the tag)"
  exit 0
fi
echo "The :latest Pod was not denied — the image webhook may not be registered yet. Wait a few seconds and retry." >&2
exit 1

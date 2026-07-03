#!/bin/bash
# Checks: tenant-portal's running Pod now carries owner=platform. That requires BOTH the
# policy match corrected AND the Pod re-admitted (mutation is admission-time only), so this
# asserts the end state rather than either step alone.
OWNER=$(kubectl get pods -n tenant-apps -l app=tenant-portal \
  -o jsonpath='{.items[0].metadata.labels.owner}' 2>/dev/null)
if [ "$OWNER" = "platform" ]; then
  echo "✓ tenant-portal's Pod now carries owner=platform — policy match fixed and the Pod re-admitted"
  exit 0
fi
echo "tenant-portal's Pod still has no owner label (got: '${OWNER:-<none>}'). Correct the policy's namespaces to [tenant-apps], then 'kubectl rollout restart deployment/tenant-portal -n tenant-apps' to re-admit it, and retry." >&2
exit 1

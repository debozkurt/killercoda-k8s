#!/bin/bash
# Checks: the coordinator SA can now get/create/update leases — the leader-election
# lock is acquirable again. Asserts the permission (the root-cause fix), not the
# staged Lease. Impersonation via --as; the kubeadm admin context can impersonate.
for verb in get create update; do
  ANS=$(kubectl auth can-i "$verb" leases.coordination.k8s.io -n call-routing \
    --as=system:serviceaccount:call-routing:coordinator 2>/dev/null)
  if [ "$ANS" != "yes" ]; then
    echo "coordinator SA still cannot '$verb' leases (got '$ANS'). Restore get/list/watch/create/update/patch/delete on leases in the leader-election Role." >&2
    exit 1
  fi
done
echo "✓ coordinator SA can get/create/update leases — the leader-election lock is acquirable again"
exit 0

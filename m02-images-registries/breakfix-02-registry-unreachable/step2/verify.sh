#!/bin/bash
# Checks: account-provisioner is Ready and no longer points at the unreachable
# registry host. Asserts the outcome (pod runs) plus that the bogus host is gone.
IMG=$(kubectl get deploy account-provisioner -n provisioning -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
case "$IMG" in
  *registry.polyphone.example*) echo "Image still references the unreachable host: $IMG. Repoint it at a registry that resolves, e.g.: kubectl set image deployment/account-provisioner app=nginx:1.25 -n provisioning" >&2; exit 1 ;;
esac
READY=$(kubectl get pod -n provisioning -l app=account-provisioner -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
[ "$READY" = "true" ] || { echo "account-provisioner is not Ready yet (the new pod may still be pulling). Current image: $IMG" >&2; exit 1; }
echo "✓ account-provisioner is Ready; image resolves to a real registry: $IMG"
exit 0

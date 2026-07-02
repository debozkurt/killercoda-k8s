#!/bin/bash
# Checks: the allow policy's ingress peer is a namespaceSelector naming app-services
# (the thing that lets it reach across the namespace boundary), and that app-services
# actually carries the automatic kubernetes.io/metadata.name label the selector uses.
NS_SEL=$(kubectl get networkpolicy allow-broker-from-app -n media \
  -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}' 2>/dev/null)
if [ "$NS_SEL" != "app-services" ]; then
  echo "allow-broker-from-app's ingress peer doesn't name app-services via a namespaceSelector (got '$NS_SEL'). Wait for setup, or re-check the policy." >&2
  exit 1
fi
NS_LABEL=$(kubectl get namespace app-services \
  -o jsonpath='{.metadata.labels.kubernetes\.io/metadata\.name}' 2>/dev/null)
if [ "$NS_LABEL" != "app-services" ]; then
  echo "app-services is missing its automatic kubernetes.io/metadata.name label (got '$NS_LABEL')." >&2
  exit 1
fi
echo "✓ the allow crosses namespaces via a namespaceSelector, and app-services carries the matching name label"
exit 0

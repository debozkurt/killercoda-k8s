#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "A portal-web (admin-portal) release has been rolling out for minutes and"
echo "never completes. Users are unaffected — but the new version won't come up."
echo "Diagnose the stuck rollout:"
echo ""
echo "  kubectl get deployment portal-web -n admin-portal"
echo "  kubectl rollout status deployment/portal-web -n admin-portal --timeout=10s"
echo ""

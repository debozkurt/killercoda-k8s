#!/bin/bash

echo "Waiting for the Polyphone baseline + the admission webhook to spin up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10 namespaces + the"
echo " 17-workload fleet; issues a serving cert; deploys the admission-guard webhook server and"
echo " registers a mutating + a validating webhook scoped to 'tenant-apps'; then admits a bare"
echo " tenant-web Pod through both)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start with the webhook backend and the two objects that register it:"
echo ""
echo "  kubectl get pods -n admission"
echo "  kubectl get mutatingwebhookconfiguration,validatingwebhookconfiguration | grep admission-guard"
echo "  kubectl get pods -n tenant-apps -L env"
echo ""

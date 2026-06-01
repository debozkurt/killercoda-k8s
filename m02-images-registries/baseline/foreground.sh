#!/bin/bash

echo "Waiting for the Polyphone baseline + private registry to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s, crane; provisions 10"
echo " namespaces and the 17-workload fleet; stands up an authenticated registry at"
echo " localhost:5000 and pushes polyphone/media-recorder into it; deploys the consumer)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by reading image references off the fleet:"
echo ""
echo "  kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.containers[*].image}{\"\\n\"}{end}' | sort -u"
echo "  kubectl get pods -n media -l app=media-recorder"
echo ""
echo "(media-recorder pulls from the private registry at localhost:5000 — the rest"
echo " of the fleet pulls nginx:1.25 anonymously from Docker Hub.)"
echo ""

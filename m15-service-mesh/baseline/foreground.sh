#!/bin/bash

echo "Waiting for the Polyphone baseline + Istio to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s, and Istio (minimal"
echo " profile); labels 'media' for sidecar injection; provisions 10 namespaces +"
echo " the 17-workload fleet; then applies a healthy VirtualService / DestinationRule"
echo " / PeerAuthentication for session-broker and a long-lived mesh-client)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by seeing which pods joined the mesh:"
echo ""
echo "  kubectl get pods -n media          # meshed pods show 2/2 (app + istio-proxy)"
echo "  istioctl proxy-status              # every sidecar and its config-sync state"
echo ""
echo "(Traffic is driven from the in-mesh mesh-client via kubectl exec; the fleet's"
echo " own nginx pods don't make outbound calls.)"
echo ""

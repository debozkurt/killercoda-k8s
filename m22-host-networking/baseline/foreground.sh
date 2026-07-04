#!/bin/bash

echo "Waiting for the Polyphone baseline (+ Multus + the host-network workloads) to come up..."
echo "(installs local-path-provisioner, metrics-server, k9s, Multus CNI; provisions the"
echo " 17-workload fleet plus rtp-relay / sip-edge / media-probe / rtp-ingress)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start with the hostNetwork relay and how its Pod IP compares"
echo "to the node's own IP:"
echo ""
echo "  kubectl get pod -n media -l app=rtp-relay -o wide"
echo "  kubectl get nodes -o wide"
echo ""

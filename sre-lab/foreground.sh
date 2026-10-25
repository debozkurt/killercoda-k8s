#!/bin/bash
# Runs in the foreground — the participant sees this output.
# Waits for the background setup to finish before handing control.

echo "Preparing your cluster environment..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
    sleep 2
done

echo "Environment ready! 8 namespaces have been deployed across the cluster."
echo ""
echo "Start with:  kubectl get pods -A"
echo ""

#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo "Waiting for the failing workload's first event..."
for i in $(seq 1 30); do
  kubectl events -A --types=Warning 2>/dev/null | grep -q FailedMount && break
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "A workload that loads call rates never started, and nobody knows where."
echo "Start with the default namespace, then widen the search:"
echo ""
echo "  kubectl events"
echo "  kubectl events -A --types=Warning"
echo ""

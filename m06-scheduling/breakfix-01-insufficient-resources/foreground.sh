#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "stream-analyzer (analytics) has no running Pod — it's stuck Pending."
echo "The scheduler couldn't place it. Read why, in one command:"
echo ""
echo "  kubectl get pods -n analytics"
echo "  kubectl describe pod -n analytics -l app=stream-analyzer | grep -A6 Events"
echo ""

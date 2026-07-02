#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "session-logger (app-services) is Running 1/1, but its logs look empty."
echo "See for yourself:"
echo ""
echo "  kubectl get pods -n app-services -l app=session-logger"
echo "  kubectl logs -n app-services deploy/session-logger"
echo ""

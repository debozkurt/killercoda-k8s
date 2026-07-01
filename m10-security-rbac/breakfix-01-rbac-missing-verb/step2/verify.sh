#!/bin/bash
# Checks: the endpoint-watcher SA can now `list endpoints` in media — the
# authorization decision this scenario fixes. Deterministic and immediate,
# independent of the Pod's CrashLoop backoff timer.
CAN=$(kubectl auth can-i list endpoints -n media \
  --as=system:serviceaccount:media:endpoint-watcher 2>/dev/null)
if [ "$CAN" != "yes" ]; then
  echo "endpoint-watcher still cannot 'list endpoints' in media (auth can-i = '$CAN'). Add the 'list' verb to Role endpoint-reader, e.g.: kubectl patch role endpoint-reader -n media --type=json -p '[{\"op\":\"replace\",\"path\":\"/rules/0/verbs\",\"value\":[\"get\",\"list\",\"watch\"]}]'" >&2
  exit 1
fi
echo "✓ endpoint-watcher can now list endpoints in media — the Role grants the 'list' verb"
exit 0

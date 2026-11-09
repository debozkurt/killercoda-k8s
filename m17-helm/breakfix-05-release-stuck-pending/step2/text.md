# Step 2 — Clear the lock and verify

A rollback does not check for a pending revision. It writes a new revision whose status is `deployed`, and that new revision becomes the latest. Do not delete the revision Secrets by hand: that removes history, and a wrong delete removes the record of the revision that runs now.

## Roll back to revision 1

```bash
helm rollback voicemail 1 -n app-services
kubectl rollout status deployment/voicemail -n app-services --timeout=60s
helm history voicemail -n app-services
```{{exec}}

Revision 3 reads `deployed`, `Rollback to 1`. Revision 2 keeps `pending-upgrade` in the history, but only the latest revision counts for the lock. The `Pending` Pod is gone.

## Ship the greeting

```bash
helm upgrade voicemail /root/voicemail --namespace app-services --reuse-values \
  --set config.greeting="Please leave a message after the tone."
```{{exec}}

Revision 4 is `deployed`.

## Verify

```bash
kubectl get pods -n app-services -l app=voicemail
kubectl describe deployment voicemail -n app-services | grep -A3 'Environment:'
```{{exec}}

Two Pods run, and `GREETING` shows the new text. `--reuse-values` carried revision 3's values forward, so the memory stays at the healthy 32Mi request.

# Step 1 — An upgrade that will not start

## Run the upgrade

```bash
helm upgrade voicemail /root/voicemail --namespace app-services --reuse-values \
  --set config.greeting="Please leave a message after the tone."
```{{exec}}

`Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress`. Helm stopped before it rendered or applied anything.

## Read the release record

```bash
helm status voicemail -n app-services | head -7
helm history voicemail -n app-services
```{{exec}}

The latest revision is 2, with `STATUS: pending-upgrade` and the description `Preparing upgrade`. Helm writes a revision as pending **before** it applies, and changes the status when the operation ends. An upgrade refuses to start while the latest revision is pending.

```bash
pgrep -a helm || echo 'no helm process'
kubectl get secret -n app-services -l owner=helm --show-labels
```{{exec}}

No Helm process runs. The revision 2 Secret carries `status=pending-upgrade`. The cancelled job never finished the operation, so nothing will ever clear this status on its own.

## See what the interrupted upgrade applied

```bash
kubectl get pods -n app-services -l app=voicemail
kubectl describe pod <name-of-the-pending-pod> -n app-services | tail -4
```

One Pod is `Pending`, and its `FailedScheduling` event includes `Insufficient memory`. Revision 2 asked for 64Gi. The two revision 1 Pods still serve.

# Step 2 — Fix it and verify

The fix is to set the value at the key the chart reads: `replicaCount`, not `replicas`.

## Upgrade with the correct key

`--reuse-values` keeps the required `sipRealm` from the current release so you only state what changes:

```bash
helm upgrade voicemail /root/voicemail \
  --namespace app-services \
  --reuse-values \
  --set replicaCount=3
```{{exec}}

`helm upgrade` re-renders with the corrected value and records a new revision. Watch the pods scale out:

```bash
kubectl get pods -n app-services -l app=voicemail -w
```{{exec}}

Once you see three `Running`, press `Ctrl-C`.

## Confirm it took this time

```bash
helm get manifest voicemail -n app-services | grep -E "replicas:"
```{{exec}}

`replicas: 3` — the rendered manifest now matches intent, because the value landed on the key the template reads.

```bash
kubectl get deployment voicemail -n app-services
```{{exec}}

`READY 3/3`.

## The durable fix

`--set` fixes the live release, but the values *file* on disk still says `replicas: 3` — the next person who installs from it hits the same wall. The real fix corrects the file:

```bash
sed -i 's/^replicas:/replicaCount:/' /root/voicemail-values.yaml
cat /root/voicemail-values.yaml
```{{exec}}

In production that file lives in git and the correction is a reviewed commit, not an in-place `sed`. For the full contrast — `--set` triage vs the values-in-git source of truth — see [ANSWER-KEY.md](../ANSWER-KEY.md).

You're done with breakfix-01. See `finish.md`.

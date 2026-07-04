# Step 2 — Fix it and verify

The `voicemail` release `dependsOn` a HelmRelease named `message-cache` that doesn't exist. The real backing store is `message-store`. Point the dependency at the release that's actually there.

## Correct the dependency

```bash
kubectl patch helmrelease voicemail -n flux-system \
  --type=merge -p '{"spec":{"dependsOn":[{"name":"message-store"}]}}'
```{{exec}}

Then reconcile so helm-controller re-checks the dependency and installs:

```bash
flux reconcile helmrelease voicemail
```{{exec}}

With `message-store` already `Ready`, the dependency gate opens and helm-controller renders the chart and installs the release. Confirm:

```bash
flux get helmreleases
```{{exec}}

`voicemail` is now `READY True`, with an installed revision.

## Confirm the workload came up

```bash
helm list -n app-services
kubectl get deploy voicemail -n app-services
```{{exec}}

The `voicemail` release is `deployed` and its Deployment is `2/2`. The dependency was the only thing holding it back.

## The durable fix

The `kubectl patch` fixes this cluster. The lasting fix corrects the `dependsOn` name in the `HelmRelease` manifest in git — a `dependsOn` that names a nonexistent object is exactly the kind of typo or stale-rename that a reviewed commit (and, ideally, CI that validates references) catches before it ships. A dependency should also be a real ordering need: only list objects the release genuinely requires first, because every `dependsOn` is another thing that can block it. For the triage-vs-durable discussion, see [ANSWER-KEY.md](../ANSWER-KEY.md).

You're done with breakfix-03, and with M18. See `finish.md`.

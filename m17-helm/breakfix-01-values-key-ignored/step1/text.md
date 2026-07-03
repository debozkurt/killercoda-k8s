# Step 1 — Why the override did nothing

The release is `deployed` and the values file says 3 replicas. Start where the alert points.

## Confirm the gap

```bash
helm get values voicemail -n app-services
```{{exec}}

You supplied `replicas: 3` and `config.sipRealm`. That's what you asked for.

```bash
kubectl get deployment voicemail -n app-services
```{{exec}}

`READY 1/1`. One pod. The release says 3, the cluster says 1. The value didn't take.

## Read what actually rendered

`helm get values` shows what you *asked for*. `helm get manifest` shows what Helm *rendered and applied*:

```bash
helm get manifest voicemail -n app-services | grep -E "replicas:"
```{{exec}}

`replicas: 1`. So the template rendered the default, not your 3. The override never reached the manifest.

## Find the key path the chart actually reads

Look at the effective (merged) values — everything Helm computed, defaults included:

```bash
helm get values voicemail -n app-services -a
```{{exec}}

Read it carefully. You'll see **both**:

```text
replicaCount: 1     <- what the template reads (chart default)
replicas: 3         <- what you set (a key nothing reads)
```

Your `replicas` sits in the values, untouched, doing nothing. Confirm which key the chart consumes:

```bash
helm show values /root/voicemail | grep -i replica
```{{exec}}

The chart's key is **`replicaCount`**. The template contains `replicas: {{ .Values.replicaCount }}` — it never looks at `.Values.replicas`. Helm doesn't validate override keys against the chart, so a typo or wrong path is kept silently and simply never used.

That's the whole bug: **right value, wrong key path.** Move to step 2 to fix it.

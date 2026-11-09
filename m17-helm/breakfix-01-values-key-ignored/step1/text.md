# Step 1 — Where the value went

Start with what the release was asked for, then compare it with what runs.

## Compare the request with the result

```bash
helm get values voicemail -n app-services
kubectl get deployment voicemail -n app-services
```{{exec}}

The user-supplied values include a 3. The Deployment reads `READY` 1/1.

## Read what Helm rendered

`helm get values` shows the input. `helm get manifest` shows the output that Helm applied. The manifest is longer than a screen, so filter it:

```bash
helm get manifest voicemail -n app-services | grep 'replicas:'
```{{exec}}

`replicas: 1`. The render did not use the 3, so the problem is between the input and the template.

## Read the computed values

`-a` prints every value the render used, chart defaults included:

```bash
helm get values voicemail -n app-services -a
```{{exec}}

Two keys sit next to each other: `replicaCount: 1` and `replicas: 3`. Only one of them can be the key the template reads.

```bash
helm show values /root/voicemail
cat /root/voicemail/templates/deployment.yaml
```{{exec}}

The chart defines `replicaCount`, and the template line reads `replicas: {{ .Values.replicaCount }}`. Nothing reads `.Values.replicas`. Helm does not check override keys against the chart, so it stored the unused key and rendered the default.

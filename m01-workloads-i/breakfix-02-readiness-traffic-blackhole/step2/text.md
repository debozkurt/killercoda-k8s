# Step 2 — Fix it and verify

The container serves on `80`; the readiness probe checks `8080`. Point the probe at the port the app actually listens on.

## Apply the fix

Edit the Deployment (the ReplicaSet will roll new Pods). Patch the readiness probe port to `80` — or to the named port `http`, which is cleaner because it survives a port-number change:

```bash
kubectl patch deployment directory -n app-services --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":"http"}]'
```{{exec}}

Or by hand:

```bash
kubectl edit deployment directory -n app-services
# under readinessProbe.httpGet, change  port: 8080  to  port: http   (or 80)
```

## Watch readiness recover

```bash
kubectl rollout status deployment directory -n app-services
```{{exec}}

`successfully rolled out` — the new Pods probe `:80`, nginx answers `200`, and their `Ready` condition flips to true.

## Confirm endpoints repopulate

The real proof isn't the pod status — it's that the Service has backends again:

```bash
kubectl get endpoints directory -n app-services
```{{exec}}

The `ENDPOINTS` column now lists `IP:80` entries — one per ready Pod. Traffic flows again; the alert clears.

```bash
kubectl get pods -n app-services -l app=directory
```{{exec}}

`Running`, `1/1 READY`. The blackhole is closed.

For self-grading, the liveness-vs-readiness contrast, and the production angle (a readiness probe tied to a flaky dependency can blackhole *every* replica at once — see the answer key), check [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.

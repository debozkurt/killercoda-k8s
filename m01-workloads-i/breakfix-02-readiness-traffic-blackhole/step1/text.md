# Step 1 — Diagnose the blackhole

Callers get nothing, but the pods are `Running`. The headline lies. Read past it to the `READY` column and the Service's endpoints.

## Look past the phase

```bash
kubectl get pods -n app-services -l app=directory
```{{exec}}

The pod: `STATUS=Running`, but `READY` shows `0/1`, and `RESTARTS=0`. That combination is the signature of this failure — *running, not ready, not restarting.* Compare it to breakfix-01: a liveness failure climbs the restart count; a readiness failure does neither. Readiness gates traffic, not lifecycle.

## Confirm the blackhole at the Service

A Service routes only to Pods whose `Ready` condition is true. If nothing is Ready, the Service has nowhere to send traffic.

```bash
kubectl get endpoints directory -n app-services
```{{exec}}

The `ENDPOINTS` column reads `<none>` (or shows only `notReadyAddresses` under `-o yaml`). That's the blackhole — the Service exists, the DNS name resolves, but there are zero backends. Callers connect to the Service IP and get nothing, exactly as the alert says.

## Ask why the Pod isn't Ready

```bash
POD=$(kubectl get pod -n app-services -l app=directory -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD -n app-services
```{{exec}}

In the `Conditions:` block you'll see `Ready  False`, and at the bottom the `Events:` section shows:

```text
  Warning  Unhealthy  ...  Readiness probe failed: dial tcp 10.x.x.x:8080: connect: connection refused
```

`connection refused` on `8080` — the kubelet tried to probe a port nothing is listening on. Note there's **no** `Killing` event: readiness failures never restart the container. The process is up and fine; it's just been pulled from rotation.

## Read the probe that's wrong

```bash
kubectl describe deploy directory -n app-services
```{{exec}}

In the `Pod Template` section, compare two lines — the port the container exposes against the port the readiness probe checks:

```text
    Port:       80/TCP
    Readiness:  http-get http://:8080/ delay=0s timeout=1s period=10s #success=1 #failure=3
```

The container serves on `80`, but the readiness probe checks `8080`. Wrong port, so the probe can never pass, so the Pod is never Ready, so the Service blackholes. On to the fix.

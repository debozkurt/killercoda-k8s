# Step 3 — The three probes

`sip-app` runs all three probes. Each answers a different question and does a different thing on failure. Confusing them is the most common probe mistake there is, so see them configured correctly first.

## Read the probes off the live spec

```bash
kubectl describe pod -n app-services -l app=sip-app | grep -A1 -E 'Liveness|Readiness|Startup'
```{{exec}}

You'll see three lines like `http-get http://:http/ delay=0s timeout=1s period=...`. Three probes, one container:

- **Startup** — "has it finished booting?" Until it passes once, liveness and readiness are suppressed. Protects slow starters without inflating liveness delays.
- **Readiness** — "can it serve traffic right now?" On failure the Pod is pulled from Service Endpoints. **No restart.**
- **Liveness** — "is it wedged?" On failure the kubelet **restarts** the container.

## See readiness wired into the Service

Readiness isn't cosmetic — it's the gate for traffic. A Service only routes to Pods whose `Ready` condition is true. Check the Endpoints behind the `sip-app` Service:

```bash
kubectl get endpoints sip-app -n app-services
```{{exec}}

You'll see two `IP:80` entries — one per ready Pod. Those addresses *are* the Service's routing targets. The link is direct: **readiness passes → Pod is Ready → its IP appears in Endpoints → the Service routes to it.** Fail readiness and the IP disappears from this list while the Pod keeps running. (Services and EndpointSlices get the full treatment in M04; here you just need the readiness → Endpoints link.)

## Confirm the Ready condition

```bash
kubectl get pod -n app-services -l app=sip-app \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```{{exec}}

Both Pods report `Ready = True`. That condition is what readiness flips and what Endpoints watches.

## Verify

```bash
kubectl get endpoints sip-app -n app-services -o jsonpath='{.subsets[0].addresses[*].ip}'; echo
```{{exec}}

Two IPs listed — both replicas in rotation. That's a healthy, serving workload. In `breakfix-02` you'll find this list *empty* while the Pods are still `Running`: the readiness-vs-liveness distinction made painfully concrete.

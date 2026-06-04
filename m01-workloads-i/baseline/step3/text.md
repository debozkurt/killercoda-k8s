# Step 3 — The three probes

`sip-app` runs all three probes. Each answers a different question and does a different thing on failure. Confusing them is the most common probe mistake there is, so see them configured correctly first.

## Read the probes off the live spec

```bash
kubectl describe pod -n app-services -l app=sip-app
```{{exec}}

Under the `Containers:` section, three lines sit together — one per probe:

```text
    Liveness:   http-get http://:http/ delay=0s timeout=1s period=10s ...
    Readiness:  http-get http://:http/ delay=0s timeout=1s period=10s ...
    Startup:    http-get http://:http/ delay=0s timeout=1s period=10s ...
```

Three probes, one container:

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
kubectl describe pod -n app-services -l app=sip-app
```{{exec}}

This time read the `Conditions:` block (above `Containers:`):

```text
Conditions:
  Type              Status
  Ready             True
```

Both Pods report `Ready  True`. That condition is what readiness flips and what Endpoints watches — and it's the same value the `READY 1/1` column in `kubectl get pods` summarizes.

## See what the probe sees — `exec` and ephemeral debug

The readiness probe does an `httpGet` on `/`. You can run the same check by hand. If the image has a shell, `kubectl exec` runs a command *inside* the container:

```bash
kubectl exec deploy/sip-app -n app-services -- nginx -v
```{{exec}}

That runs one-shot in the running container (add `-it -- sh` for an interactive shell). But many production images are **distroless** — no shell, no `curl` — so `exec` has nothing to run. For those, attach an **ephemeral container** with `kubectl debug`: a throwaway container that joins the Pod's namespaces, bringing its own tools without changing the Pod.

```bash
POD=$(kubectl get pod -n app-services -l app=sip-app -o jsonpath='{.items[0].metadata.name}')
kubectl debug -it $POD -n app-services --image=busybox:1.36 -- wget -qO- http://localhost:80/
```{{exec}}

Because the ephemeral container shares the Pod's network namespace, `localhost:80` *is* the app container — so you're hitting exactly the endpoint the readiness probe hits, and you'll see nginx's HTML (an HTTP `200`). That's the probe's-eye view, and `kubectl debug` is how you get it on a Pod you can't `exec` into. (Ctrl-D to exit; the ephemeral container stays in the Pod's spec — they're stopped, never removed.)

## Verify

```bash
kubectl get endpoints sip-app -n app-services
```{{exec}}

The `ENDPOINTS` column lists two `IP:80` entries — both replicas in rotation. That's a healthy, serving workload. In `breakfix-02` you'll find this list *empty* while the Pods are still `Running`: the readiness-vs-liveness distinction made painfully concrete.

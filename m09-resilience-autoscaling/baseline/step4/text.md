# Step 4 — Graceful shutdown

A rolling update and a node drain both do the same underlying thing over and over: they *terminate a Pod*. Whether that costs you dropped calls depends on how the Pod shuts down. Kubernetes gives every Pod a graceful-termination sequence; the question is whether the app uses it.

## Read the grace period

```bash
kubectl get pod -n call-routing -l app=route-engine \
  -o jsonpath='{.items[0].spec.terminationGracePeriodSeconds}'; echo
```{{exec}}

`30` — the default. That's how long the kubelet waits, after asking a container to stop, before it forces the issue.

## The termination lifecycle

When a Pod is deleted (by a rollout, a drain, a scale-down), several things happen at once:

1. The Pod is marked `Terminating` and **removed from its Service's Endpoints** — new traffic stops being routed to it (this is why a readiness probe going false, from M01, and termination both pull a Pod out of rotation).
2. The container's **`preStop` hook** runs, if it has one (a place to drain connections or deregister).
3. The container gets **`SIGTERM`** — the polite "please stop" signal. A well-behaved app catches it, stops accepting new work, finishes in-flight requests, and exits.
4. If the container is still alive when `terminationGracePeriodSeconds` elapses, it gets **`SIGKILL`** — the non-negotiable kill.

So the grace period is a *budget* for steps 2–3. Set it long enough and an app that handles `SIGTERM` drains cleanly; set it too short (or ignore `SIGTERM`) and the app is `SIGKILL`ed mid-request. Watch a clean termination — delete one replica and the Deployment immediately replaces it:

```bash
kubectl delete pod -n call-routing -l app=route-engine --wait=false
kubectl get pods -n call-routing -l app=route-engine -w --request-timeout=20s
```{{exec}}

You'll see one Pod go `Terminating` while a replacement goes `Pending → Running`. (Press `Ctrl-C` to stop watching.) The service never fully drops because the other replica keeps serving — the same overlap a rolling update relies on.

The three pieces of this module compose here: a **rolling update** terminates Pods one batch at a time, a **PDB** caps how many terminate at once during a drain, and **graceful shutdown** makes each individual termination lossless. Get all three right and you patch nodes and ship releases without a blip. The probe and `preStop` mechanics behind step 1's readiness removal were covered in M01. You've now seen the healthy machinery end to end — read [`LESSON.md`](../LESSON.md) for the *why*, then break three pieces of it. See `finish.md`.

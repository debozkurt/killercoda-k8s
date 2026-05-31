# Step 2 — Pod lifecycle and restartPolicy

A Pod has a coarse **phase** and a finer-grained **container state**. Healthy looks boring here — that's the point. Learn the boring shape so the broken shape jumps out later.

## Read the phase

```bash
kubectl get pods -n app-services -l app=sip-app \
  -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount
```{{exec}}

Both Pods: `PHASE=Running`, `READY=true`, `RESTARTS=0`. The phase (`Pending → Running → Succeeded/Failed`) is the headline. `READY` and `RESTARTS` are where the truth lives — a Pod can be `Running` and `READY=false`, or `Running` with dozens of restarts. Phase alone never means healthy.

## Look at the container state

```bash
kubectl get pod -n app-services -l app=sip-app \
  -o jsonpath='{.items[0].status.containerStatuses[0].state}'; echo
```{{exec}}

You'll see `{"running":{"startedAt":"..."}}`. A container is always in one of three states — `waiting`, `running`, `terminated` — and when something's wrong, `waiting.reason` or `terminated.reason` carries the diagnosis (`CrashLoopBackOff`, `ImagePullBackOff`, `OOMKilled`, `Error`). This field is the first thing to read on a sick Pod.

## Check the restartPolicy

When a container exits, `restartPolicy` decides what happens next.

```bash
kubectl get pod -n app-services -l app=sip-app \
  -o jsonpath='{.items[0].spec.restartPolicy}'; echo
```{{exec}}

It prints `Always` — the default, and the only value a Deployment permits. `Always` means any exit (clean or not) gets restarted, with exponential backoff between attempts. (Jobs use `OnFailure`/`Never`; you'll meet those in M07.) The backoff is what surfaces as `CrashLoopBackOff` — the kubelet *waiting* between restarts, not the crash itself.

## Verify

```bash
kubectl get pods -n app-services -l app=sip-app
```{{exec}}

Two Pods, `Running`, `1/1 READY`, `0` restarts, `restartPolicy=Always`. That's a healthy lifecycle: started cleanly, staying up, nothing restarting it. In `breakfix-01` you'll see the same `get pods` output with a climbing restart count — and learn to tell a real crash from a probe killing a healthy process.

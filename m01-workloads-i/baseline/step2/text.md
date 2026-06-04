# Step 2 — Pod lifecycle and restartPolicy

A Pod has a coarse **phase** and a finer-grained **container state**. Healthy looks boring here — that's the point. Learn the boring shape so the broken shape jumps out later.

## Read the phase

```bash
kubectl get pods -n app-services -l app=sip-app
```{{exec}}

Both Pods: `STATUS=Running`, `READY=1/1`, `RESTARTS=0`. The status (`Pending → Running → Succeeded/Failed`, or a reason like `CrashLoopBackOff`) is the headline. `READY` and `RESTARTS` are where the truth lives — a Pod can be `Running` and `0/1 READY`, or `Running` with dozens of restarts. Status alone never means healthy.

## Look at the container state

```bash
kubectl describe pod -n app-services -l app=sip-app
```{{exec}}

Under the `Containers:` section, find the container's `State:` line:

```text
    State:          Running
      Started:      ...
```

A container is always in one of three states — `Waiting`, `Running`, `Terminated` — and when something's wrong, the `Reason:` beneath `State:` (or under `Last State:`) carries the diagnosis (`CrashLoopBackOff`, `ImagePullBackOff`, `OOMKilled`, `Error`). This is the first thing to read on a sick Pod.

## Check the restartPolicy

When a container exits, `restartPolicy` decides what happens next. It's a spec field, so read it off the Deployment's YAML:

```bash
kubectl get deploy sip-app -n app-services -o yaml
```{{exec}}

Scroll to the pod template's `spec:` (just below `containers:`) and find:

```text
      restartPolicy: Always
```

`Always` is the default, and the only value a Deployment permits. `Always` means any exit (clean or not) gets restarted, with exponential backoff between attempts. (Jobs use `OnFailure`/`Never`; you'll meet those in M07.) The backoff is what surfaces as `CrashLoopBackOff` — the kubelet *waiting* between restarts, not the crash itself.

## Verify

```bash
kubectl get pods -n app-services -l app=sip-app
```{{exec}}

Two Pods, `Running`, `1/1 READY`, `0` restarts, `restartPolicy=Always`. That's a healthy lifecycle: started cleanly, staying up, nothing restarting it. In `breakfix-01` you'll see the same `get pods` output with a climbing restart count — and learn to tell a real crash from a probe killing a healthy process.

# Step 1 — Diagnose the failing Job

A Job at `COMPLETIONS 0/1` is either still retrying or has given up. Read its state, then ask the pods *why* every attempt dies.

## Read the Job's state

```bash
kubectl get job schema-migrate -n provisioning
```{{exec}}

`COMPLETIONS 0/1` — zero successes after one required. Now find out whether it's still trying. Read the spec bound and the live status together:

```bash
kubectl get job schema-migrate -n provisioning \
  -o jsonpath='backoffLimit={.spec.backoffLimit} restartPolicy={.spec.template.spec.restartPolicy}{"\n"}failed={.status.failed} conditions={.status.conditions[*].type}{"\n"}'
```{{exec}}

`backoffLimit=6`, `restartPolicy=OnFailure`. The `failed` count and `conditions` tell you which state you're in:

- `conditions` empty or no `Failed` → still **retrying** (attempts remain under the limit)
- `conditions=Failed` → **given up**; `backoffLimit` exhausted, no more attempts coming

Either way the root cause is the same — every attempt fails — and the fix is the same. `restartPolicy: OnFailure` means the kubelet retries the *same* pod in place, so you'll see one pod with a climbing `RESTARTS` count rather than a pile of new pods:

```bash
kubectl get pods -n provisioning -l app=schema-migrate
```{{exec}}

One pod, `RESTARTS` climbing (and likely `CrashLoopBackOff` between attempts — the same backoff you saw in M01, now inside a Job). The pod isn't being killed by a probe this time; it's *actually exiting non-zero*. Prove it by reading what it says.

## Ask the pod why it dies

```bash
kubectl logs job/schema-migrate -n provisioning
```{{exec}}

`kubectl logs job/<name>` reads the Job's pod. The output gets through the early steps and then dies on a shell error:

```text
[schema-migrate] connecting to postgres.polyphone.example
[schema-migrate] applying 001_init
/bin/sh: ecaho: not found
```

There it is. The final migration step calls `ecaho` — a typo for `echo` — which the shell can't find, so the command exits `127` (command-not-found). Every attempt dies at the same line. This is a genuine non-zero exit, not a probe kill: confirm in `describe` that the container's last state is `Terminated` with a non-zero exit code, and that the Job is counting failures toward `backoffLimit`:

```bash
POD=$(kubectl get pod -n provisioning -l app=schema-migrate -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD -n provisioning | grep -A4 'Last State'
```{{exec}}

`Reason: Error`, `Exit Code: 127`. The app *is* failing — it's a broken command, and no number of retries will fix a typo. On to the fix.

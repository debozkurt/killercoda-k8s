# Step 2 — Run-to-completion and restartPolicy

A Deployment Pod is *supposed* to run forever; if it exits, that's a failure to correct. A Job Pod is *supposed* to exit; a clean exit is the goal. That inversion drives every rule here.

## A Job that already finished

```bash
kubectl get job schema-migrate -n provisioning
```{{exec}}

`COMPLETIONS 1/1`, and a `DURATION` — it ran once, the Pod exited 0, the Job marked itself Complete and stopped. There is no "keep running": once the completion count is met, the Job is done. Read what the Pod actually did:

```bash
kubectl logs job/schema-migrate -n provisioning
```{{exec}}

`kubectl logs job/<name>` follows the Job to its Pod — you don't have to look up the Pod name. You'll see the migration steps print and then `[schema-migrate] done`. The Pod is `Completed`, not `Running`:

```bash
kubectl get pods -n provisioning -l app=schema-migrate
```{{exec}}

`STATUS Completed`, `RESTARTS 0`. A Completed Pod is the batch success state — the equivalent of a Deployment Pod sitting at `Running`.

## restartPolicy: why a Job can't use Always

```bash
kubectl get job schema-migrate -n provisioning \
  -o jsonpath='restartPolicy={.spec.template.spec.restartPolicy}{"\n"}backoffLimit={.spec.backoffLimit}{"\n"}'
```{{exec}}

`restartPolicy=OnFailure`, `backoffLimit=4`. A Job allows only `OnFailure` or `Never` — never `Always`. The reason is mechanical: `Always` means "restart the container on *any* exit, including a clean one," which would restart a successful Pod forever and the Job could never reach completion. The API rejects `Always` on a Job for exactly that reason.

The two legal values differ on failure:

- **`OnFailure`** — the kubelet restarts the *same* Pod's container in place. A failing Job shows one Pod with a climbing `RESTARTS` count.
- **`Never`** — the Job leaves the failed Pod and creates a *new* one. A failing Job shows a growing list of `Error` Pods, restart count stuck at 0.

`backoffLimit` is the give-up count: after that many failures the Job stops retrying and goes to `Failed`. Here it's 4. You'll watch this go wrong in `breakfix-02`, where every attempt fails and the Job retries to the limit.

## Verify

```bash
kubectl get job schema-migrate -n provisioning \
  -o jsonpath='{.metadata.name}: succeeded={.status.succeeded} conditions={.status.conditions[0].type}{"\n"}'
```{{exec}}

`succeeded=1`, `conditions=Complete`. That's a healthy run-to-completion Job: it ran, succeeded once, and is done. Compare with a Deployment, which has no "Complete" — only a perpetual `Available`.

# Step 2 — Fix it and verify

The command is broken (`ecaho` → `echo`). With a Deployment you'd patch the template and let it roll. **You can't do that with a Job** — its pod template is immutable. Try, and see:

```bash
kubectl patch job schema-migrate -n provisioning --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/command/2","value":"echo fixed"}]'
```{{exec}}

It's rejected: `field is immutable`. A Job represents one execution of a unit of work — mutating its template mid-run would mean different pods ran different code. So the fix is **delete and recreate**, not patch.

## Delete the broken Job

```bash
kubectl delete job schema-migrate -n provisioning
```{{exec}}

That removes the Job and its failed pods. Now apply a corrected one — same Job, `echo` instead of `ecaho`:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: schema-migrate
  namespace: provisioning
  labels: { app: schema-migrate, plane: control, tier: lab }
spec:
  backoffLimit: 6
  ttlSecondsAfterFinished: 3600
  template:
    metadata:
      labels: { app: schema-migrate, plane: control, tier: lab }
    spec:
      restartPolicy: OnFailure
      containers:
        - name: migrate
          image: busybox:1.36
          command: ["/bin/sh","-c","echo '[schema-migrate] connecting to postgres.polyphone.example'; echo '[schema-migrate] applying 001_init'; sleep 3; echo '[schema-migrate] done'"]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
EOF
```{{exec}}

(In a real shop the corrected manifest lives in Git, not a terminal heredoc — see the ANSWER-KEY production note.)

## Watch it complete

```bash
kubectl wait --for=condition=complete job/schema-migrate -n provisioning --timeout=60s
```{{exec}}

`kubectl wait` blocks until the Job's `Complete` condition is true — cleaner than polling `get`. It returns `condition met` within ~5 seconds. Read the logs to confirm the migration ran end-to-end this time:

```bash
kubectl logs job/schema-migrate -n provisioning
```{{exec}}

The output now reaches `[schema-migrate] done` — no shell error.

## Verify

```bash
kubectl get job schema-migrate -n provisioning
```{{exec}}

`COMPLETIONS 1/1`, with a `DURATION` — the migration succeeded and the release can proceed. For self-grading, the retrying-vs-given-up distinction, the `OnFailure` vs `Never` difference, and the GitOps fix, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.

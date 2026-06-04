# Step 2 — Fix it and verify

`completions` should be `4`, not `1`. Like `breakfix-02`, this is a Job, so `completions` is immutable — you delete and recreate, you don't patch. (Confirm it for yourself if you like: a `kubectl patch` of `/spec/completions` returns `field is immutable`.)

## Delete and recreate with the right size

```bash
kubectl delete job usage-export -n analytics
```{{exec}}

Apply the corrected Job — `completions: 4`, one pod per daily shard, still 2 at a time:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: usage-export
  namespace: analytics
  labels: { app: usage-export, plane: control, tier: lab }
spec:
  completions: 4
  parallelism: 2
  backoffLimit: 4
  ttlSecondsAfterFinished: 3600
  template:
    metadata:
      labels: { app: usage-export, plane: control, tier: lab }
    spec:
      restartPolicy: OnFailure
      containers:
        - name: export
          image: busybox:1.36
          command: ["/bin/sh","-c","echo '[usage-export] processing a usage shard'; sleep 4; echo '[usage-export] shard complete'"]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
EOF
```{{exec}}

## Watch all four shards run

```bash
kubectl get pods -n analytics -l app=usage-export -w
```{{exec}}

Four pods this time, two `Running` at once (that's `parallelism: 2`), each going to `Completed`. Ctrl-C once you've seen four. Then wait for the Job to report done:

```bash
kubectl wait --for=condition=complete job/usage-export -n analytics --timeout=60s
```{{exec}}

## Verify

```bash
kubectl get job usage-export -n analytics
```{{exec}}

`COMPLETIONS 4/4`, `STATUS Complete`. All four shards exported; downstream gets the full day. This time `Complete` and `correct` agree.

For self-grading, why this bug is so dangerous, and the `completionMode: Indexed` technique for making sharded work diagnosable, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.

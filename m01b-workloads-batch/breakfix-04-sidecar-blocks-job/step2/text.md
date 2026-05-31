# Step 2 — Fix it and verify

The log-shipper must run for the whole archive, then stop when the archive is done. That's exactly what a **native sidecar** does: an init container with `restartPolicy: Always`. The kubelet starts it before the main container, keeps it alive while the main container runs, and **terminates it once the main container exits** — so the Pod can complete and the Job finishes.

> Native sidecars need Kubernetes **v1.29+** (beta, on by default; GA in v1.33). This cluster runs v1.30. Confirm anytime with `kubectl version`.

## Move the helper to a native sidecar

Like the other Job breakfixes, a Job's pod template is immutable — you delete and recreate. The change: move `log-shipper` out of `containers` and into `initContainers`, and give it `restartPolicy: Always`.

```bash
kubectl delete job cdr-archive -n cdr-storage
```{{exec}}

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: cdr-archive
  namespace: cdr-storage
  labels: { app: cdr-archive, plane: control, tier: lab }
spec:
  backoffLimit: 4
  ttlSecondsAfterFinished: 3600
  template:
    metadata:
      labels: { app: cdr-archive, plane: control, tier: lab }
    spec:
      restartPolicy: Never
      initContainers:
        - name: log-shipper
          image: busybox:1.36
          restartPolicy: Always        # <-- this line makes it a NATIVE sidecar
          command: ["/bin/sh","-c","echo '[log-shipper] streaming logs'; tail -f /dev/null"]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
      containers:
        - name: archive
          image: busybox:1.36
          command: ["/bin/sh","-c","echo '[cdr-archive] archiving rolled-up CDRs to cold storage'; sleep 5; echo '[cdr-archive] archive complete'"]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
EOF
```{{exec}}

The only real change is *where* `log-shipper` lives and the one `restartPolicy: Always` line. Same image, same command.

## Watch it complete

```bash
kubectl get pods -n cdr-storage -l app=cdr-archive -w
```{{exec}}

This time the archive container runs, exits 0, and the kubelet then stops the native sidecar — the Pod goes to `Completed`. Ctrl-C once you see it. Then confirm the Job:

```bash
kubectl wait --for=condition=complete job/cdr-archive -n cdr-storage --timeout=60s
kubectl get job cdr-archive -n cdr-storage
```{{exec}}

## Verify

```bash
kubectl get job cdr-archive -n cdr-storage -o jsonpath='succeeded={.status.succeeded}{"\n"}'
```{{exec}}

`succeeded=1`, `COMPLETIONS 1/1` — the Job completes, the downstream hook fires, and no duplicate piles up. For self-grading, the multi-container completion rule, and why native sidecars exist, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.

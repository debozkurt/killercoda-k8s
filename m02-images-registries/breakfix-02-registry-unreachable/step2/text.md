# Step 2 — Fix it and verify

The repository and tag are correct; only the registry host is wrong. Point the reference at a registry that resolves. For this workload the image lives on Docker Hub, so dropping the bogus host restores it.

## Correct the reference

```bash
kubectl set image deployment/account-provisioner app=nginx:1.25 -n provisioning
```{{exec}}

`nginx:1.25` (no registry prefix) resolves to `docker.io/library/nginx:1.25` — a registry that exists and serves the image anonymously. The Deployment rolls a new pod, the kubelet resolves the host, and the pull succeeds.

Or by hand:

```bash
kubectl edit deployment account-provisioner -n provisioning
# change  image: registry.polyphone.example/library/nginx:1.25
# to      image: nginx:1.25   (the real registry for this image)
```

## In the real world, the host is the question

Here the fix is "use Docker Hub," but the real diagnostic question is *what registry was this image supposed to come from?* A `no such host` means the hostname is wrong, the registry is down, DNS is broken, or egress is blocked. The fix follows the cause: correct a typo, restore DNS, repoint at the live registry, or open the network path. The reference is just where the wrong answer was written down.

## Verify

```bash
kubectl get pods -n provisioning
kubectl describe deploy account-provisioner -n provisioning
```{{exec}}

`account-provisioner` is `Running` `1/1`, and in the `Pod Template` the `Image:` line now reads `nginx:1.25` — a registry that resolves. The pull reached the registry because the registry exists.

For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.

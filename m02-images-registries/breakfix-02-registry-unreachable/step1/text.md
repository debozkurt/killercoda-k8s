# Step 1 — Diagnose the failed pull

The status is `ImagePullBackOff` — but that's four different bugs wearing one label. The event message tells you which.

## Confirm the status, then ignore it

```bash
kubectl get pods -n provisioning
```{{exec}}

`account-provisioner` is `ImagePullBackOff`. Useful to know it's a pull problem; useless for knowing *which*. Don't guess "must be the pull secret" — read the error.

## Read the event message — this is the whole diagnosis

```bash
kubectl describe pod -n provisioning -l app=account-provisioner | sed -n '/Events/,$p'
```{{exec}}

The `Failed` event carries the runtime's actual error:

```text
Failed to pull image "registry.polyphone.example/library/nginx:1.25":
  failed to resolve reference ... dial tcp: lookup registry.polyphone.example
  on 10.96.0.10:53: no such host
```

`no such host` is the discriminator. The kubelet got far enough to *try*, but DNS couldn't resolve the registry hostname — so it never opened a connection, never authenticated, never asked about a manifest. Contrast the other branches you'll see:

```text
401 Unauthorized           → credentials rejected   (breakfix-03)
manifest unknown           → reference doesn't exist (breakfix-04)
no such host / i/o timeout  → registry unreachable   (THIS one)
```

## Look at the reference that won't resolve

```bash
kubectl get deploy account-provisioner -n provisioning \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```{{exec}}

`registry.polyphone.example/library/nginx:1.25`. The registry portion — `registry.polyphone.example` — is the host that doesn't exist. Someone pointed the workload at a registry that was never real, was decommissioned, or was a typo. The repository and tag are fine; the *registry* is the broken part of the reference. On to the fix.

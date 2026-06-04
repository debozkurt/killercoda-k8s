# Step 1 — Diagnose the unresolvable reference

Fourth `ImagePullBackOff`, fourth distinct cause. The event message tells you which branch — and this one rules out the previous two.

## Read the event

```bash
kubectl get pods -n app-services -l app=directory
kubectl describe pod -n app-services -l app=directory
```{{exec}}

Scroll to the `Events:` section at the bottom — the `Failed` event reads:

```text
Failed to pull image "nginx@sha256:000000...0000":
  failed to resolve reference ... docker.io/library/nginx@sha256:0000...:
  not found  (manifest unknown)
```

`manifest unknown` / `not found` is the discriminator. The host resolved (Docker Hub is reachable), the pull was accepted (nginx is public, no auth needed) — but the registry has no manifest matching that digest. The reference points at content that doesn't exist.

## Look at the reference

```bash
kubectl describe deploy directory -n app-services
```{{exec}}

In the `Pod Template` section, the container's `Image:` line reads:

```text
    Image:  nginx@sha256:0000000000…0000
```

It's pinned by **digest** (`@sha256:`), not by tag. The repository (`nginx`) is correct and the registry is fine — the *digest* is the broken part. A digest names exact bytes; this one names bytes the registry has never stored, so the pull fails closed.

## Find the digest that should be there

A digest pin should reference a real, published image. Ask the registry what digest the intended tag actually resolves to:

```bash
crane digest nginx:1.25
```{{exec}}

You'll get the real `sha256:…` for `nginx:1.25` — a digest that *does* exist. The bug is that the manifest was pinned to a digest that never matched any published image (a copy-paste error, a wrong promotion, a hand-edited sha). The fix is to pin a digest that resolves — or fall back to the tag. On to the fix.

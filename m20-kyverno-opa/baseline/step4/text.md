# Step 4 — Image admission gates the tag

The last policy gates *images* — the supply-chain question, *what is allowed to run here*. `disallow-latest-tag` refuses the mutable `:latest` tag, forcing an explicit, pinned version. `tenant-web` uses `nginx:1.25`, so it passed.

## Read the image rule

```bash
kubectl get clusterpolicy disallow-latest-tag -o yaml | grep -A6 'validate:'
```{{exec}}

Two rules: one requires the image to *not* match `*:latest` (`!*:latest`), the other requires a tag to be present (`*:*`). `:latest` means "whatever was pushed most recently" — the image under a running Pod could change with no manifest change, which is why the platform bans it.

## A `:latest` image is refused

```bash
cat <<'EOF' | kubectl apply --dry-run=server -f -
apiVersion: v1
kind: Pod
metadata:
  name: latest-test
  namespace: tenant-apps
spec:
  containers:
    - name: app
      image: nginx:latest
      resources:
        requests: { cpu: 25m, memory: 32Mi }
        limits:   { cpu: 100m, memory: 64Mi }
EOF
```{{exec}}

Denied by `disallow-latest-tag`, even though the Pod has limits (so `require-resource-limits` is satisfied). The denial names *which* policy failed — that's how you tell an image rejection from a limits rejection at a glance. `tenant-web`, with `nginx:1.25`, cleared this gate along with the other two.

That's a governed, compliant cluster: admission enforced, a default injected, images gated. Now go break each control — see `finish.md`.

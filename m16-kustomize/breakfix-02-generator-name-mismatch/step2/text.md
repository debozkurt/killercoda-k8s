# Step 2 — Align the names and verify

The generator is named `edge-relay-config`; the Deployment's `envFrom` asks for `edge-relay-conf`. Make the reference match the generator so Kustomize rewrites it to the hashed object it actually creates:

```bash
cd /root/edge-relay
sed -i 's/name: edge-relay-conf }/name: edge-relay-config }/' base/deployment.yaml
grep configMapRef base/deployment.yaml
```{{exec}}

Or edit by hand — `base/deployment.yaml`, the `configMapRef.name` under `envFrom`, `edge-relay-conf` → `edge-relay-config`.

(The mirror-image fix works too: rename the *generator* to `edge-relay-conf` in `base/kustomization.yaml`. Either way the two names must match — that match is what triggers the rewrite. Fix whichever side drifted; the config's established name is `edge-relay-config`.)

## Confirm the rewrite before applying

The render should now show the reference carrying the hash:

```bash
kubectl kustomize overlays/prod | grep -A1 configMapRef
```{{exec}}

`configMapRef.name` is now `edge-relay-config-<hash>` — the same hashed name as the generated ConfigMap. The reference resolves on paper; apply it:

```bash
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

## Verify

```bash
kubectl get pods -n edge -l app=edge-relay
REF=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')
kubectl get configmap "$REF" -n edge
```{{exec}}

Pods `Running` and `1/1`, and the ConfigMap the Deployment references now exists. The container found its config because the reference finally pointed at the object the generator built. For the full write-up see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.

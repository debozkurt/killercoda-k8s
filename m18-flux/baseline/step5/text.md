# Step 5 — Ship a change through git

In GitOps, a change to the cluster is a commit. `/root/polyphone-config` is a clone of the repo that Flux fetches, and its `origin` points at the same git server.

## Change, commit, push

Raise `dialplan` to 3 replicas in git:

```bash
cd /root/polyphone-config
sed -i 's/replicas: 2/replicas: 3/' apps/dialplan.yaml
git commit -am "dialplan: 3 replicas"
git push
```{{exec}}

## Watch the revision move

```bash
flux reconcile kustomization apps --with-source
flux get sources git
flux get kustomizations
```{{exec}}

`--with-source` makes the source fetch first. Both objects now show the new commit's hash. Compare it with `git log --oneline -1`.

```bash
kubectl get deploy dialplan -n app-services
```{{exec}}

3 replicas. Nobody ran `kubectl` against the Deployment.

## Delete a file and watch the prune

Remove the `dialplan-routes` ConfigMap from git:

```bash
git rm -q apps/dialplan-routes.yaml
sed -i '/dialplan-routes.yaml/d' apps/kustomization.yaml
git commit -am "dialplan: drop the routes ConfigMap"
git push
flux reconcile kustomization apps --with-source
```{{exec}}

```bash
kubectl get configmap dialplan-routes -n app-services
flux tree kustomization apps
```{{exec}}

`NotFound`, and the inventory lists only the Deployment. `prune: true` deleted the object that git no longer contains.

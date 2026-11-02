# Step 3 — Grant a permission and prove it

Give a new identity read access in one namespace, then prove what it can and cannot reach.

## Create the identity

```bash
kubectl create serviceaccount config-reader -n media
kubectl auth can-i list configmaps -n media --as=system:serviceaccount:media:config-reader
```{{exec}}

The answer is no. The account exists, so authentication works. No binding names it yet.

## Bind the built-in view ClusterRole in one namespace

```bash
kubectl create rolebinding config-reader-view -n media \
  --clusterrole=view --serviceaccount=media:config-reader
kubectl describe rolebinding config-reader-view -n media
```{{exec}}

Read the `Role:` block: `Kind: ClusterRole` and `Name: view`. Read `Subjects:`: the ServiceAccount `config-reader` in namespace `media`. A RoleBinding that references a ClusterRole grants those rules only in the RoleBinding's own namespace.

## Prove the decision and its edges

```bash
kubectl auth can-i list configmaps -n media     --as=system:serviceaccount:media:config-reader
kubectl auth can-i list configmaps -n signaling --as=system:serviceaccount:media:config-reader
kubectl auth can-i get secrets     -n media     --as=system:serviceaccount:media:config-reader
```{{exec}}

Expected: yes, no, no.

- The first is the grant.
- The second shows the scope: the binding lives in `media`, so `signaling` gets nothing.
- The third shows the role's content: `view` leaves Secrets out.

RBAC changes take effect on the next request. Nothing restarts. The change is in the binding, and nothing changed in the Pod or the account.

# Step 1 — Diagnose the name that won't resolve

The Pod is `Running`, so don't look for a crash. The failure is in name resolution — read the DNS answer, from the namespace that's actually doing the asking.

## Read the endpoint it's configured to call

```bash
kubectl describe deploy account-provisioner -n provisioning
```{{exec}}

Read the `Environment:` block in the container section. `BROKER_ENDPOINT` is set to `http://session-broker/` — a **bare** Service name, no namespace. Hold that thought.

## Reproduce the lookup from the caller's namespace

This is the step that matters: resolve the name from `provisioning`, where the caller lives — not from `media`, where it would wrongly succeed.

```bash
kubectl run dns-test --rm -i --restart=Never --image=busybox:1.36 -n provisioning -- \
  nslookup session-broker
```{{exec}}

It fails — `can't resolve 'session-broker'` / NXDOMAIN. A short name is tried under the Pod's own search domains, which are built from *its* namespace: `session-broker.provisioning.svc.cluster.local` first, then `session-broker.svc.cluster.local`, and so on. None of those exist, because the Service is in `media`.

## Prove the Service is fine — it's just elsewhere

```bash
kubectl get svc session-broker -n media
```{{exec}}

There it is, with a normal ClusterIP. The Service isn't down; the *name* the caller used can't reach it across the namespace boundary. Confirm the fix direction by resolving it qualified:

```bash
kubectl run dns-test --rm -i --restart=Never --image=busybox:1.36 -n provisioning -- \
  nslookup session-broker.media.svc.cluster.local
```{{exec}}

Now it resolves, from the same namespace that just returned NXDOMAIN. The problem was never the Service; it was an unqualified name.

(`session-broker.media` is the shorter form application config normally uses, and glibc-based images resolve it — the search list completes it. Don't use it from a busybox probe: busybox skips the search list for any name that already contains a dot, so it would return NXDOMAIN here and tell you nothing.) On to the fix.

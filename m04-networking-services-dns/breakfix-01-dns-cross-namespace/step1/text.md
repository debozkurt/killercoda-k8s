# Step 1 — Diagnose the name that won't resolve

The Pod is `Running`, so don't look for a crash. The failure is in name resolution — read the DNS answer, from the namespace that's actually doing the asking.

## Read the endpoint it's configured to call

```bash
kubectl get deploy account-provisioner -n provisioning -o yaml | grep -A2 BROKER_ENDPOINT
```{{exec}}

The value is `http://session-broker/` — a **bare** Service name, no namespace. Hold that thought.

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
  nslookup session-broker.media
```{{exec}}

Now it resolves — `session-broker.media` lets the search list complete it to `session-broker.media.svc.cluster.local`. The problem was never the Service; it was an unqualified name. On to the fix.
</content>

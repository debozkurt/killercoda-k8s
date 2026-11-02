# Step 1 — Diagnose the Forbidden

Three fields match the grant. Find the fourth.

## Read the logs

```bash
kubectl get pods -n provisioning -l app=release-auditor
kubectl logs -n provisioning deploy/release-auditor --tail=8
```{{exec}}

```text
deployments.apps is forbidden: User "system:serviceaccount:provisioning:release-auditor"
cannot list resource "deployments" in API group "apps" in the namespace "provisioning"
```

- identity: `release-auditor`, the intended ServiceAccount
- verb: `list`
- resource: `deployments`
- API group: `apps`
- scope: the namespace `provisioning`

## Read the Role

```bash
kubectl describe role release-reader -n provisioning
```{{exec}}

The rule row reads `deployments` with verbs [get list watch]. Compare it with the ClusterRole `view` from the baseline, which prints `deployments.apps`. `kubectl describe` adds the API group as a suffix, and a core-group resource has no suffix. This rule names `deployments` in the core group.

## Confirm where Deployments live

```bash
kubectl api-resources | grep -w deployments
kubectl auth can-i list deployments -n provisioning --as=system:serviceaccount:provisioning:release-auditor
```{{exec}}

The APIVERSION column reads apps/v1, so Deployments belong to the `apps` group. The core group has no `deployments` resource. The rule is valid YAML that matches no real request, and `auth can-i` answers no.

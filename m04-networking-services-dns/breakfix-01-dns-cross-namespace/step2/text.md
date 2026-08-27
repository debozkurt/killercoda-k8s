# Step 2 — Fix it and verify

The Service is healthy; the configured name just wasn't qualified for a cross-namespace call. Point it at a name that resolves from `provisioning`.

## Qualify the name

```bash
kubectl set env deployment/account-provisioner -n provisioning \
  BROKER_ENDPOINT=http://session-broker.media.svc.cluster.local/
```{{exec}}

The fully-qualified name resolves from any namespace. `session-broker.media` works too for a glibc-based application image — the search list completes it — but the FQDN is the unambiguous choice for config that crosses namespaces, and it's the only form a busybox client resolves.

Or by hand:

```bash
kubectl edit deployment account-provisioner -n provisioning
# change  value: http://session-broker/
# to      value: http://session-broker.media.svc.cluster.local/
```

## The real-world version

The fix here is a name, but the lesson is a convention: **cross-namespace calls use `<svc>.<ns>` (or the FQDN), never the bare name.** The bare-name habit works right up until caller and callee stop sharing a namespace — then it fails for a subset of traffic and looks like the callee is down. If DNS were failing *everywhere* (not just across namespaces), that's a different incident: check CoreDNS in `kube-system` and the `kube-dns` Service's endpoints before touching app config.

## Verify

```bash
kubectl describe deploy account-provisioner -n provisioning
kubectl run dns-test --rm -i --restart=Never --image=busybox:1.36 -n provisioning -- \
  wget -qO- -T3 http://session-broker.media.svc.cluster.local/ | head -4
```{{exec}}

The `Environment:` block now shows `BROKER_ENDPOINT` carrying the qualified name, and the `wget` from `provisioning` returns nginx's HTML — the broker is reachable from the caller's namespace. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.

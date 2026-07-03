# Step 3 — mTLS between two workloads

`config-api` doesn't just serve HTTPS — it requires the *caller* to present a valid client cert too (mutual TLS). `config-client` in `app-services` holds one. Watch a real workload-to-workload mTLS call.

## What the client holds

```bash
kubectl exec -n app-services deploy/config-client -- ls /etc/tls/id /etc/tls/trust
```{{exec}}

`/etc/tls/id` is its **identity** (`tls.crt` / `tls.key`, from its own leaf cert); `/etc/tls/trust` is its **trust anchor** (`ca.crt`, the internal CA it verifies the server against). Two separate jobs — prove who you are, and decide who to believe.

## The mTLS call succeeds

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

`config-api: mTLS OK, client=CN=config-client`. Everything lined up: the cert was **issued** (the Secret exists), its **identity** matched (you dialed a name in its SANs), and it was **trusted** (`--cacert` is the CA that signed it) — *both* directions, since the server echoed the client's identity back. That's mTLS working.

## Drop the client cert — the server rejects you

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

`400 No required SSL certificate was sent`. The transport encrypted fine, but the server *demands* a client cert and you didn't present one, so it refuses at the door. That's the "mutual" in mTLS — network reachability isn't identity.

The three ingredients you just watched line up — issuance, identity, trust — are exactly what the three break/fix scenarios each knock out one at a time. On to renewal.

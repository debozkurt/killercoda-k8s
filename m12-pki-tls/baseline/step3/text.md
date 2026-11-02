# Step 3 — mTLS between two workloads

`config-api` requires the caller to present a valid cert too. That requirement is **mutual TLS** (mTLS). `config-client` in `app-services` holds one.

## What the client holds

```bash
kubectl exec -n app-services deploy/config-client -- ls /etc/tls/id /etc/tls/trust
```{{exec}}

`/etc/tls/id` holds the client's **identity**: `tls.crt` and `tls.key` from its own leaf cert. `/etc/tls/trust` holds its **trust anchor**: `ca.crt`, the CA it verifies the server against. Two jobs, two mounts.

## The mTLS call succeeds

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The reply reads `config-api: mTLS OK, client=CN=config-client`. The server accepted the client's cert and echoed its identity. The client accepted the server's cert because the name matched a SAN and `--cacert` holds the CA that signed it.

## Drop the client cert

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The reply is an HTML page: 400 Bad Request, No required SSL certificate was sent. The TLS channel opened, and the server then refused a caller with no identity. Network reachability is not identity.

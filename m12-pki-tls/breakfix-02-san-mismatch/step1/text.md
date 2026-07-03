# Step 1 — Diagnose the handshake failure

The app is healthy by every status check, so prove the failure is in TLS, then read exactly which of the two handshake checks — trust or identity — failed.

## Reproduce the call

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

```text
curl: (60) SSL: no alternative certificate subject name matches target host name 'config-api.media.svc.cluster.local'
```

Read that precisely. It is **not** "unable to get local issuer certificate" (that would be trust). It's the *hostname* check: curl trusts the signer fine, but the name you dialed isn't in the cert's SANs. So the cert is issued and trusted — its **identity** is wrong.

## Confirm the app itself is fine

```bash
kubectl get pods -n media -l app=config-api
kubectl get certificate config-api-tls -n media
```{{exec}}

`Running 1/1`, `Certificate` `Ready`. Nothing here hints at a problem — which is the lesson: a green `Certificate` says *issued*, not *correct*.

## Read the cert's SANs

Decode the served cert straight from its Secret and read the names it's valid for:

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext subjectAltName
```{{exec}}

```text
X509v3 Subject Alternative Name:
    DNS:config-api-legacy.media.svc.cluster.local
```

There's the mismatch: the cert is valid only for `config-api-legacy.media.svc.cluster.local`, but clients reach the Service at `config-api.media.svc.cluster.local`. Confirm what drives those SANs — the `Certificate`'s `dnsNames`:

```bash
kubectl get certificate config-api-tls -n media -o jsonpath='{.spec.dnsNames}{"\n"}'
```{{exec}}

`["config-api-legacy.media.svc.cluster.local"]` — it omits the real Service names. Root cause: the server cert's SANs don't cover the name clients dial. On to the fix.

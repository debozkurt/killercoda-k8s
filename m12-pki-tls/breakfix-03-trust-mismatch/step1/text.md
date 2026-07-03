# Step 1 — Diagnose the trust failure

Same call, different error. Read *which* handshake check failed, then compare the CA the client trusts against the CA that signed the server.

## Reproduce the call

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

```text
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

This is the **trust** check, not the hostname check. curl found the server's cert but couldn't chain it up to any CA in the bundle you gave it (`--cacert /etc/tls/trust/ca.crt`). The server cert isn't bad — the client doesn't recognize who signed it.

## Who signed the server's cert?

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -issuer
```{{exec}}

`issuer=CN=polyphone-internal-ca`. So the client must hold the **internal CA** to verify it.

## Which CA is the client actually trusting?

Read the CA cert the client has mounted at `/etc/tls/trust/ca.crt`:

```bash
kubectl exec -n app-services deploy/config-client -- \
  openssl x509 -in /etc/tls/trust/ca.crt -noout -subject
```{{exec}}

`subject=CN=polyphone-legacy-ca` — a *different* CA. The client is verifying against `polyphone-legacy-ca` while the server's cert was signed by `polyphone-internal-ca`. They don't match, so verification fails. Find where that wrong bundle comes from:

```bash
kubectl get deploy config-client -n app-services \
  -o jsonpath='{.spec.template.spec.volumes[?(@.name=="trust")].secret.secretName}{"\n"}'
```{{exec}}

`legacy-ca-bundle`. Root cause: the client mounts the wrong trust bundle. The correct one is `internal-ca-bundle` (the internal CA's public cert). On to the fix — and note the *wrong* fix would be `curl --insecure`, which doesn't fix trust, it turns verification off.

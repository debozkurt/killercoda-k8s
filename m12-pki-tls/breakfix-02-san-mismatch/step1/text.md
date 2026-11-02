# Step 1 — Diagnose the handshake failure

The status checks pass, so reproduce the failure. Then read which handshake check failed: trust or identity.

## Reproduce the call

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The error reads `no alternative certificate subject name matches target host name 'config-api.media.svc.cluster.local'`. This is the name check. The trust check says `unable to get local issuer certificate`, and that is not what you got. The client trusts the signer. The name it dialed is not in the cert.

## The app and the Certificate look fine

```bash
kubectl get pods -n media -l app=config-api
kubectl get certificate config-api-tls -n media
```{{exec}}

Pod Running 1/1, `Certificate` Ready. Ready means issued. It does not mean correct.

## Read the SANs

Decode the served cert from its Secret:

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext subjectAltName
```{{exec}}

The only SAN is `config-api-legacy.media.svc.cluster.local`. Clients dial `config-api.media.svc.cluster.local`. Now find what drives the SAN list:

```bash
kubectl describe certificate config-api-tls -n media
```{{exec}}

In the `Spec:` block, read `Dns Names`. It holds the legacy name only. The cert omits the real Service names.

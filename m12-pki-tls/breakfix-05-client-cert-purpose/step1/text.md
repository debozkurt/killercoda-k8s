# Step 1 — Diagnose the rejection

Read who answers. A server that answers has already completed the TLS handshake.

## Reproduce the call

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The reply is an HTML page: 400 Bad Request, The SSL certificate error. curl reports no handshake error, so the client accepted the server cert. Name and trust pass in this direction. The server rejected the client cert.

## Ask the server why

```bash
kubectl logs -n media deploy/config-api --tail=5
```{{exec}}

Read the line `client SSL certificate verify error: (26:unsuitable certificate purpose)`. nginx logs this failure at `info` level. The lab sets that level, because nginx hides these lines by default. The error is about the purpose of the cert, not its signer. A signer error reads `unable to get local issuer certificate`.

## Read the client cert's purpose

The **Extended Key Usage** (EKU) extension lists what a cert may be used for. Decode the client cert:

```bash
kubectl get secret config-client-tls -n app-services -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext extendedKeyUsage
```{{exec}}

The cert reads `TLS Web Server Authentication`. A client identity needs `TLS Web Client Authentication`. Find what drives it:

```bash
kubectl describe certificate config-client-tls -n app-services
```{{exec}}

In the `Spec:` block, read `Usages`. It lists `server auth` and omits `client auth`. cert-manager issued exactly what the spec asked for.

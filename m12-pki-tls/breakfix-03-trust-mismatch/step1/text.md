# Step 1 — Diagnose the trust failure

Same call, different error. Read which check failed. Then compare the CA that signed the server with the CA the client holds.

## Reproduce the call

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The error reads `SSL certificate problem: unable to get local issuer certificate`. This is the trust check, not the name check. curl found the server cert and could not chain it to any CA in `--cacert`. The cert is not bad. The client does not recognize the signer.

## Who signed the server cert?

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -issuer
```{{exec}}

The issuer is `CN=polyphone-internal-ca`. The client needs that CA.

## Which CA does the client hold?

Read which Secret the client mounts for trust:

```bash
kubectl describe deployment config-client -n app-services
```{{exec}}

Under `Volumes:`, read the `trust` entry. Its SecretName is `legacy-ca-bundle`. The client image has no `openssl` binary, so decode that bundle on the host:

```bash
kubectl get secret legacy-ca-bundle -n app-services -o jsonpath='{.data.ca\.crt}' | base64 -d \
  | openssl x509 -noout -subject
```{{exec}}

The subject is `CN=polyphone-legacy-ca`, a different CA. The client verifies against the legacy CA while the internal CA signed the server. The matching bundle is `internal-ca-bundle`.

The wrong fix is `curl --insecure`. It does not repair trust. It turns verification off.

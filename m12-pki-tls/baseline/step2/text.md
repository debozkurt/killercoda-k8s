# Step 2 — A Certificate becomes a TLS Secret

You don't sign certs by hand. You declare a `Certificate`, and cert-manager reconciles it into a `kubernetes.io/tls` Secret. `config-api` (the HTTPS server in `media`) has one.

## The leaf Certificate is Ready

```bash
kubectl get certificate config-api-tls -n media
kubectl describe certificate config-api-tls -n media | sed -n '/Status:/,/Events:/p'
```{{exec}}

`READY=True`. The `describe` shows the conditions and the child `CertificateRequest` cert-manager created to get it signed — the ladder you'll climb in `breakfix-01` when a cert *won't* issue.

## The Secret it produced

```bash
kubectl get secret config-api-tls -n media
```{{exec}}

Type `kubernetes.io/tls`. Three keys: `tls.crt` (the cert), `tls.key` (the private key the server serves with), and `ca.crt` (the CA that signed it — handy for clients). This Secret is the deliverable: the `config-api` Pod mounts it to serve HTTPS.

## Read the cert's identity — its SANs

The **Subject Alternative Names** are the only field TLS checks for identity. Decode the cert and read them:

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -subject -ext subjectAltName
```{{exec}}

Three SANs — `config-api`, `config-api.media.svc`, `config-api.media.svc.cluster.local` — the three DNS forms a caller might use to reach this Service. A client that dials any of them passes hostname verification; a client that dials a name *not* listed fails, even though the cert is perfectly valid. That mismatch is `breakfix-02`.

## Confirm the server mounts it

```bash
kubectl get deploy config-api -n media \
  -o jsonpath='{.spec.template.spec.volumes[?(@.name=="tls")].secret.secretName}{"\n"}'
```{{exec}}

`config-api-tls` — the Pod mounts the Secret at `/etc/nginx/tls` and serves HTTPS from it. On to the handshake.

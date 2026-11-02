# Step 2 — A Certificate becomes a TLS Secret

You declare a `Certificate`. cert-manager reconciles it into a Secret of type `kubernetes.io/tls`, the object a Pod mounts to read a key pair. `config-api` (the HTTPS server in `media`) has one.

## The Certificate is Ready

```bash
kubectl get certificate config-api-tls -n media
kubectl describe certificate config-api-tls -n media
```{{exec}}

Ready is True. In the `describe` output, read `Conditions:` and then the `Events:` at the bottom. The events name the CertificateRequest, the object cert-manager creates to get each key pair signed.

## The Secret it produced

```bash
kubectl describe secret config-api-tls -n media
```{{exec}}

The `Data` block lists three keys: `tls.crt` (the cert), `tls.key` (the private key) and `ca.crt` (the issuing CA). Kubernetes requires only `tls.crt` and `tls.key`. cert-manager adds `ca.crt` as its best guess at the CA.

## Read the cert's identity

The **Subject Alternative Names** (SANs) are the names a client checks. Decode the cert and read them:

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -subject -ext subjectAltName
```{{exec}}

The cert lists three SANs: the short name, `config-api.media.svc`, and the full cluster name. A client that dials any of the three passes the name check. A client that dials another name fails, even though the cert is valid.

## Confirm the Pod mounts it

```bash
kubectl describe deployment config-api -n media
```{{exec}}

Under `Volumes:`, read the `tls` entry. Its SecretName is `config-api-tls`, and the container mounts it at /etc/nginx/tls.

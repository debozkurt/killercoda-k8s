# Step 1 — cert-manager and the internal CA

cert-manager is an operator (the M08 pattern). Custom resource definitions describe the objects, and a controller reconciles a declared `Certificate` into a signed key pair.

## The components

```bash
kubectl get pods -n cert-manager
```{{exec}}

Three Deployments run. `cert-manager` is the controller that issues certificates. `cert-manager-webhook` validates, defaults and converts every cert-manager object, so nothing PKI-related can be created until it serves. `cert-manager-cainjector` writes CA bundles into the webhook configurations, so the API server trusts the webhook.

## The issuers

An **issuer** names a signing backend. A `ClusterIssuer` is an issuer that every namespace can use.

```bash
kubectl get clusterissuers
```{{exec}}

`selfsigned-bootstrap` (type SelfSigned) mints a self-signed root. A root CA signs itself, so the first CA needs this bootstrap. `polyphone-ca` (type CA) then signs every workload's leaf cert with that root. Both read Ready True.

## The CA certificate and its Secret

```bash
kubectl get certificate polyphone-internal-ca -n cert-manager
kubectl describe secret polyphone-internal-ca -n cert-manager
```{{exec}}

The CA `Certificate` is Ready. Its key pair lives in the Secret `polyphone-internal-ca`, in the `cert-manager` namespace, because a ClusterIssuer reads its signing key from that namespace. The private key in this Secret is the crown jewel: whoever reads it can sign any identity.

Decode the CA cert to confirm it is a self-signed root:

```bash
kubectl get secret polyphone-internal-ca -n cert-manager -o jsonpath='{.data.tls\.crt}' \
  | base64 -d | openssl x509 -noout -subject -issuer
```{{exec}}

Subject and issuer match. That match marks a self-signed root, and every leaf below chains up to it.

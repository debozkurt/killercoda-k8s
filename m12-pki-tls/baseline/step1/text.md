# Step 1 — cert-manager and the internal CA

cert-manager is an operator (the M08 pattern): CRDs plus a reconcile loop that turns a declarative `Certificate` into a real signed key pair. It runs three components.

## The components

```bash
kubectl get pods -n cert-manager
```{{exec}}

Three Deployments: `cert-manager` (the controller that issues), `cert-manager-webhook` (validates/defaults every Issuer and Certificate — nothing PKI-related can be created until it's serving), and `cert-manager-cainjector` (wires the webhook's own CA). All `Running`.

## The issuers — how certs get signed

```bash
kubectl get clusterissuers
```{{exec}}

Two `ClusterIssuer`s, and the two-step chain that builds an internal CA. `selfsigned-bootstrap` (type SelfSigned) can mint a self-signed root — you need it because a root CA signs *itself*; there's no higher CA yet. `polyphone-ca` (type CA) then signs every workload's leaf cert using that root. Both `READY=True`.

## The CA certificate and its Secret

```bash
kubectl get certificate polyphone-internal-ca -n cert-manager
kubectl get secret polyphone-internal-ca -n cert-manager
```{{exec}}

The CA `Certificate` is `Ready`, and its private key + cert live in Secret `polyphone-internal-ca` (in the `cert-manager` namespace, because a CA issuer reads its signing key from the cluster resource namespace). **Only cert-manager reads this Secret** — the CA's private key is the crown jewel; the whole system's security rests on it staying secret.

Read the CA cert itself to confirm it's a CA:

```bash
kubectl get secret polyphone-internal-ca -n cert-manager -o jsonpath='{.data.tls\.crt}' \
  | base64 -d | openssl x509 -noout -subject -issuer
```{{exec}}

`subject` and `issuer` are identical (`CN=polyphone-internal-ca`) — the signature of a self-signed root. This is your trust anchor: every leaf below chains up to it. On to a leaf cert.

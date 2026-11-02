# Step 6 — Prove what etcd holds

Base64 is the API's encoding, not storage protection. By default the API server writes Secrets to etcd unencrypted. Encryption at rest needs the `--encryption-provider-config` flag on the API server.

## Check the API server flag

The API server runs as a static Pod. Its manifest is on this control-plane node:

```bash
grep -c encryption-provider-config /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

It prints 0. No `EncryptionConfiguration` is configured.

## Read the Secret from etcd

The etcd image includes `etcdctl`. Capture the etcd Pod name, then read the Secret's key in etcd with the etcd client certificates:

```bash
ETCD=$(kubectl get pods -n kube-system -l component=etcd -o name)
kubectl exec -n kube-system $ETCD -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/provisioning/db-credentials --print-value-only | tr -c '[:print:]' '.'; echo
```{{exec}}

The record is binary protobuf, so `tr` turns the unprintable bytes into dots. Find the readable parts: the prefix k8s, the kind Secret, the key `DB_PASSWORD`, and the password S3cure-prod-4417 in clear text. No base64 is involved.

With encryption at rest, the same read prints a prefix such as k8s:enc:aescbc:v1:key1: followed by ciphertext. Anyone with an etcd snapshot of this cluster has every credential in it.

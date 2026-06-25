# Step 4 — Secrets aren't secret: base64 is encoding

A Secret's values are stored base64-encoded in its `data` field. That encoding is the single most misunderstood thing about Secrets — so see exactly what it is and isn't.

## Look at the raw Secret

```bash
kubectl get secret database-creds -n provisioning -o yaml
```{{exec}}

Read the `data` section — the values are base64, not plaintext:

```text
data:
  DB_HOST: cG9zdGdyZXMucG9seXBob25lLmV4YW1wbGU=
  DB_PASSWORD: Y2hhbmdlbWU=
```

## Decode it — no key, no permission, nothing

```bash
kubectl get secret database-creds -n provisioning -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo
```{{exec}}

```text
changeme
```

That's it. Anyone who can `get` the Secret reads the value with a single public decode — **base64 is encoding, not encryption.** The encoding exists so a Secret can carry arbitrary bytes (binary keys, certificates) inside a JSON field, not to hide anything.

## What actually protects a Secret

Out of the box a Secret is just base64 in etcd. Real confidentiality is layered on top, and none of it is on by default here:

- **RBAC** — restrict who can `get`/`list` Secrets. Note the subtle hole: anyone who can create a Pod in the namespace can mount any Secret in it (M10).
- **Encryption at rest** — encrypt Secret values before they reach etcd, so an etcd backup isn't every credential in the clear.
- **External stores** — at scale, sync from Vault/cloud managers or commit only encrypted material to Git (M11).

When you *author* a Secret, write plaintext into `stringData` and let the API server encode it — that's how you avoid hand-base64'ing (and the double-encoding mistake a later scenario hits).

## Verify

```bash
kubectl get secret database-creds -n provisioning -o jsonpath='{.type}'; echo
```{{exec}}

`Opaque` — the default Secret type for arbitrary key/value data. That's healthy config across both objects and both consumption modes. Next, the four ways it breaks.

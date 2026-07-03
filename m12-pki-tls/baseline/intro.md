# M12 — Baseline Tour

A certificate answers one question — *who are you?* — with a signature anyone can check. Three properties make it work, and every TLS failure is a failure of exactly one: **issuance** (does a signed cert exist?), **identity** (does it claim the right name?), and **trust** (does the verifier believe the signer?).

This tour runs on the full Polyphone fleet on a **2-node cluster**, plus **cert-manager** (the operator that issues and renews certs), an **internal CA** already minted, and an mTLS workload pair — `config-api` (an HTTPS server in `media`) and `config-client` (a caller in `app-services`). Nothing is broken; you're learning to *read* a healthy PKI so a broken one stands out.

Four short steps:

1. **cert-manager and the internal CA** — the components, the two `ClusterIssuer`s, the CA `Certificate`, and the CA Secret
2. **A Certificate becomes a TLS Secret** — a leaf `Certificate` reconciled into a `kubernetes.io/tls` Secret; decode the cert and read its SANs
3. **mTLS between two workloads** — `config-client` calls `config-api`, both presenting certs; watch it succeed, then watch a caller with no client cert get rejected
4. **Expiry and automatic renewal** — read a cert's validity window and how cert-manager renews it before it expires

Installing cert-manager makes this boot slower than usual — **2–3 minutes**. Click **Start** when the terminal says the cluster is ready.

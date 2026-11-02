# M10 — Baseline Tour

Every Pod in the fleet talks to the API server as an identity. The API server checks each request at three gates: **authentication** (who is calling), **authorization** (may the caller do this), and **admission** (is this object allowed). The kubelet adds one more check before a container starts.

This tour runs on the full Polyphone fleet on a **2-node cluster**. Nothing is broken. You read the healthy security posture so that a denial stands out in the break/fix scenarios.

Five steps:

1. **Who the Pods are**: the ServiceAccount each Pod runs as, its mounted token, and what `default` may do
2. **What an identity may do**: RBAC roles and rules, and deny by default
3. **Grant a permission and prove it**: bind `view` in one namespace and test its edges with `kubectl auth can-i`
4. **A Pod's security posture**: the `securityContext` fields and what the fleet runs with
5. **Namespace enforcement**: PodSecurity admission rejects a Pod, warns on a Deployment, and admits a compliant Pod

The cluster takes 90–150 seconds to come up. Click **Start** when ready.

# M10 — Baseline Tour

Every Pod you've run talks to the API server as *someone*, and every request it makes is checked by three gates: **authentication** (who are you?), **authorization** (may you do this?), and **admission** (is this object allowed?). This module is about reading which gate says no — and its favorite word is `Forbidden`.

This tour runs on the full Polyphone fleet on a **2-node cluster**. Nothing to fix — you're learning to *read* the fleet's security posture before the break/fix scenarios break each gate in turn.

Four short steps:

1. **Who the Pods are** — the ServiceAccount each Pod runs as, the token projected into it, and what `default` can (and can't) do
2. **What an identity may do** — RBAC's Roles and bindings, the built-in ClusterRoles, and `kubectl auth can-i` to prove any decision
3. **A Pod's security posture** — the `securityContext` fields, and what the fleet runs with by default
4. **Namespace enforcement** — PodSecurity admission rejecting a non-compliant Pod, and admitting a compliant one

See what healthy security looks like, so a denial stands out later. The cluster takes 90–150 seconds to come up. Click **Start** when ready.

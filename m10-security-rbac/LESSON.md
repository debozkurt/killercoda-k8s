# M10 — Security I: RBAC & Pod Security

> The two questions every request to the API server must pass — *who are you* and *what may you do* — plus the admission gate that decides whether a Pod's security posture is allowed at all, and the handful of ways each one returns `Forbidden`.

## What you'll learn

- Trace a request through the API server's three gates — **authentication** (who), **authorization** (may they), **admission** (is this object allowed) — and tell which gate a `Forbidden` came from
- Read RBAC: a **Role**/**ClusterRole** as a set of rules (`apiGroups` × `resources` × `verbs`), a **RoleBinding**/**ClusterRoleBinding** tying a subject to a role, and the additive/deny-by-default evaluation
- Use `kubectl auth can-i` (with `--as` and `--list`) to reproduce and prove any authorization decision instead of guessing
- Understand a **ServiceAccount** as a Pod's API identity — `system:serviceaccount:<ns>:<name>`, the auto-projected short-lived token — and why the `default` SA is bound to nothing
- Set a container's **securityContext** (`runAsNonRoot`, `allowPrivilegeEscalation`, dropped capabilities, seccomp) and know which fields the `restricted` standard requires
- Enforce the **Pod Security Standards** with PodSecurity admission's namespace labels (`enforce`/`audit`/`warn`), and recognize an admission rejection — a Deployment with zero Pods and no `Pending` Pod
- Work the **`Forbidden` differential**: the same 403 from a missing verb vs. the wrong identity vs. the wrong scope — one phrase in the message tells them apart

## Why it matters

Security failures don't crash — they deny. A Pod that can't reach the API doesn't OOM or sit `Pending`; its app logs one line — `Forbidden` — and stalls, and every reflex from the workload modules (`logs`, `--previous`, restart) returns nothing useful. The signal is a single string from the API server that names the identity, the verb, the resource, and the scope. Read it and the fix is obvious; skim past it and you'll spend an hour editing an app that was never wrong.

At Polyphone the surface is everywhere. A discovery sidecar needs to `list endpoints` and someone granted it `get`. A workload ships without a ServiceAccount, so it authenticates as `default` — bound to nothing — and every API call is denied. A new component wants to read node labels and the RoleBinding that "grants" it silently does nothing, because nodes are cluster-scoped and a namespaced binding can't reach them. The security team enforces the `restricted` standard on a namespace and the next Deployment there creates zero Pods with no error on any Pod, because no Pod was ever admitted. Each is one field, in one of three gates. This module is about reading which gate said no, and why.

## Scope

**Covers:** the API request pipeline (authentication → authorization → admission) and where each says no; **RBAC** — Roles and ClusterRoles, RoleBindings and ClusterRoleBindings, the rule triple (`apiGroups`/`resources`/`verbs`), namespaced vs. cluster scope, additive/deny-by-default evaluation, and `kubectl auth can-i`; **ServiceAccounts** as Pod identity, the projected bound token, the `default` SA; **securityContext** at Pod and container level; the **Pod Security Standards** (privileged/baseline/restricted) and **PodSecurity admission** (the `enforce`/`audit`/`warn` namespace labels); and the `Forbidden` differential that ties RBAC and admission together.

**Doesn't cover:** user/group authentication mechanisms — client certs, OIDC, the fact that Kubernetes has no first-class User object — named where they intersect but the identity providers themselves are out; secrets management at scale (External Secrets, Vault, sealed-secrets) → M11; PKI, cert-manager, and mTLS between workloads → M12; NetworkPolicy and traffic isolation → M14; policy-as-code admission webhooks (Kyverno, OPA Gatekeeper) that go beyond built-in PodSecurity → M20–M21; the audit log that records every authorization decision → M13; image provenance (scanning, signing), covered in M02.

**Assumes:** M00 (`get → describe → events → logs`, and that a resource's story lives between `spec` and `status`), M01 (Pods, Deployments, ReplicaSets — a *controller*, not you, creates the Pods, which matters for how an admission rejection surfaces), M03 (a ServiceAccount token is mounted into a Pod the same way the projected Secret volumes there already are), and a working idea of an HTTP request carrying an `Authorization` header — because every `kubectl` command is exactly that.

## Vocabulary

| Term | Definition |
|------|------------|
| **authentication (authn)** | The API server deciding *who* is calling, from a token or client cert. The result is a username (or `system:serviceaccount:<ns>:<name>`) plus groups. Kubernetes stores no User objects; ServiceAccounts are the only first-class identities. |
| **authorization (authz)** | Deciding whether that identity may perform this **verb** on this **resource**. RBAC is the authorizer here. Deny-by-default: if no rule allows, the answer is no. |
| **admission** | The stage *after* authz (writes only) where admission controllers inspect the object and may reject or mutate it. PodSecurity is a built-in admission controller. |
| **RBAC** | Role-Based Access Control. Permissions are grouped into Roles; Roles are granted to subjects by Bindings. |
| **Role / ClusterRole** | A named set of **rules**. A **Role** is namespaced (rules apply in one namespace); a **ClusterRole** is cluster-scoped — usable in any namespace, and the only kind that can grant cluster-scoped resources. |
| **rule** | One line of a Role: `apiGroups` × `resources` × `verbs`, ANDed. A request is allowed if any rule matches all three. RBAC never denies explicitly; it only fails to allow. |
| **RoleBinding / ClusterRoleBinding** | Ties a **subject** to a Role/ClusterRole. A **RoleBinding** grants within its namespace; a **ClusterRoleBinding** grants cluster-wide. |
| **subject** | Who a binding grants to. For a Pod: `kind: ServiceAccount` with a `name` and `namespace`. |
| **verb** | The action: `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`. Reading one named object is `get`; reading a collection is `list`. |
| **ServiceAccount (SA)** | A namespaced identity for processes in Pods. Every Pod runs as exactly one SA (`default` if unset) and authenticates as `system:serviceaccount:<ns>:<name>`. |
| **bound service account token** | The short-lived, audience- and Pod-bound JWT the kubelet projects into every Pod at `/var/run/secrets/kubernetes.io/serviceaccount/token`. Auto-rotated; invalid once the Pod is gone. Replaced the old permanent Secret-based tokens. |
| **securityContext** | Pod- and container-level fields setting the process's security posture: `runAsNonRoot`, `runAsUser`, `allowPrivilegeEscalation`, `capabilities`, `seccompProfile`, `readOnlyRootFilesystem`. |
| **Pod Security Standards** | Three named policies: **Privileged** (unrestricted), **Baseline** (blocks known escalations), **Restricted** (hardened best practice). |
| **PodSecurity admission** | The built-in controller that enforces a Standard per namespace via labels `pod-security.kubernetes.io/<mode>: <level>`, where mode is `enforce` (reject), `audit` (log), or `warn` (warn). |
| **capability** | A slice of root's power (e.g. `NET_BIND_SERVICE`). Dropping `ALL` and adding back only what's needed is the hardening default. |

## Mental model

Every `kubectl` command — and every API call your Pods make — is an HTTP request to the API server, and the server runs it through three gates, in order<sup><a href="https://kubernetes.io/docs/concepts/security/controlling-access/">[9]</a></sup>:

1. **Authentication** — *who are you?* The server validates your credential (a token, a client cert) and resolves it to a username and groups. A Pod's credential is its projected ServiceAccount token, which resolves to `system:serviceaccount:<ns>:<name>`.
2. **Authorization** — *may you do this?* With RBAC, the server looks for a rule — reachable from your identity through some binding — that allows this verb on this resource in this scope. There is no explicit deny; if nothing allows, you get `403 Forbidden`<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[1]</a></sup>.
3. **Admission** — *is this object allowed?* Writes only. Admission controllers see the object and can reject or modify it. PodSecurity checks a Pod's `securityContext` against the namespace's Standard<sup><a href="https://kubernetes.io/docs/concepts/security/pod-security-admission/">[6]</a></sup>.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'primaryColor':'#2b2b2b', 'primaryTextColor':'#e6e6e6',
  'primaryBorderColor':'#7a7a7a', 'lineColor':'#9a9a9a',
  'secondaryColor':'#3a3a3a', 'tertiaryColor':'#1f1f1f',
  'background':'#0f0f0f'
}}}%%
flowchart LR
    R[API request<br/>+ credential] --> A1{authenticated?<br/>who are you}
    A1 -->|no| E1[401 Unauthorized]
    A1 -->|yes: user or<br/>serviceaccount| A2{authorized?<br/>RBAC rule allows}
    A2 -->|no| E2[403 Forbidden]
    A2 -->|yes| A3{admitted?<br/>PodSecurity etc.}
    A3 -->|reject| E3[forbidden:<br/>violates PodSecurity]
    A3 -->|admit| S[persisted → scheduled]
```

The payoff is that a `Forbidden` names exactly which gate and why. An **authorization** Forbidden reads: `<resource> is forbidden: User "<identity>" cannot <verb> resource "<resource>" in API group "<group>" in the namespace "<ns>"` (or, for a cluster-scoped resource, `at the cluster scope`). Every field in that sentence is a place the fix could live: the **identity** (are you who you meant to be?), the **verb** and **resource** (does a rule cover them?), and the **scope** (namespace vs. cluster — did you use the right kind of binding?). An **admission** Forbidden reads differently — `pods "<name>" is forbidden: violates PodSecurity "restricted:latest": <fields>` — and it lands not on your command but on the ReplicaSet that tried to create the Pod, because the *controller*, not you, is the caller the server refused.

Two facts make RBAC quick to reason about. First, it is **purely additive and deny-by-default**: you can only grant, never deny, and a subject's permissions are the union of every binding that reaches it — so "why can't it?" is always "no rule allows it," never "something blocked it"<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[1]</a></sup>. Second, RBAC matches **strings**, not intent: `endpoints` and `endpoint`, `get` and `list`, apiGroup `""` and `"apps"` are different keys, and a near-miss is a silent denial. The fix is never to argue with the error; it is to make some rule, reachable from the right subject, match all three strings in the right scope.

## Concept walkthrough

### RBAC: rules, bindings, and the two scopes

RBAC has exactly two kinds of object, each in a namespaced and a cluster-scoped form. A **Role** (or **ClusterRole**) is a bag of rules; a **RoleBinding** (or **ClusterRoleBinding**) grants a role to subjects. A rule is three lists ANDed together<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[1]</a></sup>:

```yaml
rules:
- apiGroups: [""]            # "" is the core group (pods, services, endpoints, secrets…)
  resources: ["endpoints"]
  verbs: ["get", "list", "watch"]
```

A request is authorized if some rule reachable from the caller matches its apiGroup, its resource, *and* its verb. Miss any one — ask to `list` when the rule only grants `get`, name `endpoints` when the rule says `services` — and no rule matches, so it's denied. There is no `deny` rule to look for; the *absence* of an allow is the denial.

The scope distinction is the part that bites. Roles and RoleBindings are **namespaced**: a RoleBinding grants its role's rules only within its own namespace, and a Role can only usefully grant namespaced resources. ClusterRoles and ClusterRoleBindings are **cluster-scoped**: a ClusterRoleBinding grants across every namespace, and — the load-bearing fact — a **cluster-scoped resource (`nodes`, `namespaces`, `persistentvolumes`) can only be granted by a ClusterRole through a ClusterRoleBinding**<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[1]</a></sup>. Put `nodes` in a namespaced Role, bind it with a RoleBinding, and RBAC accepts the YAML without complaint — but the grant does nothing: nodes live outside every namespace, so a namespaced binding can never reach them. The request is denied `at the cluster scope`, and that word — *scope* — is the whole tell.

One useful combination: a RoleBinding may reference a *ClusterRole*, which grants that ClusterRole's rules *only within the RoleBinding's namespace* — the standard way to reuse a built-in ClusterRole like `view` per namespace without copying its rules.

You don't have to reason about any of this in your head. `kubectl auth can-i` asks the API server the exact question the authorizer answers<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/authorization/">[2]</a></sup>:

```bash
kubectl auth can-i list endpoints -n media \
  --as=system:serviceaccount:media:endpoint-watcher            # yes / no
kubectl auth can-i --list \
  --as=system:serviceaccount:media:endpoint-watcher -n media   # everything that SA can do
```

`--as` impersonates any identity (you need impersonation rights, which cluster-admin has); `--list` dumps the full matrix. This is the first move on any Forbidden: reproduce it as a yes/no, then widen with `--list` to see what the subject actually holds.

<details>
<summary>📖 Going deeper: the built-in ClusterRoles, and why you rarely write rules from scratch<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[1]</a></sup></summary>

Kubernetes ships default ClusterRoles you should reach for before hand-writing rules. The four user-facing ones are namespace-grantable via a RoleBinding that references them:

- **view** — read-only on most namespaced resources, *excluding* Secrets (reading Secrets is a privilege escalation — a viewer who could read Secrets could read every ServiceAccount token in the namespace).
- **edit** — read/write on most namespaced resources; still no RBAC editing, and no Secret read by default.
- **admin** — everything `edit` has, plus managing Roles and RoleBindings *within* the namespace.
- **cluster-admin** — everything, everywhere. The built-in `system:masters` group maps here and bypasses RBAC entirely, which is why a leaked cluster-admin kubeconfig is game over.

Grant `view` in one namespace with `kubectl create rolebinding … --clusterrole=view --serviceaccount=ns:sa`. Prefer these to bespoke Roles: they track new resource types as the API grows, and they encode escalation boundaries (like the Secret exclusion) that are easy to get wrong by hand. Write a custom Role only when you need something *narrower* than `view` — a controller that lists exactly one resource, say.

</details>

### ServiceAccounts: a Pod's identity

Authorization needs an identity, and for a Pod that identity is a **ServiceAccount**. Every Pod runs as exactly one SA — the one named in `spec.serviceAccountName`, or `default` if you don't set one — and the kubelet projects a token for that SA into the container at `/var/run/secrets/kubernetes.io/serviceaccount/`<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/">[3]</a></sup>. When the process calls the API with that token, the server authenticates it as `system:serviceaccount:<namespace>:<name>`. That string is the subject your RoleBindings must name — and the identity a Forbidden error quotes back at you.

The `default` SA is the trap. Kubernetes auto-creates a `default` ServiceAccount in every namespace, and it is **bound to nothing** — it can talk to the API server (authenticate) but is authorized for almost nothing<sup><a href="https://kubernetes.io/docs/concepts/security/service-accounts/">[4]</a></sup>. A Pod rolled out without `serviceAccountName` runs as `default`, so a workload that needs API access and whose author forgot the one line gets a `Forbidden` naming `…:default` — even when the Role and RoleBinding they carefully wrote are sitting right there, correct, granting the *intended* SA the Pod never adopted. The difference between "the permission is wrong" and "the caller isn't who you think" is one word in the error: the subject.

The token itself changed in a way worth knowing<sup><a href="https://kubernetes.io/docs/concepts/security/service-accounts/">[4]</a></sup>. Modern clusters project a **bound service account token**: a short-lived JWT, scoped to a specific audience and Pod, auto-rotated by the kubelet, and invalid the moment the Pod is gone. This replaced the old model where every SA got a permanent, non-expiring token stored in a Secret — a token that, if exfiltrated, worked forever. You no longer get an automatic Secret per SA; ask for a token explicitly with `kubectl create token <sa>` when you need one out-of-band. If a workload never calls the API, set `automountServiceAccountToken: false` and it gets no token to leak.

### securityContext and the Pod Security Standards

Authorization governs what a Pod's *process* may ask the API. The last gate governs what the Pod itself may *be*. A container, by default, can run as root, escalate privileges, and hold a broad set of Linux capabilities — fine on a laptop, a liability in a multi-tenant cluster where a container escape becomes a node compromise. The **securityContext** is where you tighten that, at the Pod level (applies to all containers) or per container<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-container/security-context/">[8]</a></sup>:

- `runAsNonRoot: true` — the kubelet refuses to start the container if its image would run as UID 0.
- `runAsUser: 1000` — pin the UID (needed alongside `runAsNonRoot` when the image defaults to root).
- `allowPrivilegeEscalation: false` — no child process can gain more privileges than its parent (blocks setuid escalation).
- `capabilities: { drop: ["ALL"] }` — start from zero Linux capabilities and add back only what's needed.
- `seccompProfile: { type: RuntimeDefault }` — apply the container runtime's default syscall filter.

Setting these on every workload by hand is error-prone, so Kubernetes standardizes them into three **Pod Security Standards** and enforces them per namespace<sup><a href="https://kubernetes.io/docs/concepts/security/pod-security-standards/">[5]</a></sup>:

- **Privileged** — unrestricted. The default when a namespace carries no label.
- **Baseline** — blocks the known-dangerous: no privileged containers, no host namespaces, no `hostPath`. Minimal friction.
- **Restricted** — the hardened profile: everything Baseline blocks, *plus* `runAsNonRoot`, `allowPrivilegeEscalation: false`, `capabilities: drop [ALL]`, and a `seccompProfile`. Exactly the fields listed above.

**PodSecurity admission** turns a Standard on for a namespace with a label, `pod-security.kubernetes.io/<mode>: <level>`, in three independent modes<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-security-admission/enforce-standards-namespace-labels/">[7]</a></sup>:

```bash
kubectl label ns payments \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted
```

`enforce` **rejects** a non-compliant Pod at admission; `audit` records it in the audit log; `warn` returns a warning to the client but admits it. Because the three are independent, the safe rollout pattern is `warn`/`audit` first (learn what would break), then `enforce`.

The failure mode is specific and easy to misread. Because enforce runs at **admission**, a rejection lands on the object that *tries to create* the Pod — for a Deployment, that's the ReplicaSet — not on a Pod, because no Pod is ever created. So a Deployment in an enforced namespace can sit at `0/3` ready with **no Pods at all**, not even `Pending` ones, and the reason is an event on the ReplicaSet: `Error creating: … violates PodSecurity "restricted:latest": …`. `kubectl get pods` shows nothing to describe; you look at the controller or the namespace events. (This mirrors what M06 taught about `NoSchedule`: enforce gates *creation* — Pods already admitted before the label went on keep running.)

## Hands-on

Four steps in the baseline, four break/fix scenarios — all on the full Polyphone fleet on a 2-node cluster. The baseline reads the healthy security posture; each break/fix breaks exactly one gate so you practice reading a single denial at a time.

- **`baseline/`** — who the fleet's Pods are (their ServiceAccounts and projected tokens), what they may do (RBAC roles, bindings, and `kubectl auth can-i`), the `securityContext` they carry, and which namespaces enforce a Pod Security Standard. Healthy security, so a denial stands out later.
- **`breakfix-01-rbac-missing-verb`** — a reader Pod in `CrashLoopBackOff`, its logs a `403 Forbidden`: its Role grants `get`/`watch` on endpoints but the app does a `list`. Tests parsing the Forbidden and reading a Role's rules.
- **`breakfix-02-serviceaccount-default`** — the same 403, but the message names `…:default`: the Pod omits `serviceAccountName`, so the correctly-bound SA is never adopted. Tests reading *which identity* the error names, and fixing the Pod, not the RBAC.
- **`breakfix-03-rbac-cluster-scope`** — a 403 that ends `at the cluster scope`: a namespaced Role/RoleBinding trying to grant `nodes`, which only a ClusterRole can. Tests the scope distinction.
- **`breakfix-04-podsecurity-restricted`** — a Deployment stuck `0/1` with no Pods at all: a workload with no `securityContext` in a namespace that enforces `restricted`. Tests recognizing an admission rejection and writing a compliant `securityContext`.

The first three walk the `Forbidden` differential — one phrase in the message each — and the fourth flips to the admission gate. Check yourself against `ANSWER-KEY.md` after each.

## Common failure modes

| Symptom | Likely cause | Where to look |
|---------|--------------|---------------|
| App logs `Forbidden … cannot list … in the namespace` | An RBAC rule doesn't cover the verb/resource for this SA | `kubectl auth can-i --list --as=system:serviceaccount:ns:sa -n ns`; the Role's `rules` |
| `Forbidden` names `…:default` | Pod runs as the `default` SA (no `serviceAccountName`) | the Pod's `.spec.serviceAccountName`; the RoleBinding's subject |
| `Forbidden … at the cluster scope` | A cluster-scoped resource granted via a namespaced Role/RoleBinding | is it a Role or ClusterRole; `kubectl api-resources --namespaced=false` to confirm the resource is cluster-scoped |
| Deployment `0/N`, no Pods, no `Pending` Pod | PodSecurity `enforce` rejected the Pod at admission | `kubectl get events -n ns`; `kubectl describe rs`; the namespace's `pod-security…/enforce` label |
| Container won't start: `has runAsNonRoot and image will run as root` | `runAsNonRoot: true` but no non-root `runAsUser` and a root image | the `securityContext.runAsUser`; the image's default user |
| `auth can-i` says yes but the app still gets 403 | The Pod isn't using the SA you tested, or its token isn't mounted | the Pod's *actual* SA; `automountServiceAccountToken` |
| Everything denied for an SA that "has admin" | Binding subject name/namespace typo, or RoleBinding vs. ClusterRoleBinding mismatch | `kubectl describe rolebinding/clusterrolebinding`; the subject `kind`/`name`/`namespace` |

## Recap

- **Every API request passes three gates in order** — authentication (who), authorization (may they), admission (is the object allowed) — and a `Forbidden` names which gate and why. Read the gate before you touch the app.
- **RBAC is additive, deny-by-default, and matches strings.** A request is allowed only if some rule, reachable from the caller's identity through a binding, matches its apiGroup, resource, *and* verb. A near-miss (`get` vs. `list`, singular vs. plural) is a silent denial — there is nothing to "unblock," only a rule to make match.
- **A Pod's identity is its ServiceAccount**; unset means `default`, which is bound to nothing. The subject named in a Forbidden tells you whether the permission is wrong or the caller isn't who you meant — one is an RBAC fix, the other a one-line Pod fix.
- **Scope is a hard boundary.** Cluster-scoped resources (nodes, PVs, namespaces) can only be granted by a ClusterRole through a ClusterRoleBinding. A namespaced binding for them parses fine and grants nothing — the error ends `at the cluster scope`.
- **PodSecurity admission enforces the Standards per namespace by label.** `enforce` rejects at *creation*, so a rejected Deployment has zero Pods and the reason lives on the ReplicaSet, not on any Pod. `restricted` needs `runAsNonRoot`, no privilege escalation, dropped capabilities, and a seccomp profile.

## Production thinking

- A ServiceAccount is granted `cluster-admin` "to unblock a rollout" and never walked back. What's the blast radius of that one binding if the Pod using it is compromised — and how would least-privilege (`auth can-i --list` to see what it actually uses, then a scoped Role) have bounded it?
- You enforce `restricted` on a namespace that already runs a dozen workloads. Existing Pods keep running; the next deploy of any of them fails admission. How do you sequence it — `warn`/`audit` first, fix the `securityContext`s, *then* `enforce` — so you learn what breaks before it breaks in production?
- A workload authenticates as `default` and someone "fixes" the Forbidden by granting `default` the permissions it needed. Why is that the wrong fix — what does it hand to every *other* Pod in the namespace that also uses `default`, and what should they have done instead?

## References

1. Kubernetes — Using RBAC Authorization: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
2. Kubernetes — Authorization Overview (checking access, `can-i`): https://kubernetes.io/docs/reference/access-authn-authz/authorization/
3. Kubernetes — Configure Service Accounts for Pods: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
4. Kubernetes — Service Accounts (concept): https://kubernetes.io/docs/concepts/security/service-accounts/
5. Kubernetes — Pod Security Standards: https://kubernetes.io/docs/concepts/security/pod-security-standards/
6. Kubernetes — Pod Security Admission: https://kubernetes.io/docs/concepts/security/pod-security-admission/
7. Kubernetes — Enforce Pod Security Standards with Namespace Labels: https://kubernetes.io/docs/tasks/configure-pod-security-admission/enforce-standards-namespace-labels/
8. Kubernetes — Configure a Security Context for a Pod or Container: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
9. Kubernetes — Controlling Access to the Kubernetes API: https://kubernetes.io/docs/concepts/security/controlling-access/

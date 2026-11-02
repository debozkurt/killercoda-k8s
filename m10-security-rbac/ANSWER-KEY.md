# M10 — Security I: RBAC & Pod Security — Answer Key

> Self-grading reference. Try each scenario first, then check your diagnostic path against the canonical one.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline. Each break/fix layers one small workload onto the fleet. The RBAC scenarios run a `curl` loop that calls the API server with the Pod's projected token, prints the HTTP status, and exits on any failure. The pod-security scenarios run `busybox` in a namespace that enforces `restricted`.

## Lesson summary

M10 covers the three gates every API request passes (authentication, authorization, admission) and the kubelet check that runs before a container starts. Four scenarios break one field of the RBAC refusal each. Two split pod security between admission and the kubelet:

- `breakfix-01-rbac-missing-verb`: **`cannot list`**. The Role grants `get` and `watch` but not `list`.
- `breakfix-02-serviceaccount-default`: **the identity is `…:default`**. The RBAC is correct, and the Pod omits `serviceAccountName`.
- `breakfix-03-rbac-cluster-scope`: **`at the cluster scope`**. A Role and RoleBinding try to grant `nodes`.
- `breakfix-04-podsecurity-restricted`: **a Deployment at 0/1 with no Pods**. Admission rejects each Pod.
- `breakfix-05-rbac-wrong-apigroup`: **`in API group "apps"`**. The Role names `deployments` in the core group.
- `breakfix-06-runasnonroot-root-image`: **a Pod in `CreateContainerConfigError`**. Admission accepts it, and the kubelet refuses a root image.

The through-line: **read the refusal before you change anything.** The RBAC message names identity, verb, resource, API group, and scope, and each field maps to one object<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[1]</a></sup>. `kubectl auth can-i --as=…` turns a crash-looping 403 into a `yes` or `no` that you can test in a second<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/authorization/">[2]</a></sup>.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (ServiceAccounts):** `get serviceaccounts -n media` lists `default`. `describe pod` for `session-broker` shows `Service Account:  default`. The mounted directory holds `ca.crt`, `namespace`, and `token`. `auth can-i --list` as `media:default` shows only the self-review resources and discovery paths.
- **Step 2 (RBAC):** `get clusterroles view edit admin cluster-admin` lists the four built-ins. `describe clusterrole view` prints rule rows such as `deployments.apps … [get list watch]`, and no `secrets` row. `auth can-i get pods` as `media:default` returns `no`.
- **Step 3 (Grant and prove):** after `create serviceaccount config-reader` and `create rolebinding config-reader-view --clusterrole=view`, `describe rolebinding` shows `Kind: ClusterRole`, `Name: view`, and the ServiceAccount subject. `auth can-i` returns `yes` for configmaps in `media`, `no` in `signaling` (the RoleBinding's scope), and `no` for secrets in `media` (the role's content).
- **Step 4 (securityContext):** the Pod YAML has `securityContext: {}` and no container block. `id -u` prints 0.
- **Step 5 (PodSecurity):** no fleet namespace has a pod-security label. In `psa-demo` with `enforce=restricted`, `kubectl run bad` fails with `violates PodSecurity "restricted:latest"` and lists four checks. `create deployment bad-deploy` prints `Warning: would violate PodSecurity` and creates a Deployment that stays 0/1 with no Pods. `describe rs` shows `FailedCreate`. The compliant `good` Pod reaches `Running`<sup><a href="https://kubernetes.io/docs/concepts/security/pod-security-admission/">[3]</a></sup>.

---

## Break/fix 01 — RBAC: a missing verb

**Symptom:** `endpoint-watcher` in `media` is in `CrashLoopBackOff`. Its logs show `HTTP 403` and a `Forbidden` status, and then the process exits.

**Root cause:** The Role `endpoint-reader` grants `get` and `watch` on `endpoints`, not `list`. The reader sends a GET to the endpoints collection, and the API server maps a collection GET to the `list` verb. No rule matches, so authorization refuses the request<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[1]</a></sup>.

**Diagnostic commands:**

```bash
kubectl get pods -n media -l app=endpoint-watcher           # CrashLoopBackOff
kubectl logs -n media deploy/endpoint-watcher --tail=8
# User "system:serviceaccount:media:endpoint-watcher" cannot list resource "endpoints"
# in API group "" in the namespace "media"
# identity: the workload's own account | verb: list | group: core | scope: media
kubectl auth can-i list endpoints -n media \
  --as=system:serviceaccount:media:endpoint-watcher         # no
kubectl describe role endpoint-reader -n media              # endpoints  []  []  [get watch]
```

**Fix:**

```bash
kubectl patch role endpoint-reader -n media --type=json \
  -p '[{"op":"replace","path":"/rules/0/verbs","value":["get","list","watch"]}]'
```

**Verify:**

```bash
kubectl auth can-i list endpoints -n media \
  --as=system:serviceaccount:media:endpoint-watcher         # yes
kubectl rollout restart deployment endpoint-watcher -n media   # skip the backoff wait
kubectl logs -n media deploy/endpoint-watcher --tail=2      # HTTP 200
```

**What this scenario tests:** reading a 403 as a permission fault, and the `get` versus `list` distinction.

- Did you treat the crash loop as a permission failure before you checked the image or the code?
- Did you match the verb in the message against the verbs column of the Role?
- Did you add one verb, rather than a wildcard or `cluster-admin`?

**Expected time:** 3–5 min with the reflex; 10–15 min the first time.

**Production thinking:** Near-miss grants are the common case. A controller gets `get`, then a new version starts to list a collection. Grant the verbs the client sends, and test them with `auth can-i` in CI. A wildcard verb turns a reader into something that can delete.

---

## Break/fix 02 — ServiceAccount: the default identity

**Symptom:** `route-watcher` in `call-routing` is in `CrashLoopBackOff` with a 403. A dedicated ServiceAccount, Role, and RoleBinding all exist.

**Root cause:** The Pod template has no `serviceAccountName`, so each Pod runs as `call-routing:default`. The RoleBinding grants `route-watcher`, and `default` holds no grant<sup><a href="https://kubernetes.io/docs/concepts/security/service-accounts/">[4]</a></sup>.

**Diagnostic commands:**

```bash
kubectl logs -n call-routing deploy/route-watcher --tail=8
# User "system:serviceaccount:call-routing:default" cannot list resource "endpoints" ...
kubectl auth can-i list endpoints -n call-routing \
  --as=system:serviceaccount:call-routing:route-watcher     # yes: the grant works
kubectl auth can-i list endpoints -n call-routing \
  --as=system:serviceaccount:call-routing:default           # no
kubectl describe pod -n call-routing -l app=route-watcher | grep -m1 'Service Account'
# Service Account:  default
```

**Fix:**

```bash
kubectl set serviceaccount deployment route-watcher route-watcher -n call-routing
```

**Verify:**

```bash
kubectl rollout status deployment route-watcher -n call-routing --timeout=60s
kubectl describe pod -n call-routing -l app=route-watcher | grep -m1 'Service Account'   # route-watcher
kubectl logs -n call-routing deploy/route-watcher --tail=2  # HTTP 200
```

**What this scenario tests:** reading the identity field before the permission fields.

- Did you notice `default` in the message before you opened the Role?
- Did you prove the grant was correct with `auth can-i` on the intended account?
- Did you change the Pod, and leave `default` with no grant?

**Expected time:** 3–5 min with the reflex; 10–15 min the first time.

**Production thinking:** A grant to `default` reaches every Pod in the namespace that omits `serviceAccountName`, now and in the future. Give each workload that calls the API its own ServiceAccount. Set `automountServiceAccountToken: false` on the `default` account, so a Pod that forgets the field gets no token instead of a borrowed identity. A policy engine (M20) can require the field.

---

## Break/fix 03 — RBAC: cluster scope

**Symptom:** `node-inspector` in `analytics` is in `CrashLoopBackOff` with a 403. A Role names `nodes` with get, list, and watch, and a RoleBinding grants it.

**Root cause:** Nodes are cluster-scoped. A RoleBinding grants only inside its own namespace, so it never reaches a resource that has none. The API server accepts the Role and the Role grants nothing. Only a ClusterRole bound by a ClusterRoleBinding grants a cluster-scoped resource<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[1]</a></sup>.

**Diagnostic commands:**

```bash
kubectl logs -n analytics deploy/node-inspector --tail=8
# cannot list resource "nodes" in API group "" at the cluster scope
kubectl api-resources --namespaced=false | grep -w nodes
kubectl get role,rolebinding -n analytics                   # namespaced grant
kubectl auth can-i list nodes \
  --as=system:serviceaccount:analytics:node-inspector       # no (no -n: cluster question)
```

**Fix:**

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding node-inspector \
  --clusterrole=node-reader --serviceaccount=analytics:node-inspector
# remove the inert grant; two kinds in one command need the kind/name form
kubectl delete role/node-reader rolebinding/node-inspector-binding -n analytics
```

**Verify:**

```bash
kubectl auth can-i list nodes --as=system:serviceaccount:analytics:node-inspector   # yes
kubectl rollout restart deployment node-inspector -n analytics
kubectl logs -n analytics deploy/node-inspector --tail=2    # HTTP 200
```

**What this scenario tests:** the scope field, and which binding kind reaches which resource.

- Did you read the message to its end and see `at the cluster scope`?
- Did you confirm the resource is cluster-scoped with `api-resources`?
- Did you run `auth can-i` without `-n` for a cluster-scoped question?

**Expected time:** 4–6 min with the reflex; 12–20 min the first time.

**Production thinking:** A ClusterRoleBinding is the widest grant RBAC has. Keep the ClusterRole narrow (one resource, read verbs), and review every ClusterRoleBinding that names a ServiceAccount. A `get` on `nodes/proxy` looks like a read, and it reaches the kubelet API.

---

## Break/fix 04 — PodSecurity: restricted admission

**Symptom:** `payments-api` in `payments` reports 0/1. `kubectl get pods -n payments` prints nothing. No Pod is `Pending` or crashing.

**Root cause:** The namespace has `pod-security.kubernetes.io/enforce=restricted`, and the Pod template has no `securityContext`. `enforce` checks Pods, not Deployments. The ReplicaSet controller asks for each Pod, and admission rejects it before it is stored<sup><a href="https://kubernetes.io/docs/concepts/security/pod-security-admission/">[3]</a></sup>.

**Diagnostic commands:**

```bash
kubectl get deploy,rs,pods -n payments          # 0/1, rs desired 1 current 0, no pods
kubectl describe rs -n payments -l app=payments-api
# FailedCreate: pods "payments-api-…" is forbidden: violates PodSecurity "restricted:latest":
# allowPrivilegeEscalation != false, unrestricted capabilities, runAsNonRoot != true, seccompProfile
kubectl describe deploy payments-api -n payments # ReplicaFailure True FailedCreate
kubectl describe ns payments                     # Labels: …/enforce=restricted
```

**Fix:**

```bash
kubectl patch deployment payments-api -n payments -p '{
  "spec": {"template": {"spec": {
    "securityContext": {"runAsNonRoot": true, "runAsUser": 1000, "seccompProfile": {"type": "RuntimeDefault"}},
    "containers": [{"name": "app", "securityContext": {"allowPrivilegeEscalation": false, "capabilities": {"drop": ["ALL"]}}}]
  }}}
}'
```

`runAsUser: 1000` is required because busybox runs as root. Without it, the Pod passes admission and fails at the kubelet (break/fix 06).

**Verify:**

```bash
kubectl rollout status deployment payments-api -n payments --timeout=60s
kubectl get deploy,pods -n payments              # 1/1, Pod Running
```

**What this scenario tests:** recognizing an admission rejection by the absence of Pods.

- Did you go to the ReplicaSet when `get pods` returned nothing?
- Did you treat the violation text as the list of fields to set?
- Did you fix the workload and leave the namespace label alone?

**Expected time:** 5–8 min with the reflex; 15–20 min the first time.

**Production thinking:** `enforce` checks only creation, so the label does not stop running Pods. It stops their next replacement, which may come from a node drain at 03:00. Before you set `enforce`, run `kubectl label --dry-run=server --overwrite ns <name> pod-security.kubernetes.io/enforce=restricted`. The API server lists each existing Pod that would fail<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/">[5]</a></sup>. Put the `restricted` fields in your base manifests so a new namespace policy changes nothing.

---

## Break/fix 05 — RBAC: wrong API group

**Symptom:** `release-auditor` in `provisioning` is in `CrashLoopBackOff` with a 403. The Role grants get, list, and watch on `deployments`.

**Root cause:** The rule names `deployments` with `apiGroups: [""]`, the core group. Deployments belong to `apps`. RBAC matches the group as an exact string, so the rule matches no real request<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[1]</a></sup>.

**Diagnostic commands:**

```bash
kubectl logs -n provisioning deploy/release-auditor --tail=8
# deployments.apps is forbidden: ... cannot list resource "deployments" in API group "apps"
kubectl describe role release-reader -n provisioning   # deployments  []  []  [get list watch]
#   no ".apps" suffix: the rule is in the core group
kubectl api-resources | grep -w deployments            # APIVERSION apps/v1
kubectl auth can-i list deployments -n provisioning \
  --as=system:serviceaccount:provisioning:release-auditor   # no
```

**Fix:**

```bash
kubectl patch role release-reader -n provisioning --type=json \
  -p '[{"op":"replace","path":"/rules/0/apiGroups","value":["apps"]}]'
```

**Verify:**

```bash
kubectl describe role release-reader -n provisioning   # deployments.apps
kubectl auth can-i list deployments -n provisioning \
  --as=system:serviceaccount:provisioning:release-auditor   # yes
kubectl rollout restart deployment release-auditor -n provisioning
kubectl logs -n provisioning deploy/release-auditor --tail=2   # HTTP 200
```

**What this scenario tests:** the API group field, and reading the group suffix in `describe role`.

- Did you compare `in API group "apps"` with the rule's group, not only its verbs?
- Did you read the missing `.apps` suffix in the `Resources` column?
- Did you look up the group with `api-resources` rather than guess?

**Expected time:** 3–6 min with the reflex; 10–15 min the first time.

**Production thinking:** Wrong groups appear after API migrations (an `extensions` rule left behind) and in rules typed from memory. `kubectl create role --verb=list --resource=deployments` resolves the group through discovery. Prefer it, or copy the group from `kubectl api-resources`.

<details>
<summary>📖 Going deeper: auditing who can reach what<sup><a href="https://kubernetes.io/docs/concepts/security/rbac-good-practices/">[6]</a></sup></summary>

During a review, start from the identity, not the YAML. `kubectl auth can-i --list --as=system:serviceaccount:<ns>:<name> -n <ns>` prints the effective rules after every binding is applied. Repeat it without `-n` for cluster-scoped grants.

Then search for the escalation paths in the good-practices guide:

- `create` on `pods` or on a workload resource gives access to every Secret and ServiceAccount in the namespace.
- `escalate`, `bind`, and `impersonate` bypass RBAC's own escalation checks.
- `get` on `nodes/proxy` reaches the kubelet API.

The built-in `edit` ClusterRole carries the first path. A team with `edit` can read Secrets and run Pods as any ServiceAccount in its namespace.

</details>

---

## Break/fix 06 — runAsNonRoot: a root image

**Symptom:** `ledger-sync` in `payments` reports 0/1. A Pod exists, and its status is `CreateContainerConfigError`.

**Root cause:** The Pod sets `runAsNonRoot: true` and no `runAsUser`. busybox declares no `USER`, so the container would run as UID 0. Admission passes the Pod, because `restricted` requires `runAsNonRoot` and does not require `runAsUser`. The kubelet then checks the effective user and refuses to create the container<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-container/security-context/">[7]</a></sup>.

**Diagnostic commands:**

```bash
kubectl get deploy,pods -n payments              # Pod: CreateContainerConfigError
kubectl describe pod -n payments -l app=ledger-sync
# Events: Error: container has runAsNonRoot and image will run as root
kubectl get deploy ledger-sync -n payments -o yaml | grep -A4 'securityContext:'
# runAsNonRoot: true, no runAsUser
```

**Fix:**

```bash
kubectl patch deployment ledger-sync -n payments -p '{
  "spec": {"template": {"spec": {"securityContext": {"runAsUser": 1000}}}}
}'
```

Or use an image that declares a numeric non-root `USER`. A named `USER` fails the same check, because the kubelet cannot prove a name is not root.

**Verify:**

```bash
kubectl rollout status deployment ledger-sync -n payments --timeout=60s
kubectl exec -n payments deploy/ledger-sync -- id -u     # 1000
```

**What this scenario tests:** telling the kubelet's refusal from admission's.

- Did a Pod that exists send you to the Pod's events, not the ReplicaSet's?
- Did you see that `runAsNonRoot` checks the user and does not set it?
- Did you keep `runAsNonRoot: true` and add a user, rather than remove the check?

**Expected time:** 3–5 min with the reflex; 10–15 min the first time.

**Production thinking:** `restricted` admission does not prove a Pod will start. Build images with a numeric non-root `USER`, so the image itself passes the kubelet check. Test the hardened manifest in a namespace that enforces `restricted` before the rollout, because the failure appears only at container creation.


## References

1. Kubernetes — Using RBAC Authorization: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
2. Kubernetes — Authorization (checking API access): https://kubernetes.io/docs/reference/access-authn-authz/authorization/
3. Kubernetes — Pod Security Admission: https://kubernetes.io/docs/concepts/security/pod-security-admission/
4. Kubernetes — Service Accounts: https://kubernetes.io/docs/concepts/security/service-accounts/
5. Kubernetes — Enforce Pod Security Standards with Namespace Labels: https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/
6. Kubernetes — Role Based Access Control Good Practices: https://kubernetes.io/docs/concepts/security/rbac-good-practices/
7. Kubernetes — Configure a Security Context for a Pod or Container: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

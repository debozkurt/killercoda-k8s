# M11 — Security II: Secrets at Scale — Answer Key

> Self-grading reference. Try each scenario first, then check your diagnostic path against the canonical one.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline plus a secrets pipeline. The backing store is the Secret `vault-backend` in `secrets-source`, in place of an external secrets manager. The `SecretSync` CRD models an External Secrets Operator `ExternalSecret`. The `secret-operator` loop (an `alpine/k8s` Pod in `secrets-system`) runs every 10 seconds and reports `Synced`, `SyncError`, `StoreNotReady`, or `SecretWriteError` in `.status`. Two consumers read the derived Secrets: `billing-processor` in `provisioning` and `partner-connector` in `media`.

## Lesson summary

M11 covers what happens to a Secret when GitOps forbids plaintext in Git. A controller materializes each Secret from a store or from an encrypted file, and the consumer reads the result. The failure surface moves from the Pod into the pipeline. Five scenarios break one link each:

- `breakfix-01-source-key-missing`: **one sync in `SyncError`**. The reference names a key that the store lacks.
- `breakfix-02-store-access-denied`: **every sync in `StoreNotReady`**. The store RoleBinding names a ServiceAccount that does not exist.
- `breakfix-03-rotation-not-propagated`: **a green pipeline and an old password in the process**. The consumer reads an environment variable.
- `breakfix-04-target-write-denied`: **one namespace in `SecretWriteError`**. The write grant sits in the wrong namespace.
- `breakfix-05-subpath-rotation-stale`: **a green pipeline and an old token in a file**. The consumer mounts the key with `subPath`.

The through-line: **read the producing object's status, and let the failure pattern pick the link.** One failed sync means its reference. A fan-out that names one store means the store. One failing namespace means a grant in that namespace. A green pipeline with a wrong process means the consumption mode<sup><a href="https://kubernetes.io/docs/concepts/configuration/secret/">[1]</a></sup>.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (inputs):** `get secretsync -A` lists `db-credentials` and `partner-api`, both `True` and `Synced`. `describe secretsync db-credentials` shows `Source Key: db-password`, `Secret Key: DB_PASSWORD`, `Store Ref: Name: vault-backend`. `describe secret vault-backend` lists three keys with byte sizes and no values.
- **Step 2 (derived Secret):** `describe secret db-credentials` shows the label `managed-by=secret-operator`. Both decode commands print `S3cure-prod-4417`. The label selector lists two Secrets.
- **Step 3 (operator report):** the operator Pod is `Running`. The `Status:` block reads `Ready: True`, `Reason: Synced`, `Synced Keys: DB_PASSWORD`. The logs print one `Synced ->` line per sync per pass.
- **Step 4 (consumer):** `describe deployment billing-processor` shows `DB_PASSWORD: <set to the key 'DB_PASSWORD' in secret 'db-credentials'>`. `printenv` prints `S3cure-prod-4417`.
- **Step 5 (revert):** the first read after the patch prints `hand-edited`. After `sleep 15` it prints `S3cure-prod-4417`, and the sync still reads `Synced`. ESO behaves the same under the default `creationPolicy: Owner`: it watches the target and compares a data-hash annotation<sup><a href="https://external-secrets.io/latest/api/externalsecret/">[2]</a></sup>.
- **Step 6 (etcd):** `grep -c` prints `0`. The `etcdctl get` output, with unprintable bytes as dots, contains `k8s`, `Secret`, `db-credentials`, `DB_PASSWORD`, and `S3cure-prod-4417` in clear text. With an `EncryptionConfiguration`, the value starts with `k8s:enc:` and the rest is ciphertext<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/">[3]</a></sup>.

---

## Break/fix 01 — Missing source key

**Symptom:** `partner-connector` in `media` is in `CreateContainerConfigError`. The Secret `partner-api` does not exist. The billing side is healthy.

**Root cause:** The `SecretSync` `partner-api` names `sourceKey: api-tokn`. The store holds `api-token`. The operator refuses to write a partial Secret, so it reports `SyncError` and writes nothing.

**Diagnostic commands:**

```bash
kubectl get pods -n media -l app=partner-connector        # CreateContainerConfigError
kubectl describe pod -n media -l app=partner-connector    # Error: secret "partner-api" not found
kubectl get secretsync -A                                 # partner-api False SyncError; db-credentials Synced
kubectl describe secretsync partner-api -n media
# Status: Message: source keys not found in store: api-tokn
# Spec:   Source Key: api-tokn
kubectl describe secret vault-backend -n secrets-source   # api-token, db-password, signing-key
```

**Fix:**

```bash
kubectl patch secretsync partner-api -n media --type=json \
  -p '[{"op":"replace","path":"/spec/data/0/sourceKey","value":"api-token"}]'
```

**Verify:**

```bash
kubectl get secretsync -A                                 # both Synced
kubectl get pods -n media -l app=partner-connector        # Running 1/1, no manual restart
kubectl exec deploy/partner-connector -n media -- printenv API_TOKEN
```

**What this scenario tests:** reading the producing object before the consumer.

- Did you open the `SecretSync` before you considered creating the Secret by hand?
- Did one failed sync, next to one healthy sync, rule out the store and the operator?
- Did you fix the reference, rather than add an `api-tokn` key to the store?

**Expected time:** 3–5 min with the reflex; 10–15 min the first time.

**Production thinking:** In ESO the same fault reads `SecretSyncedError` on the `ExternalSecret`, with the provider's "not found" in the message. Validate `remoteRef` keys in CI against the store's key list where the store allows it. A hand-created Secret hides the bug until the controller overwrites it.

---

## Break/fix 02 — Store access denied

**Symptom:** `billing-processor` and `partner-connector` are both in `CreateContainerConfigError`. Every `SecretSync` reads `StoreNotReady`. The operator Pod is `Running`.

**Root cause:** The RoleBinding `secret-operator-store` in `secrets-source` grants store access to `secret-operator-ro`, a ServiceAccount that does not exist. The operator runs as `secret-operator` and cannot read the store<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[4]</a></sup>.

**Diagnostic commands:**

```bash
kubectl get secretsync -A                                 # both False StoreNotReady
kubectl describe secretsync db-credentials -n provisioning
# Message: cannot read backing store secrets-source/vault-backend
kubectl get pods -n secrets-system                        # Running, 0 restarts
kubectl auth can-i get secrets -n secrets-source \
  --as=system:serviceaccount:secrets-system:secret-operator   # no
kubectl describe rolebinding secret-operator-store -n secrets-source
# Subjects: ServiceAccount  secret-operator-ro  secrets-system
kubectl get serviceaccounts -n secrets-system             # default, secret-operator
```

**Fix:**

```bash
kubectl patch rolebinding secret-operator-store -n secrets-source --type=json \
  -p '[{"op":"replace","path":"/subjects/0/name","value":"secret-operator"}]'
```

**Verify:**

```bash
kubectl auth can-i get secrets -n secrets-source \
  --as=system:serviceaccount:secrets-system:secret-operator   # yes
kubectl get secretsync -A                                 # both Synced within 10 s
kubectl get pods -n provisioning -l app=billing-processor
kubectl get pods -n media -l app=partner-connector        # both Running 1/1
```

**What this scenario tests:** store-first diagnosis, and proving a controller's identity.

- Did you read the identical reason on both syncs as one cause before you opened either consumer?
- Did you test the operator's ServiceAccount with `auth can-i --as`, rather than your own access?
- Did you fix the one binding, rather than grant the operator Secrets cluster-wide?

**Expected time:** 3–5 min with the reflex; 10–20 min the first time.

**Production thinking:** In ESO the store itself reports the fault. The `SecretStore` goes `Ready=False` with `ValidationFailed`, and every `ExternalSecret` that uses it fails<sup><a href="https://external-secrets.io/latest/provider/kubernetes/">[5]</a></sup>. Alert on store readiness, not on each `ExternalSecret`. Existing Secrets keep their last value, so the outage starts only when a Pod reschedules or a new namespace needs a Secret.

---

## Break/fix 03 — Rotation not propagated (environment variable)

**Symptom:** Both syncs read `Synced`. The store and `db-credentials` hold `R0tated-prod-8842`. `billing-processor` still presents `S3cure-prod-4417`.

**Root cause:** `billing-processor` reads `DB_PASSWORD` from the Secret as an environment variable. The kubelet set it when the container started, before the rotation. A Secret update never changes a running container's environment, and nothing restarts the Pod<sup><a href="https://kubernetes.io/docs/concepts/configuration/secret/">[1]</a></sup>.

**Diagnostic commands:**

```bash
kubectl get secretsync -A                                 # both Synced
kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' | base64 -d; echo
kubectl get secret db-credentials -n provisioning -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo
# both R0tated-prod-8842
kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD   # S3cure-prod-4417
kubectl describe deployment billing-processor -n provisioning   # Environment: DB_PASSWORD <set to the key ...>
kubectl get pods -n provisioning -l app=billing-processor       # old AGE, 0 restarts
```

**Fix:**

```bash
kubectl rollout restart deployment/billing-processor -n provisioning
kubectl rollout status deployment/billing-processor -n provisioning
```

**Verify:**

```bash
kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD   # R0tated-prod-8842
```

**What this scenario tests:** distrusting a green status, and reading the value the process holds.

- Did you compare the process's value with the Secret, rather than stop at `Synced`?
- Did you name the consumption mode (env, set at container start) as the cause?
- Did you leave the store, the sync, and the Secret alone, because they were correct?

**Expected time:** 3–5 min with the reflex; 10–15 min the first time.

**Production thinking:** A checksum annotation on the Pod template does not help a synced Secret, because the operator changes the Secret after the deploy tool rendered the manifest. Run a controller that watches the Secret and restarts its consumers, or mount the Secret as a directory and make the application reload it. Keep the old credential valid in the backend until every consumer runs on the new one.

---

## Break/fix 04 — Target write denied

**Symptom:** `billing-processor` in `provisioning` is in `CreateContainerConfigError`. `db-credentials` reads `SecretWriteError`. `partner-api` in `media` reads `Synced`.

**Root cause:** The RoleBinding `secret-operator-targets` meant for `provisioning` was created in `secrets-system`. A RoleBinding grants only inside its own namespace, so the operator can write Secrets in `secrets-system` and `media` but not in `provisioning`<sup><a href="https://kubernetes.io/docs/reference/access-authn-authz/rbac/">[4]</a></sup>.

**Diagnostic commands:**

```bash
kubectl get secretsync -A                                 # db-credentials SecretWriteError; partner-api Synced
kubectl describe secretsync db-credentials -n provisioning
# Message: cannot write target Secret provisioning/db-credentials
kubectl logs deployment/secret-operator -n secrets-system --tail=4
# ... is forbidden: User "system:serviceaccount:secrets-system:secret-operator"
#     cannot get resource "secrets" in API group "" in the namespace "provisioning"
kubectl auth can-i create secrets -n provisioning \
  --as=system:serviceaccount:secrets-system:secret-operator   # no
kubectl auth can-i create secrets -n media \
  --as=system:serviceaccount:secrets-system:secret-operator   # yes
kubectl get rolebindings -A | grep secret-operator        # targets in media and secrets-system only
```

**Fix:**

```bash
kubectl create rolebinding secret-operator-targets -n provisioning \
  --clusterrole=secret-operator-secrets \
  --serviceaccount=secrets-system:secret-operator
kubectl delete rolebinding secret-operator-targets -n secrets-system
```

**Verify:**

```bash
kubectl get secretsync -A                                 # both Synced
kubectl get pods -n provisioning -l app=billing-processor # Running 1/1
```

**What this scenario tests:** using the failure's scope to pick the binding.

- Did a healthy sync from the same store rule out the store read?
- Did you compare `auth can-i` across the failing and the healthy namespace?
- Did you recognize that the binding's namespace, not its subject's namespace, sets its scope?

**Expected time:** 4–6 min with the reflex; 12–20 min the first time.

**Production thinking:** Onboard a namespace to the secrets pipeline with one template that creates the `ExternalSecret` and the controller's RoleBinding together. ESO typically runs with a cluster-wide grant, which removes this failure and widens the blast radius of a compromised controller. A per-namespace grant keeps the blast radius small, and its cost is this exact failure.

---

## Break/fix 05 — subPath rotation stale

**Symptom:** Both syncs read `Synced`. The store and `partner-api` hold `pt_live_rotated_51e0c7`. The file `/etc/partner/API_TOKEN` in `partner-connector` still holds `pt_live_9c2f8a1b7e004d3a`.

**Root cause:** `partner-connector` mounts the key `API_TOKEN` with `subPath`. The kubelet updates a Secret volume in place, but "a container using a Secret as a subPath volume mount does not receive automated Secret updates"<sup><a href="https://kubernetes.io/docs/concepts/configuration/secret/">[1]</a></sup>.

**Diagnostic commands:**

```bash
kubectl get secretsync -A                                 # both Synced
kubectl get secret partner-api -n media -o jsonpath='{.data.API_TOKEN}' | base64 -d; echo   # new token
kubectl exec deploy/partner-connector -n media -- cat /etc/partner/API_TOKEN; echo         # old token
kubectl describe pod -n media -l app=partner-connector
# Mounts: /etc/partner/API_TOKEN from partner-api (ro,path="API_TOKEN")
```

**Fix:**

```bash
kubectl patch deployment partner-connector -n media --type=json -p '[
  {"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/0/mountPath","value":"/etc/partner"},
  {"op":"remove","path":"/spec/template/spec/containers/0/volumeMounts/0/subPath"}]'
```

**Verify:**

```bash
kubectl exec deploy/partner-connector -n media -- cat /etc/partner/API_TOKEN   # new token
kubectl patch secret vault-backend -n secrets-source --type=merge \
  -p '{"stringData":{"api-token":"pt_live_rotated_second"}}'
# within about two minutes, the same Pod's file reads pt_live_rotated_second with 0 restarts
```

**What this scenario tests:** reading the mount, not only the source of the value.

- Did you find the `path=` flag on the `Mounts:` line?
- Did you expect a volume to update, and then ask why this one did not?
- Did you prove the fix with a second rotation and no restart?

**Expected time:** 4–6 min with the reflex; 12–20 min the first time.

**Production thinking:** A `subPath` mount is common when an image expects one file in a directory that holds other files. Mount the Secret into its own directory and point the application at that path, or use a projected volume. A file that updates is half of the fix. The application must read the file again, through a file watch or a read on each use, or it keeps the old value in memory.

## References

1. Kubernetes — Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
2. External Secrets Operator — ExternalSecret: https://external-secrets.io/latest/api/externalsecret/
3. Kubernetes — Encrypting Confidential Data at Rest: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
4. Kubernetes — Using RBAC Authorization: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
5. External Secrets Operator — Kubernetes provider: https://external-secrets.io/latest/provider/kubernetes/

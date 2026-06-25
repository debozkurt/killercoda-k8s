# M03 — Configuration

> How a Pod gets its configuration — ConfigMaps and Secrets, injected as environment variables or mounted as files — and the four ways that wiring breaks: the Pod won't start, won't update, or runs but reads the wrong value.

## What you'll learn

- Separate a workload's *config* from its *image*, and choose between the two delivery mechanisms: environment variables and mounted files
- Wire a Pod to a ConfigMap and a Secret with `env`, `envFrom`, and volume mounts — and predict the update behavior each one gives you
- Explain why an env var never changes after the container starts, while a mounted file does — eventually — and what `subPath` and `immutable` change about that
- Read a Secret's real contents and explain why base64 is encoding, not security
- Work the config-failure differential: tell `CreateContainerConfigError` from a stuck `ContainerCreating`, and both from a Pod that's `Running` on the wrong value

## Why it matters

The same image runs in `dev`, `stage`, and `prod`; what differs is configuration — the log level, the database host, the feature flags, the credentials. Kubernetes keeps that configuration out of the image, in ConfigMaps and Secrets, and injects it at container start. When the wiring is wrong, the failure lands in one of a few recognizable shapes, and an SRE who can name the shape fixes it in two minutes instead of twenty.

The traps are specific and they recur: a Pod that won't start because a referenced key doesn't exist; a Pod stuck in `ContainerCreating` mounting a Secret that was never created; a ConfigMap someone edited that changed nothing because the consuming Pods were never restarted; and the worst case — a Pod that is `Running` and `Ready` while serving a garbled credential. Each is a different root cause with a different fix, and each starts with reading the Pod's status and events — the instinct M00 and M02 drilled, pointed now at configuration.

## Scope

**Covers:** ConfigMaps and Secrets (Opaque and the common typed Secrets), the two ways a Pod consumes them — environment variables (`env`, `envFrom`) and mounted files (volume and projected volumes) — the update/propagation semantics of each, `immutable`, the downward API in passing, and the config-failure differential (`CreateContainerConfigError`, `FailedMount`, runs-but-wrong).

**Doesn't cover:** keeping Secrets *actually* secret at scale — encryption-at-rest config, External Secrets Operator, Vault, sealed-secrets, sops → M11 (Security II — Secrets at Scale). RBAC on who can read a Secret → M10. TLS material and cert issuance → M12. Templating config across environments (Kustomize/Helm overlays, the config-hash rollout pattern in anger) → M16–M19. This module is the *mechanics*: how config reaches a container and how that reach fails.

**Assumes:** M00 (`get → describe → events → logs`; spec vs status) and M01 (Pods, Deployments, container states, a rolling update). You know a container is a process started from an image (M02); this module is about handing that process its settings.

## Vocabulary

| Term | Definition |
|------|------------|
| **ConfigMap** | A namespaced API object holding non-confidential config as key/value pairs. Consumed as env vars or files. Capped at 1 MiB. |
| **Secret** | Like a ConfigMap, but for confidential data. Values are base64-encoded in `data` and stored in etcd. Encoding is not encryption. |
| **`data` / `stringData`** | A Secret's `data` holds base64-encoded values; `stringData` is a write-only convenience field — you write plaintext, the API server encodes it into `data` and never reads it back. |
| **Opaque** | The default Secret `type`. Other types (`kubernetes.io/dockerconfigjson`, `kubernetes.io/tls`, `kubernetes.io/service-account-token`) carry a required-key schema the kubelet understands. |
| **`env` / `envFrom`** | `env` injects one named key as an environment variable (`valueFrom.configMapKeyRef`/`secretKeyRef`); `envFrom` injects *every* key of a ConfigMap/Secret as env vars. |
| **volume mount** | Projecting a ConfigMap/Secret into a directory, one file per key. The other consumption mode; the one that updates live. |
| **projected volume** | A single mount that combines several sources — `configMap`, `secret`, `downwardAPI`, `serviceAccountToken` — into one directory. |
| **downward API** | A mechanism to expose Pod/container fields (name, namespace, IP, resource limits) to the container as env vars or files. |
| **`optional`** | A flag on a config reference that lets the Pod start even if the ConfigMap/Secret/key is absent, instead of failing. |
| **`immutable`** | A flag that freezes a ConfigMap/Secret's contents (delete-and-recreate to change) and lets the kubelet stop watching it. |
| **`CreateContainerConfigError`** | Container status: the kubelet couldn't assemble the container's config — usually a missing referenced key or object in an `env`/`envFrom` reference. |

## Mental model

Configuration lives in one place — a ConfigMap or Secret in etcd — and reaches a container by one of two paths. The path you pick decides everything downstream: how a missing reference fails, and whether a later edit ever reaches the running process.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'primaryColor':'#2b2b2b', 'primaryTextColor':'#e6e6e6',
  'primaryBorderColor':'#7a7a7a', 'lineColor':'#9a9a9a',
  'secondaryColor':'#3a3a3a', 'tertiaryColor':'#1f1f1f',
  'background':'#0f0f0f'
}}}%%
flowchart TD
    SRC[ConfigMap / Secret<br/>key=value in etcd]
    SRC -->|env / envFrom| ENV[Environment variables<br/>materialized once at container start]
    SRC -->|volume / projected| VOL[Files in a mounted directory<br/>one file per key]
    ENV --> PROC[Container process]
    VOL --> PROC
    ENV -.source edited later.-> FROZEN[Frozen — process keeps old value<br/>until the Pod is restarted]
    VOL -.source edited later.-> LIVE[Updated in place<br/>~kubelet sync period; subPath is excepted]
```

Two consequences fall out of this split. **At start:** a missing env reference fails the container *during creation* (`CreateContainerConfigError`); a missing mounted object fails *before* creation, leaving the Pod stuck in `ContainerCreating` on a `FailedMount`. **After start:** an env value is frozen for the life of the container, while a mounted file tracks the source — unless it's a `subPath` mount. Read the status and you know which path broke; know the path and you know whether an edit will ever take.

## Concept walkthrough

### ConfigMaps and Secrets: two objects, one shape

A ConfigMap is a bag of key/value pairs for non-confidential settings — log levels, hostnames, tuning parameters, whole config files as multi-line values<sup><a href="https://kubernetes.io/docs/concepts/configuration/configmap/">[1]</a></sup>. A Secret is the same shape for confidential data, with two differences: values are base64-encoded in `data`, and the API treats them with more care (typed Secrets, separate RBAC conventions, optional encryption at rest)<sup><a href="https://kubernetes.io/docs/concepts/configuration/secret/">[2]</a></sup>. Both are namespaced and capped at **1 MiB** — they live in etcd and every kubelet that mounts one holds it in memory, so they're for settings, not data blobs.

The base64 in a Secret is the single most misunderstood thing in this module. **Base64 is encoding, not encryption.** Anyone who can `get` the Secret, anyone with etcd access, and anyone who can create a Pod in the namespace can read every Secret in it<sup><a href="https://kubernetes.io/docs/concepts/configuration/secret/#information-security-for-secrets">[3]</a></sup>. The encoding exists so a Secret can carry arbitrary bytes (binary keys, certs) in a JSON field — not to hide anything. To author one without hand-encoding, write plaintext into `stringData`; the API server encodes it into `data` and drops `stringData` on read, so `kubectl get secret -o yaml` always shows base64 `data`.

<details>
<summary>📖 Going deeper: why "Secret" doesn't mean secret — and what actually protects it<sup><a href="https://kubernetes.io/docs/concepts/security/secrets-good-practices/">[4]</a></sup></summary>

The name oversells it. Out of the box a Secret is just base64 in etcd; confidentiality comes from three things layered on top, none on by default in a vanilla cluster<sup><a href="https://kubernetes.io/docs/concepts/configuration/secret/#information-security-for-secrets">[3]</a></sup>:

1. **Encryption at rest.** An `EncryptionConfiguration` on the API server encrypts Secret values before they hit etcd, ideally via a KMS<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/">[5]</a></sup>. Without it, an etcd backup is every credential in the clear.
2. **RBAC least privilege.** `get`/`list` on Secrets is the access boundary — with a subtle hole: *anyone who can create a Pod in a namespace can mount any Secret in it and read it*. Namespace boundaries are part of your Secret blast radius, not just `get secret` rules (RBAC → M10).
3. **An external store.** At scale, don't keep long-lived Secrets in the cluster at all — sync them from Vault/cloud managers via the External Secrets Operator, or commit only encrypted material (sealed-secrets, sops) to Git. That's M11.

M03 is the mechanics; M10–M11 are where "secret" becomes true.

</details>

### Two ways in: environment variables vs mounted files

A container reads config exactly two ways, and the choice is architectural, not cosmetic.

**As environment variables.** `envFrom` injects every key of a ConfigMap or Secret as an env var; `env` with a `valueFrom` injects one named key<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/">[6]</a></sup>:

```yaml
envFrom:
  - configMapRef: { name: app-config }      # every key → an env var
env:
  - name: DB_PASSWORD                        # one key → one env var
    valueFrom:
      secretKeyRef: { name: database-creds, key: DB_PASSWORD }
```

Env vars are simple and universal — every language reads them — but they have two sharp edges. They're materialized once, at container start, and never change after (the next section). And `envFrom` silently skips any key that isn't a valid environment-variable name: a key like `app.properties` is legal in a ConfigMap but illegal as an env var (the dot), so it's dropped, the Pod starts fine, and the only trace is one `InvalidEnvironmentVariableNames` warning event.

**As mounted files.** A ConfigMap or Secret volume projects each key as a file in a directory — `/etc/app-config/LOG_LEVEL` containing `info`<sup><a href="https://kubernetes.io/docs/concepts/configuration/configmap/#using-configmaps">[1]</a></sup>. This suits whole config files and large values, keeps confidential bytes off the process environment, and — critically — tracks the source object when it changes. A **projected volume** combines a ConfigMap, a Secret, downward-API fields, and a ServiceAccount token into one directory<sup><a href="https://kubernetes.io/docs/concepts/storage/projected-volumes/">[7]</a></sup>; the short-lived ServiceAccount token every Pod carries is delivered this way.

The **downward API** is the third source worth naming: it exposes the Pod's own metadata — name, namespace, IP, node, resource requests/limits — as env vars or files, so a process can learn things about itself that aren't in any ConfigMap<sup><a href="https://kubernetes.io/docs/concepts/workloads/pods/downward-api/">[8]</a></sup>. A few fields (labels, annotations) are file-only, because they can change while env is frozen.

### The update problem: env is frozen, files drift, nothing rolls

This is the concept that pages people. **A ConfigMap or Secret edit does not restart anything** — no controller watches config objects to roll your Deployments. What happens next depends entirely on the consumption path:

- **Environment variables never update.** The value was baked into the container's environment at start. Editing the source ConfigMap changes the object in etcd and nothing else; the running process keeps the old value until its Pod is replaced<sup><a href="https://kubernetes.io/docs/concepts/configuration/configmap/#mounted-configmaps-are-updated-automatically">[9]</a></sup>.
- **Mounted files do update — eventually.** The kubelet refreshes mounted ConfigMaps/Secrets on its periodic sync; the change appears in the file after roughly the kubelet sync period (default ~1 minute) plus cache propagation<sup><a href="https://kubernetes.io/docs/concepts/configuration/configmap/#mounted-configmaps-are-updated-automatically">[9]</a></sup>. The application still has to *re-read* the file — many don't without a SIGHUP or a restart, so "the file updated" and "the app picked it up" are two different things.
- **`subPath` mounts are the trap.** Mounting a single key with `subPath` (to drop one file into an existing directory without hiding its other contents) opts you out of live updates entirely — that file is frozen like an env var<sup><a href="https://kubernetes.io/docs/concepts/configuration/configmap/#mounted-configmaps-are-updated-automatically">[9]</a></sup>.

So when you need a config change to take effect, you make it. The blunt instrument is `kubectl rollout restart deployment/<name>` — it rolls every Pod, which re-reads everything. The durable, GitOps-native one is a **config-hash annotation**: put a checksum of the ConfigMap/Secret into the Pod template's annotations, so changing the config changes the template hash and triggers a normal rolling update — the restart encoded in the manifest, auditable rather than hand-run<sup><a href="https://helm.sh/docs/howto/charts_tips_and_tricks/#automatically-roll-deployments">[10]</a></sup>.

<details>
<summary>📖 Going deeper: <code>immutable</code>, and making config changes safe by construction<sup><a href="https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable">[11]</a></sup></summary>

Setting `immutable: true` on a ConfigMap or Secret does two things (GA since Kubernetes v1.24)<sup><a href="https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable">[11]</a></sup>: it blocks all edits — you must delete and recreate to change the contents — and it lets the kubelet stop watching the object, which materially cuts API-server watch load in clusters with thousands of config objects.

The two benefits compose into a pattern. Name config objects by content — `app-config-7f3a9`, the suffix a hash of the data — mark them `immutable`, and reference the hashed name from the Pod template. Now "changing config" means *creating a new immutable object and updating the reference*, which is itself a Pod-template change, which rolls the Deployment. You get safety (nothing mutates a live config out from under a running Pod), an automatic rollout (the reference changed), and a clean rollback (the old object still exists). The "I edited the ConfigMap and nothing happened" footgun becomes structurally impossible — and it's exactly what Kustomize's and Helm's config generators do for you, garbage-collecting the old objects too.

</details>

### When config breaks the Pod: the start-up differential

When a config reference is wrong, the failure shape tells you which path broke — the same read-the-status-and-events discipline from M00, applied to configuration. Three shapes cover almost everything:

- **`CreateContainerConfigError`** — the kubelet scheduled the Pod and tried to *create the container*, but couldn't assemble its environment: a required `env`/`envFrom` reference points at a ConfigMap/Secret that doesn't exist, or a key that isn't in it. The describe event is explicit: `Error: couldn't find key MAX_CONNECTIONS in ConfigMap media/app-config`<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/">[6]</a></sup>. This is an *environment-injection* failure — the Pod got far enough to attempt container creation.
- **Stuck `ContainerCreating`, `FailedMount` event** — the Pod references a Secret/ConfigMap as a *volume* that doesn't exist. Volume setup is a precondition to container creation, so the container is never even attempted; the Pod sits in `ContainerCreating` while the kubelet retries the mount and emits `MountVolume.SetUp failed for volume … secret "portal-secrets" not found`. Same root cause as the first shape — a missing referenced object — but a different lifecycle phase, so a different status and a different event to look for.
- **`Running`, but wrong** — no error at all. The reference resolved, the value was injected, the Pod is `Ready` — and the value is wrong: a Secret base64-encoded twice that decodes to a still-encoded string, or a stale env after an un-rolled config edit. This is configuration's instance of a theme that recurs at every layer — the headline status is green and the system is still wrong (M01's `Running` ≠ `Ready`, M01b's `Complete` ≠ correct). You find it not in the status but by reading the value the container actually got: `kubectl exec … -- printenv` or `cat` the mounted file.

The escape hatch for the first two is `optional: true` on the reference — a missing object or key is then skipped and the Pod starts<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/">[6]</a></sup>. Use it where the app has a sane fallback; avoid it where you'd rather fail loudly than start on an empty value, because `optional` converts a `CreateContainerConfigError` you'd notice into a silent missing value you might not.

## Hands-on

Four steps in the baseline, four break/fix scenarios — all on the full Polyphone fleet, configured the way real workloads are: `session-broker` (`media`) reads an `app-config` ConfigMap both as env vars and as mounted files; `account-provisioner` (`provisioning`) takes its `database-creds` Secret as env; `portal-ui` (`admin-portal`) mounts a Secret as files.

- **`baseline/`** — ConfigMaps and Secrets across the fleet, the two consumption modes read out of running containers, mounted files vs env, and a Secret decoded to show base64 isn't security. What healthy config wiring looks like.
- **`breakfix-01-configmap-key-missing/`** — a Pod in `CreateContainerConfigError`. Tests reading the config-key failure: a required `env` reference to a key the ConfigMap doesn't have.
- **`breakfix-02-secret-volume-missing/`** — a Pod stuck in `ContainerCreating`. Tests recognizing a `FailedMount` for a Secret that was never created — a different failure surface from the env case.
- **`breakfix-03-stale-env-config/`** — a ConfigMap was updated but the workload still serves the old value. Tests the propagation gap: env is frozen, and a config edit rolls nothing until you make it.
- **`breakfix-04-secret-double-base64/`** — a Pod `Running` and `Ready` on a wrong credential. Tests finding a green-but-wrong config by reading the value the container actually got, and the base64 boundary that produced it.

Check yourself against `ANSWER-KEY.md` after each.

## Common failure modes

| Symptom | Likely cause | Where to look |
|---------|--------------|---------------|
| `CreateContainerConfigError` | Required `env`/`envFrom` ref to a missing ConfigMap/Secret or a missing key | `kubectl describe pod` events (`couldn't find key …`); the container's `env`/`envFrom`; does the key exist in the object |
| Stuck `ContainerCreating` (no logs) | Volume mount of a Secret/ConfigMap that doesn't exist | `describe pod` events (`FailedMount … not found`); the Pod's volumes; `kubectl get secret/configmap -n <ns>` |
| Edited a ConfigMap/Secret, nothing changed | Env consumers are frozen; nothing rolls on a config edit | Is it consumed as env or as a file; did the Pods restart; `rollout restart` or a hash-annotation |
| Mounted file still stale after minutes | `subPath` mount (no live update), or app never re-read the file | The volumeMount's `subPath`; whether the app reloads config without a restart |
| `Running` but behaving on wrong value | Double-base64'd Secret, wrong key, or stale env | `kubectl exec … -- printenv` / `cat` the file; decode the Secret with `base64 -d` and compare |
| `envFrom` key silently absent | A ConfigMap key that isn't a valid env-var name (e.g. has a `.` or `-`) was skipped | `describe pod` for an `InvalidEnvironmentVariableNames` warning; use a volume mount or rename the key |

## Recap

- Configuration is separated from the image and delivered at runtime by ConfigMaps (non-confidential) and Secrets (confidential, base64-in-etcd). **Base64 is encoding, not encryption** — RBAC, encryption-at-rest, and external stores are what actually protect a Secret.
- A container consumes config two ways — **environment variables or mounted files** — and the choice is load-bearing: it determines both how a bad reference fails and whether a later edit ever reaches the process.
- **Env vars are frozen at container start; mounted files update with the source (after ~the kubelet sync period), except `subPath`.** A config edit restarts nothing on its own — force it with `rollout restart` or, GitOps-natively, a config-hash annotation (and `immutable` makes change-by-recreate the only path).
- **The config-failure differential:** `CreateContainerConfigError` = a missing env key/object; stuck `ContainerCreating` + `FailedMount` = a missing mounted object; `Running`-but-wrong = a value that resolved but is incorrect. Status and events name the first two; only reading the injected value catches the third.
- A green Pod can still hold the wrong config. `Running` ≠ correct — the same "the headline status lies" instinct from `Running` ≠ `Ready` and `Complete` ≠ correct, now pointed at the values inside the container.

## Production thinking

- A credential rotates and you update the Secret, but the workloads consume it as env vars. Nothing changes — running Pods hold the old value, and they'll keep authenticating with it until something restarts them. How do you make a Secret rotation actually reach every consumer, and how would you detect the ones still running on the stale value?
- Your team is split: one service reads config from env vars, another from a mounted file, and only the file-based one picks up edits live. What's your standard — do you mandate one consumption mode, lean on `rollout restart` everywhere, or adopt hashed-immutable config objects so every change rolls by construction? What does each choice cost the release process?
- A developer base64-encodes a password by hand, gets it wrong, and ships a Pod that's `Running` and `Ready` on a broken credential — no alert fires, because nothing crashed. What in your pipeline or your manifests would have caught a green-but-wrong config before it reached prod?

## References

1. Kubernetes — ConfigMaps: https://kubernetes.io/docs/concepts/configuration/configmap/
2. Kubernetes — Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
3. Kubernetes — Information security for Secrets: https://kubernetes.io/docs/concepts/configuration/secret/#information-security-for-secrets
4. Kubernetes — Good practices for Kubernetes Secrets: https://kubernetes.io/docs/concepts/security/secrets-good-practices/
5. Kubernetes — Encrypting Confidential Data at Rest: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
6. Kubernetes — Configure a Pod to Use a ConfigMap: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
7. Kubernetes — Projected Volumes: https://kubernetes.io/docs/concepts/storage/projected-volumes/
8. Kubernetes — Downward API: https://kubernetes.io/docs/concepts/workloads/pods/downward-api/
9. Kubernetes — Mounted ConfigMaps are updated automatically: https://kubernetes.io/docs/concepts/configuration/configmap/#mounted-configmaps-are-updated-automatically
10. Helm — Automatically Roll Deployments (config-hash annotation): https://helm.sh/docs/howto/charts_tips_and_tricks/#automatically-roll-deployments
11. Kubernetes — Immutable ConfigMaps: https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable

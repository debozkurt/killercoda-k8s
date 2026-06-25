# M03 — Baseline Tour

The same image runs in every environment; what changes between them is *configuration* — log levels, hostnames, feature flags, credentials. Kubernetes keeps that out of the image, in **ConfigMaps** (non-confidential) and **Secrets** (confidential), and injects it into containers at start. M02 was about getting the image onto the node; M03 is about handing the process its settings.

This tour runs on the full Polyphone fleet, configured the way real workloads are:

- **`session-broker`** (`media`) reads an `app-config` ConfigMap **both ways** — as environment variables *and* as files mounted at `/etc/app-config`.
- **`account-provisioner`** (`provisioning`) takes its `database-creds` Secret as environment variables.
- **`portal-ui`** (`admin-portal`) mounts a `portal-secrets` Secret as files at `/etc/portal`.

Four short steps:

1. **ConfigMaps and Secrets on the fleet** — what config objects exist and who consumes them
2. **Config as environment variables** — read the injected env out of a running container
3. **Config as mounted files** — the other consumption mode, and how it differs on updates
4. **Secrets aren't secret** — decode a Secret and see that base64 is encoding, not security

Nothing to fix here. See what healthy config wiring looks like before the break/fix scenarios walk the four ways it breaks. The cluster takes 90–150 seconds to come up. Click **Start** when ready.

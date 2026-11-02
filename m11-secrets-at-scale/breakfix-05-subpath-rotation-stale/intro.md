# M11 — Break/fix 05: subPath Rotation Stale

> The healthy pipeline from the baseline, after a token rotation. Work breakfix-03 first.

The partner API token was rotated in the store. The operator synced it, and every `SecretSync` reads `Synced`. The partner reports that `partner-connector` in `media` still presents the old token.

In breakfix-03 the consumer read an environment variable, which never changes after container start. This consumer reads its token from a file in a Secret volume. The Kubernetes docs say a Secret volume receives updates. So why does this file not change?

Your job: find where the old value lives, explain why the update never reached it, and change the consumer so that the next rotation lands without a restart.

The cluster takes 90–150 seconds to come up. Click **Start** when ready.

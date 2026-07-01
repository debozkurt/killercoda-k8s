# M09 — Break/fix 03: Stuck Rollout

> Pre-req: the baseline tour. You saw a rolling update complete cleanly and `rollout undo` rewind one. This is a rollout that won't complete.

Someone shipped a new `portal-web` release to `admin-portal` a while ago, and the deploy pipeline is still waiting on it — `kubectl rollout status` never returns. The odd part: users aren't complaining. The admin UI is up and serving. But the new version isn't taking, and the rollout is stuck in limbo.

This is the good news and the bad news of a rolling update. The Deployment is *careful* — it won't tear down the old version until the new one is healthy, so a broken release doesn't take the service down. But it also won't give up on its own timeline, so the rollout just sits there, half-done, until someone intervenes.

Your job: read what state the rollout is wedged in, find why the new Pods won't come up, and get the Deployment back to a fully rolled-out, healthy state.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.

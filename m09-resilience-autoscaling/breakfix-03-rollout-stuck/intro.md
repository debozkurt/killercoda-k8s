# M09 — Break/fix 03: Stuck Rollout

> Pre-req: the baseline tour. You saw a rolling update finish and `rollout undo` rewind one. This rollout does not finish.

A new `portal-web` release shipped to `admin-portal` a while ago, and the deploy pipeline still waits on it. `kubectl rollout status` never returns. Users do not complain, because the admin UI is up and serving. The new version has not landed.

A rolling update is careful. It keeps the old version serving until the new one is Ready, so a broken release does not take the service down. It also does not give up, so the rollout sits half-done until someone acts.

Your job: read the state the rollout is stuck in, find why the new Pods will not start, and return the Deployment to a healthy, fully rolled-out state.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.

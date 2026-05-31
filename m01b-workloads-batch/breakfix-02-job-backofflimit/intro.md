# M01b — Break/fix 02: Job Stuck Retrying

> Pre-req: the M01b baseline tour, or comfort with `kubectl get jobs`, `kubectl logs job/<name>`, and the idea of `backoffLimit`.

A release is blocked. The pre-deploy **schema migration won't complete.** `schema-migrate` in `provisioning` is a one-shot Job that should run once and exit clean — but it isn't, and the pipeline is waiting on it.

Unlike a Deployment, a Job has a *give-up* condition. It will retry a failing pod up to `backoffLimit` times and then mark itself `Failed` — permanently, no more attempts. So two very different states can look similar at a glance: a Job still **retrying** (more attempts coming) and a Job that has **given up** (done, failed, inert). Telling them apart, and finding *why* every attempt fails, is the skill.

There's a second trap waiting at the fix: a Job's pod template is immutable. You can't patch the command and roll it like a Deployment. Knowing that changes how you fix it.

The cluster takes 60–120 seconds to come up; the Job needs a few more seconds to start failing and retrying. Click **Start** when ready.

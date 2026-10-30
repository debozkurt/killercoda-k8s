# M09 — Break/fix 05: SIGTERM Ignored

> Pre-req: the baseline tour, step 5. You saw the termination sequence on a Pod that exits at once. This Pod does not.

After each deploy of `announce-player` in `media`, the old Pods linger in `Terminating`. Last night's node drain crawled through the same Pods, one every 45 seconds. Nothing errors, no Pod crashes, and every alert is green. The change is slow, not broken.

Termination is a budget of time. A well-behaved container uses a fraction of it. Something about this container uses all of it.

Your job: measure how long a Pod takes to leave, find what the container does with the stop signal, and make it exit when asked.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.

# M15 — Break/fix 05: Fault Injection Left On

> Pre-req: the M15 baseline tour.

**Alert:** the error rate for calls to `session-broker` is about 50%.

The other half of the calls succeed. Every `media` pod is 2/2 and `Ready`, and none restarted. The `session-broker` team reports that their nginx logs show no errors. Last week the resilience team ran a test against `media`.

Your job: find what answers the failed calls, and bring the error rate to zero.

The cluster takes 3 to 5 minutes to start. Click **Start** when ready.

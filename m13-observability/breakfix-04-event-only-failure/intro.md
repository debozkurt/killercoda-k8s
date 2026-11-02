# M13 — Break/fix 04: a workload with no logs

> Pre-req: the M13 baseline tour. You read the event stream with `kubectl events`. Here events are the only signal that exists.

A release finished and a workload that loads call rates never came up. The on-call engineer knows only that it is somewhere in the cluster. They ran `kubectl get events` in the default namespace and it found nothing. They ran `kubectl logs` on the Pod and it failed. There is no application log, because the application never started.

Your job: find the failing Pod without knowing its namespace, read the event that names the cause, and fix it so the workload starts.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.

# M01 — Break/fix 02: Readiness Traffic Blackhole

> Pre-req: breakfix-01, or comfort with the idea that readiness gates traffic while liveness gates restarts.

An alert fires: **callers of the `directory` service in `app-services` are getting connection errors.** The address-book lookups every call depends on are failing. But when you glance at the pods, they're `Running` — and unlike the last incident, nothing is restarting.

This is the quieter, more confusing failure. Nothing crashes. Nothing loops. The pods look alive by the headline metric, yet no traffic reaches them. The cause is one probe doing exactly what it's designed to do — to a Pod that shouldn't have failed it.

Your job: find why a `Running` Pod is receiving no traffic, and fix it. The skill is understanding what readiness actually controls — and that "Running" and "Ready" are not the same thing.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.

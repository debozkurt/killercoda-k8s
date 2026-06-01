# M02 — Break/fix 04: Digest Mismatch

> Pre-req: the M02 baseline tour (tags vs digests) and breakfix-02/03 (reading the event to classify a pull failure).

`directory` in `app-services` won't start — the contacts/address-book service is down. `ImagePullBackOff` again, the fourth time you've seen that status in this module. By now the reflex is automatic: read the event message, don't trust the status.

This one is the last branch of the differential, and the subtlest. The registry is reachable (no `no such host`), the pull is authenticated (no `401`) — but the reference resolves to **nothing**. The workload is pinned by digest, and the digest names a manifest that doesn't exist in the registry. The kubelet asks for those exact bytes, the registry says `manifest unknown`, and the pull fails **closed**.

That fail-closed behavior is the point: a wrong digest can never silently run the wrong image — it refuses to run at all. Your job: recognize `manifest unknown` as a bad-reference failure (not auth, not reachability), and re-pin to a digest that exists. `crane` is installed to help you find the right one. The cluster takes 60–120 seconds to come up. Click **Start** when ready.

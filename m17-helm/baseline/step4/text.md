# Step 4 — History and rollback

Every install, upgrade and rollback adds one **revision**. Helm keeps old revisions, and that history makes a rollback possible.

## Walk the history

```bash
helm history voicemail -n app-services
```{{exec}}

Two rows. Revision 1 reads `superseded`, `Install complete`. Revision 2 reads `deployed`, `Upgrade complete`.

## Roll back

```bash
helm rollback voicemail 1 -n app-services
helm history voicemail -n app-services
```{{exec}}

A rollback re-applies revision 1's manifest as a **new** revision. Revision 3 reads `deployed`, `Rollback to 1`, and revision 2 stays in the history.

```bash
kubectl get deployment voicemail -n app-services
```{{exec}}

`READY` returns to 2/2.

## Where the history lives

```bash
kubectl get secret -n app-services -l owner=helm --show-labels
```{{exec}}

One Secret per revision: `sh.helm.release.v1.voicemail.v1` to `.v3`. The `status=` label on each one mirrors the `STATUS` column of `helm history`. The record is in the cluster, so every machine with access sees the same history.

# M06 — Break/fix 05: Node Affinity Mismatch

> Pre-req: breakfix-01 through 04. You have read three `FailedScheduling` reasons and one runtime kill. This is the last branch of the `Pending` differential.

The media team copied a new workload, `conference-mixer`, from another region's manifests and rolled it out to the `media` namespace. It mixes audio for conference calls, so the team pinned it to fast-disk nodes. Its Pod is stuck `Pending`.

No node is short of CPU or memory. No new taint is in the way. The worker runs other media workloads that ask for fast disks, and they are healthy.

Your job: read the `FailedScheduling` event, compare what the Pod asks for with what the nodes carry, and fix the side that is wrong.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.

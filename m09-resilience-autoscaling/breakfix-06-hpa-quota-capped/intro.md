# M09 — Break/fix 06: HPA Capped by Quota

> Pre-req: breakfix-02. There, the HPA could not read its metric. Here it reads fine and still does not deliver.

`caption-engine` in `captions` has an HPA with a minimum of 4 replicas. Traffic is rising, and the service runs on 2 Pods. The HPA reads a real percentage, its conditions are green, and it reports 4 as the desired count.

A desired count is a request. Between the HPA and a serving Pod sit the ReplicaSet, admission, the scheduler, and a node. One of those links refuses the Pods.

Your job: walk down that chain from the HPA until you find the link that says no, then remove the cap.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.

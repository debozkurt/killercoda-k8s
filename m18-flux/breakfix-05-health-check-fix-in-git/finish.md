# Done

The health stage failed, and the fix had to go through git. The release commit set an image tag that the registry does not have. Flux applied it, the new Pods sat in `ImagePullBackOff`, and the health check timed out with `HealthCheckFailed`. A hand fix with `kubectl set image` lasted until the next pass, because the git manifest declares the image. A revert commit changed the desired state, and the applied revision then matched the fix commit.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) covers when to suspend instead, and how to keep a bad tag out of git.
- [LESSON.md](../LESSON.md) covers drift correction and server-side apply ownership.
- **M18 is complete.** Next on the GitOps track: **M19 Multi-cluster**, where one repo renders a different state for each cluster.

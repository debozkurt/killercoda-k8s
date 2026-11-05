# Done

The 503s carried the flag `FI` in the caller's access log, and the server's log held only 200s. The caller's sidecar answered the failed requests itself, from a `fault.abort` at 50% that a resilience test left in the VirtualService. Removing the block brought the error rate to zero.

The reflex: **when the server logs no errors, check whether the request left the caller. The response flag tells you.** A fault injection is ordinary route configuration, so give each test fault an owner and a removal step.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- You have completed M15's five scenarios: five causes, one 503 or one reset, and the access log names each one.

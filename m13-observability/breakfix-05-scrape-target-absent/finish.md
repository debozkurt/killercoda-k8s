# Done

The dashboards were flat, the app was healthy and its scrape port was correct. The Service's selector read `app=call-metric`, one letter short of the Pod's label. The Service had no endpoints, so a service-based scraper found no target. The target was **absent**, not DOWN: Prometheus recorded no `up` series, so an alert on `up == 0` stayed silent. Correcting the selector filled the endpoints.

The reflex: **flat dashboards with a correct port mean check the Service endpoints.** A DOWN target has an address that fails. An absent target has no address. Compare the Service selector with the Pod labels with `describe service` and `--show-labels`. Alert on a missing target with an absence check, not only on `up == 0`.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § Metrics.
- That is all five break/fix scenarios. Re-read [`LESSON.md`](../LESSON.md) for the full mental model, including where traces fit.

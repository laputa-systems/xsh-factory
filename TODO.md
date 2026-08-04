# Factory TODOs

- [ ] Evaluate provider switching or fallback based on provider-health telemetry
  (429/5xx/retry events, request latency, time to first token, and observed
  generation rate). This is intentionally out of scope for the next cycle;
  collect and report health evidence first without changing the configured
  provider or model.

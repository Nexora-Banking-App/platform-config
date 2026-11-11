# TargetDown

Severity: `warning`

## What it means

Prometheus has failed to scrape a target for 5 minutes.

## Impact

No direct customer impact, but alerts and canary analysis that depend on that target's metrics are blind.

## First three checks

1. Prometheus UI: Status > Targets, read the scrape error for the target
2. `kubectl -n <namespace> get pod <pod> -o wide`
3. `kubectl -n nexora get networkpolicy allow-prometheus-scrape -o yaml   # for nexora pods`

## Mitigation

A `context deadline exceeded` on nexora pods points to a NetworkPolicy or sidecar problem (Prometheus scrapes :15020 on injected pods, :8000 otherwise). A `connection refused` means the app is not listening: treat as a pod problem.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

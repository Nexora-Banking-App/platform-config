# HighFraudServiceCPU

Severity: `warning`

## What it means

A `fraud-service` pod has used more than 80% of its CPU limit (500m) for 5 minutes.

## Impact

No direct customer impact yet. Sustained throttling slows `/api/scan`, which slows every transfer (transaction-service waits up to 2s for it).

## First three checks

1. `kubectl -n nexora get hpa fraud-service-hpa`
2. `kubectl -n nexora top pods -l app=fraud-service --containers`
3. PromQL: `sum by (pod) (rate(container_cpu_cfs_throttled_periods_total{namespace="nexora", container="fraud-service"}[5m])) / sum by (pod) (rate(container_cpu_cfs_periods_total{namespace="nexora", container="fraud-service"}[5m]))`

## Mitigation

Normally none: the HPA (target 50%, max 5) adds replicas. If the HPA is already at max, see `HPAAtMaxReplicas`. If the HPA shows `<unknown>` targets, check metrics-server.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

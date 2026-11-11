# HPAAtMaxReplicas

Severity: `warning`

## What it means

An HPA in `nexora` has been at its maximum replica count for 15 minutes (today only `fraud-service-hpa`, max 5).

## Impact

The service cannot scale further. Extra load will show up as CPU throttling and latency.

## First three checks

1. `kubectl -n nexora describe hpa fraud-service-hpa`
2. `kubectl -n nexora top pods -l app=fraud-service`
3. PromQL: `sum(rate(http_requests_total{namespace="nexora", app="fraud-service", handler="/api/scan"}[5m]))` to see whether load is real

## Mitigation

If the load is legitimate, raise `maxReplicas` in `app-manifests/base/fraud-service.yaml` and check the nodes have room (`kubectl describe nodes | grep -A5 Allocated`). If it is a load test, no action.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

# HighHTTPLatencyP99

Severity: `warning`

## What it means

A service's p99 request latency has been above 1 second for 10 minutes. The histogram has no handler label, so probes and `/metrics` scrapes are included.

## Impact

Slow pages and transfers. api-gateway times out upstream calls at 10s; transaction-service times out the fraud check at 2s.

## First three checks

1. PromQL: `histogram_quantile(0.99, sum by (app, le) (rate(http_request_duration_highr_seconds_bucket{namespace="nexora"}[5m])))` to see which services are slow
2. `kubectl -n nexora top pods --containers   # CPU close to limit means throttling`
3. PromQL: `sum by (app, handler) (rate(http_request_duration_seconds_sum{namespace="nexora"}[5m])) / sum by (app, handler) (rate(http_request_duration_seconds_count{namespace="nexora"}[5m]))` for mean latency per handler

## Mitigation

If fraud-service is the slow one, check its HPA. If transaction-service is slow with low CPU, suspect row-lock queues or the DB connection pool (20 per pod) and check RDS CPU and connections.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

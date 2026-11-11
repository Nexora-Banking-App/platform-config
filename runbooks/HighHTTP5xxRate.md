# HighHTTP5xxRate

Severity: `critical`

## What it means

More than 10% of a service's requests (health and metrics endpoints excluded) returned 5xx for 5 minutes.

## Impact

Customers see failed logins, balance lookups or transfers, depending on the `app` label.

## First three checks

1. PromQL: `sum by (app, handler) (rate(http_requests_total{namespace="nexora", status="5xx"}[5m]))` to find the failing handler
2. `kubectl -n nexora logs -l app=<app> -c <app> --tail=200 | grep -iE 'error|exception|traceback'`
3. `kubectl -n nexora get pods -l app=<app> -o wide   # restarts, readiness, recent rollout`

## Mitigation

If it started with a deploy, revert the image tag PR in `app-manifests` (for api-gateway: `kubectl argo rollouts abort api-gateway -n nexora`). If readiness reports the database is unready, check RDS and the `db-secret` ExternalSecret. A 502/504 from api-gateway means the upstream service is the real problem.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

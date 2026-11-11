# TransferErrorBudgetFastBurn

Severity: `critical`

## What it means

The `/transfer` 5xx ratio is above 1.44% over both the last hour and the last 5 minutes. At that rate a 99.9% monthly error budget is gone in about two days.

## Impact

Customers cannot move money. This is the most important alert on the platform.

## First three checks

1. PromQL: `sli:transfer_errors:ratio_rate5m` and `sum by (status) (rate(http_requests_total{namespace="nexora", app="transaction-service", handler="/transfer"}[5m]))`
2. `kubectl -n nexora logs -l app=transaction-service -c transaction-service --tail=200`
3. `kubectl -n nexora get pods -l 'app in (transaction-service, fraud-service)' -o wide`

## Mitigation

A 503 `Fraud engine unreachable` means fixing fraud-service first. A 500 with a database error means checking RDS and the connection pool. If it started with a deploy, revert the image tag PR in `app-manifests`.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

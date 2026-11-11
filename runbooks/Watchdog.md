# Watchdog

Severity: `none`

## What it means

This alert always fires. It is routed to the `null` receiver and sends nothing.

## Impact

None while it fires. If it is missing from Alertmanager, Prometheus is not evaluating rules or cannot reach Alertmanager, and no other alert will arrive either.

## First three checks

1. Alertmanager UI: is `Watchdog` listed?
2. `kubectl -n monitoring get pods`
3. `kubectl -n monitoring logs deploy/prometheus-server -c prometheus-server --tail=50`

## Mitigation

Restore Prometheus or Alertmanager. Nothing external watches this alert yet; adding a dead-man's-switch receiver is an open item.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

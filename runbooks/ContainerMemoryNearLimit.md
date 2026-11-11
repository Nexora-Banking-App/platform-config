# ContainerMemoryNearLimit

Severity: `warning`

## What it means

An app container has used more than 85% of its memory limit for 10 minutes.

## Impact

None yet. The next step is an OOM kill.

## First three checks

1. PromQL: `container_memory_working_set_bytes{namespace="nexora", pod="<pod>", container="<container>"}` over 6h: flat or growing?
2. `kubectl -n nexora top pod <pod> --containers`
3. `kubectl -n nexora get pod <pod> -o jsonpath='{.spec.containers[*].resources}'`

## Mitigation

If usage is flat, the limit is simply too tight: raise it in `app-manifests`. If it grows without bound, restart the workload and investigate the leak.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

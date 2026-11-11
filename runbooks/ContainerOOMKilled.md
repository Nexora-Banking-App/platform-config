# ContainerOOMKilled

Severity: `warning`

## What it means

The last termination of a container in `nexora` was an OOM kill. The alert stays active until the container terminates for another reason or the pod is replaced.

## Impact

In-flight requests on that pod were dropped. A transfer interrupted mid-flight is retried safely through its idempotency key.

## First three checks

1. `kubectl -n nexora describe pod <pod> | grep -A6 'Last State'`
2. PromQL: `max_over_time(container_memory_working_set_bytes{namespace="nexora", pod="<pod>", container="<container>"}[1h])`
3. `kubectl -n nexora get pod <pod> -o jsonpath='{.spec.containers[*].resources.limits.memory}'`

## Mitigation

Raise the memory limit for that service in `app-manifests` (base is 128Mi; the staging Kafka patches already use 256Mi). If memory grows steadily, it is a leak: restart with `kubectl -n nexora rollout restart deploy/<app>` and open a bug.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

# PodCrashLooping

Severity: `warning`

## What it means

A container in `nexora` has restarted repeatedly for at least 15 minutes.

## Impact

Reduced capacity for that service; a full outage if every replica is affected.

## First three checks

1. `kubectl -n nexora get pods --sort-by='.status.containerStatuses[0].restartCount'`
2. `kubectl -n nexora describe pod <pod>   # Last State, exit code, events`
3. `kubectl -n nexora logs <pod> -c <container> --previous --tail=100`

## Mitigation

Exit code 137 means OOM (see `ContainerOOMKilled`). A missing secret or env var means checking the ExternalSecrets (`kubectl -n nexora get externalsecret`). If it started with a deploy, revert the image tag PR in `app-manifests`.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

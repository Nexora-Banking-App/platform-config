# PersistentVolumeFillingUp

Severity: `warning`

## What it means

A PersistentVolumeClaim has less than 15% free space.

## Impact

When it fills: Prometheus stops ingesting, Alertmanager loses silences, Kafka brokers stop accepting writes.

## First three checks

1. `kubectl get pvc -A`
2. PromQL: `kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes` by `persistentvolumeclaim`
3. PromQL: `predict_linear(kubelet_volume_stats_available_bytes[6h], 24*3600) < 0` to see if it fills within a day

## Mitigation

The `ebs-gp3` StorageClass does not set `allowVolumeExpansion`, so the PVC cannot simply be resized. For Prometheus, lower `server.retention` in the chart values. For Kafka, lower `retention.ms` on the topic. Growing a volume needs a StorageClass change first.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

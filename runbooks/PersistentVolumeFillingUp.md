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

First reduce what is stored: for Prometheus lower `server.retention` in the chart values, for Loki lower `retention_period`, for Kafka lower `retention.ms` on the topic. If the data is needed, grow the volume: the `ebs-gp3` StorageClass allows expansion, so raise the size where the PVC is declared in Git (chart values or the Kafka node pool) and let ArgoCD apply it. Volumes can grow but never shrink.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

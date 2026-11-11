# NodeNotReady

Severity: `critical`

## What it means

A node has not reported Ready for 5 minutes.

## Impact

Pods on that node are unreachable or being evicted. Staging has two nodes, so half the capacity may be gone. Warning and critical alerts carrying the same `node` label are inhibited while this fires.

## First three checks

1. `kubectl get nodes -o wide`
2. `kubectl describe node <node> | sed -n '/Conditions/,/Addresses/p'`
3. `kubectl get pods -A -o wide --field-selector spec.nodeName=<node>`

## Mitigation

Check the EC2 instance status in the AWS console. The managed node group replaces failed instances; if the node stays NotReady, cordon and drain it (`kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`) and terminate the instance so the group replaces it. Kafka brokers on that node keep their EBS volumes.

## Escalation

Platform team (email receiver `email-alerts`). If customers are affected for more than 30 minutes, pause deploys to `app-manifests` and treat it as an incident.

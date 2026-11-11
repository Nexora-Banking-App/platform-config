## What changed and why

<!-- One or two sentences. Link the issue or incident if there is one. -->

## How it was checked

- [ ] `kustomize build --enable-helm` succeeds for every changed kustomization
- [ ] Alert rules changed? `promtool check rules` passes, each new alert has a runbook, and `scripts/sync-prod-rules.py` was run
- [ ] Dashboards are valid JSON and reference datasources by uid
- [ ] No secret values in the diff (secrets come from External Secrets)

## Risk and rollback

<!-- What could break, and how to undo it (usually: revert this PR). -->

#!/usr/bin/env python3
"""Keep the prod PrometheusRule in sync with the staging rules.

Staging runs the plain Prometheus chart, where alert and recording rules live
in the chart values (platform-manifests/prometheus/kustomization.yaml).
Prod runs kube-prometheus-stack, where rules are PrometheusRule resources.
The staging file is the single source of truth; this script copies its rule
groups into the prod PrometheusRule so the two can never drift.

Usage:
  scripts/sync-prod-rules.py           # rewrite the prod file
  scripts/sync-prod-rules.py --check   # exit 1 if the prod file is out of date (CI)

Needs PyYAML (pip install pyyaml).
"""
import pathlib
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "platform-manifests/prometheus/kustomization.yaml"
TARGET = ROOT / "platform-manifests-prod/monitoring-config/prometheus-rules.yaml"

HEADER = (
    "# GENERATED FILE - do not edit by hand.\n"
    "# Source: platform-manifests/prometheus/kustomization.yaml (serverFiles)\n"
    "# Regenerate with: scripts/sync-prod-rules.py\n"
)


class _Dumper(yaml.SafeDumper):
    """Writes multi-line strings (PromQL) as readable block scalars."""


def _str_presenter(dumper, data):
    if "\n" in data:
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
    return dumper.represent_scalar("tag:yaml.org,2002:str", data)


_Dumper.add_representer(str, _str_presenter)


def render() -> str:
    kustomization = yaml.safe_load(SOURCE.read_text())
    chart = next(c for c in kustomization["helmCharts"] if c["name"] == "prometheus")
    server_files = chart["valuesInline"]["serverFiles"]
    groups = []
    for key in ("alerting_rules.yml", "recording_rules.yml"):
        groups.extend(server_files.get(key, {}).get("groups", []))

    rule = {
        "apiVersion": "monitoring.coreos.com/v1",
        "kind": "PrometheusRule",
        "metadata": {
            "name": "nexora-rules",
            "namespace": "monitoring",
            "labels": {"app.kubernetes.io/part-of": "nexora"},
        },
        "spec": {"groups": groups},
    }
    return HEADER + yaml.dump(rule, Dumper=_Dumper, sort_keys=False, width=4096)


def main() -> int:
    wanted = render()
    if "--check" in sys.argv:
        current = TARGET.read_text() if TARGET.exists() else ""
        if current != wanted:
            print(f"{TARGET.relative_to(ROOT)} is out of date. Run scripts/sync-prod-rules.py")
            return 1
        print("prod PrometheusRule is in sync with the staging rules")
        return 0
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(wanted)
    print(f"wrote {TARGET.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

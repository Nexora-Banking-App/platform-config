#!/usr/bin/env bash
# Opens every operator dashboard of the Nexora platform through kubectl
# port-forward tunnels. Nothing is exposed publicly: access is whatever your
# current kubectl context (AWS IAM access entry) allows.
#
# Usage:
#   ./scripts/open-dashboards.sh            # start tunnels and open browser tabs
#   ./scripts/open-dashboards.sh --no-open  # start tunnels only, print the URLs
#
# Works on both cluster layouts:
#   staging - prometheus chart + grafana chart
#   prod    - kube-prometheus-stack + grafana-operator
# For each dashboard the first Service that exists is used; missing ones are skipped.
#
# Loki and Tempo have no UI of their own: use Grafana (Explore, or the
# "Nexora" dashboard folder) to query logs and traces.
set -uo pipefail

OPEN_BROWSER=true
[ "${1:-}" = "--no-open" ] && OPEN_BROWSER=false

PIDS=()
URLS=()

cleanup() {
  echo ""
  echo "Closing tunnels..."
  for pid in "${PIDS[@]:-}"; do
    [ -n "$pid" ] && kill "$pid" 2>/dev/null
  done
}
trap cleanup EXIT INT TERM

# forward <label> <local-port> <scheme> <note> <namespace/service:port> [more candidates...]
forward() {
  local label="$1" local_port="$2" scheme="$3" note="$4"
  shift 4
  local candidate namespace service remote_port
  for candidate in "$@"; do
    namespace="${candidate%%/*}"
    service="${candidate#*/}"
    remote_port="${service##*:}"
    service="${service%%:*}"
    if kubectl get svc "$service" -n "$namespace" >/dev/null 2>&1; then
      kubectl port-forward "svc/$service" -n "$namespace" "$local_port:$remote_port" >/dev/null 2>&1 &
      PIDS+=("$!")
      URLS+=("$scheme://localhost:$local_port")
      printf '  %-14s %-28s %s\n' "$label" "$scheme://localhost:$local_port" "$note"
      return 0
    fi
  done
  printf '  %-14s %-28s %s\n' "$label" "(not installed)" ""
  return 0
}

echo "======================================================="
echo "   NEXORA PLATFORM - OPERATOR DASHBOARDS"
echo "======================================================="

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "kubectl cannot reach a cluster. Check your context:"
  echo "  aws eks update-kubeconfig --name nexora-staging --region us-east-1"
  exit 1
fi
echo "Cluster: $(kubectl config current-context)"
echo ""

forward "ArgoCD"       8081 https "user: admin" \
  "argocd/argocd-server:443"
forward "Grafana"      3000 http  "user: admin (dashboards, logs, traces)" \
  "monitoring/grafana:80" "monitoring/grafana-service:3000"
forward "Prometheus"   9090 http  "targets, rules, ad-hoc queries" \
  "monitoring/prometheus-server:80" "monitoring/kps-prometheus:9090"
forward "Alertmanager" 9093 http  "firing alerts, silences" \
  "monitoring/prometheus-alertmanager:9093" "monitoring/kps-alertmanager:9093"
forward "Backstage"    7007 http  "service catalog (guest login)" \
  "backstage/backstage:7007"

# The banking app itself is public, through the Istio gateway's load balancer.
APP_HOST="$(kubectl get svc nexora-gateway-istio -n nexora -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)"
if [ -n "$APP_HOST" ]; then
  URLS+=("http://$APP_HOST")
  printf '  %-14s %s\n' "Banking app" "http://$APP_HOST"
else
  printf '  %-14s %s\n' "Banking app" "(gateway has no load balancer address yet)"
fi

echo ""
echo "Passwords (not printed here on purpose):"
echo "  ArgoCD:  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "  Grafana: kubectl -n monitoring get secret grafana-admin-credentials -o jsonpath='{.data.admin-password}' | base64 -d"
echo ""

if [ "${#PIDS[@]}" -eq 0 ]; then
  echo "No dashboard Service was found in this cluster."
  exit 1
fi

sleep 2 # give the tunnels a moment before a browser connects

if $OPEN_BROWSER; then
  opener=""
  command -v xdg-open >/dev/null 2>&1 && opener="xdg-open"
  [ -z "$opener" ] && command -v open >/dev/null 2>&1 && opener="open"
  if [ -n "$opener" ]; then
    for url in "${URLS[@]}"; do
      "$opener" "$url" >/dev/null 2>&1 &
    done
  else
    echo "No browser opener found (xdg-open / open). Open the URLs above by hand."
  fi
fi

echo "Tunnels are live. Press Ctrl+C to close them."
wait

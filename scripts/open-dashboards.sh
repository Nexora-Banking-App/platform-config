#!/bin/bash

echo "======================================================="
echo "   NEXORA PLATFORM - OPERATOR DASHBOARD LAUNCHER       "
echo "======================================================="

# 1. Kill any stale tunnels
pkill -f "kubectl port-forward" 2>/dev/null || true

echo "Starting secure IAM-authenticated tunnels..."

# 2. Start background tunnels
kubectl port-forward svc/argocd-server -n argocd 8081:443 >/dev/null 2>&1 &
kubectl port-forward svc/grafana -n monitoring 3000:80 >/dev/null 2>&1 &

sleep 2

# 3. Resolve URLs
APP_URL="http://$(kubectl get svc nexora-gateway-istio -n nexora -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
ARGOCD_URL="https://localhost:8081"
GRAFANA_URL="http://localhost:3000"

echo ""
echo "✅ Tunnels Established Successfully!"
echo "-------------------------------------------------------"
echo "🏦 Public Banking App: $APP_URL"
echo "🐙 ArgoCD Dashboard:  $ARGOCD_URL (User: admin)"
echo "📊 Grafana Metrics:   $GRAFANA_URL   (User: admin)"
echo "-------------------------------------------------------"

# 4. Physically POP OPEN the browser tabs!
if command -v xdg-open > /dev/null; then
    echo "🚀 Popping open browser windows..."
    xdg-open "$APP_URL" 2>/dev/null &
    xdg-open "$ARGOCD_URL" 2>/dev/null &
    xdg-open "$GRAFANA_URL" 2>/dev/null &
fi

echo ""
echo "Tunnels are live! Press Ctrl+C in this terminal when you are done."
echo ""

# Keep tunnels alive
wait

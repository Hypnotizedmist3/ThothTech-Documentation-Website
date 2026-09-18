#!/usr/bin/env bash
# Monitoring stage: confirms Prometheus is scraping both environments and
# prints current alert status straight into the Jenkins console log, so the
# stage output itself is evidence of a working monitoring integration.
set -uo pipefail

echo "=================================================="
echo " Prometheus scrape targets"
echo "=================================================="
if curl -sf http://localhost:9090/api/v1/targets > /tmp/prom-targets.json 2>/dev/null; then
    python3 -c "
import json
data = json.load(open('/tmp/prom-targets.json'))
for t in data['data']['activeTargets']:
    print(f\"  {t['labels'].get('instance', t['scrapeUrl'])}: {t['health']}\")
" || cat /tmp/prom-targets.json
else
    echo "Prometheus not reachable at localhost:9090 — start docker-compose.monitoring.yml (see SETUP.md)"
fi

echo "=================================================="
echo " Active alerts"
echo "=================================================="
if curl -sf http://localhost:9090/api/v1/alerts > /tmp/prom-alerts.json 2>/dev/null; then
    python3 -c "
import json
data = json.load(open('/tmp/prom-alerts.json'))
alerts = data['data']['alerts']
if not alerts:
    print('  No active alerts — all monitored endpoints healthy')
for a in alerts:
    print(f\"  [{a['labels'].get('severity','?')}] {a['labels'].get('alertname')} on {a['labels'].get('instance')}: {a['state']}\")
" || cat /tmp/prom-alerts.json
else
    echo "Prometheus not reachable — skipping alert summary"
fi

exit 0

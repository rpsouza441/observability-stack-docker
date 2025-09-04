# Módulo 05: Dashboards e Alertas

Este módulo aborda a criação de dashboards no Grafana e configuração de alertas para métricas do Node Exporter, fornecendo visualizações profissionais e monitoramento proativo.

## 📊 Dashboards do Grafana

### Dashboard Principal - Node Exporter Full

```json
{
  "dashboard": {
    "id": null,
    "title": "Node Exporter Full",
    "tags": ["node-exporter", "infrastructure"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 90}
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Memory Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "id": 3,
        "title": "Disk Usage",
        "type": "bargauge",
        "targets": [
          {
            "expr": "100 - ((node_filesystem_avail_bytes{mountpoint=\"/\",fstype!=\"rootfs\"} / node_filesystem_size_bytes{mountpoint=\"/\",fstype!=\"rootfs\"}) * 100)",
            "legendFormat": "{{instance}}"
          }
        ]
      }
    ]
  }
}
```

### Script para Importar Dashboard

```bash
#!/bin/bash
# import-node-exporter-dashboard.sh

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"
DASHBOARD_ID="1860"  # Node Exporter Full dashboard

echo "📊 Importando dashboard do Node Exporter..."

# Baixar dashboard do Grafana.com
curl -s "https://grafana.com/api/dashboards/${DASHBOARD_ID}/revisions/latest/download" > node-exporter-dashboard.json

# Preparar payload para importação
cat > import-payload.json << EOF
{
  "dashboard": $(cat node-exporter-dashboard.json),
  "overwrite": true,
  "inputs": [
    {
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "prometheus"
    }
  ]
}
EOF

# Importar dashboard
curl -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  -d @import-payload.json \
  "${GRAFANA_URL}/api/dashboards/import"

echo "✅ Dashboard importado com sucesso!"
echo "🌐 Acesse: ${GRAFANA_URL}/d/rYdddlPWk/node-exporter-full"

# Limpeza
rm -f node-exporter-dashboard.json import-payload.json
```

### Dashboard Customizado - Infraestrutura

```bash
#!/bin/bash
# create-custom-dashboard.sh

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

cat > custom-infrastructure-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Infrastructure Overview",
    "tags": ["infrastructure", "overview"],
    "timezone": "browser",
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s",
    "panels": [
      {
        "id": 1,
        "title": "System Load",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "node_load1",
            "legendFormat": "Load 1m - {{instance}}"
          },
          {
            "expr": "node_load5",
            "legendFormat": "Load 5m - {{instance}}"
          },
          {
            "expr": "node_load15",
            "legendFormat": "Load 15m - {{instance}}"
          }
        ]
      },
      {
        "id": 2,
        "title": "Network Traffic",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "irate(node_network_receive_bytes_total{device!~\"lo|veth.*|docker.*|flannel.*|cali.*|cbr.*\"}[5m])",
            "legendFormat": "RX - {{device}}"
          },
          {
            "expr": "irate(node_network_transmit_bytes_total{device!~\"lo|veth.*|docker.*|flannel.*|cali.*|cbr.*\"}[5m])",
            "legendFormat": "TX - {{device}}"
          }
        ]
      },
      {
        "id": 3,
        "title": "Disk I/O",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "irate(node_disk_read_bytes_total[5m])",
            "legendFormat": "Read - {{device}}"
          },
          {
            "expr": "irate(node_disk_written_bytes_total[5m])",
            "legendFormat": "Write - {{device}}"
          }
        ]
      }
    ]
  },
  "overwrite": true
}
EOF

# Importar dashboard customizado
curl -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  -d @custom-infrastructure-dashboard.json \
  "${GRAFANA_URL}/api/dashboards/db"

echo "✅ Dashboard customizado criado!"
rm -f custom-infrastructure-dashboard.json
```

## 🚨 Configuração de Alertas

### Regras de Alerta para Node Exporter

```yaml
# node-exporter-alerts.yml
groups:
  - name: node-exporter-alerts
    rules:
      # CPU Alerts
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          service: node-exporter
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% on {{ $labels.instance }} for more than 5 minutes. Current value: {{ $value }}%"

      - alert: CriticalCPUUsage
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
        for: 2m
        labels:
          severity: critical
          service: node-exporter
        annotations:
          summary: "Critical CPU usage detected"
          description: "CPU usage is above 95% on {{ $labels.instance }} for more than 2 minutes. Current value: {{ $value }}%"

      # Memory Alerts
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
        for: 5m
        labels:
          severity: warning
          service: node-exporter
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 80% on {{ $labels.instance }}. Current value: {{ $value }}%"

      - alert: CriticalMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 95
        for: 2m
        labels:
          severity: critical
          service: node-exporter
        annotations:
          summary: "Critical memory usage detected"
          description: "Memory usage is above 95% on {{ $labels.instance }}. Current value: {{ $value }}%"

      # Disk Alerts
      - alert: HighDiskUsage
        expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/",fstype!="rootfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!="rootfs"}) * 100) > 80
        for: 5m
        labels:
          severity: warning
          service: node-exporter
        annotations:
          summary: "High disk usage detected"
          description: "Disk usage is above 80% on {{ $labels.instance }} at {{ $labels.mountpoint }}. Current value: {{ $value }}%"

      - alert: CriticalDiskUsage
        expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/",fstype!="rootfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!="rootfs"}) * 100) > 95
        for: 2m
        labels:
          severity: critical
          service: node-exporter
        annotations:
          summary: "Critical disk usage detected"
          description: "Disk usage is above 95% on {{ $labels.instance }} at {{ $labels.mountpoint }}. Current value: {{ $value }}%"

      # Load Average Alerts
      - alert: HighLoadAverage
        expr: node_load15 / count by (instance) (node_cpu_seconds_total{mode="idle"}) > 1.5
        for: 10m
        labels:
          severity: warning
          service: node-exporter
        annotations:
          summary: "High load average detected"
          description: "Load average is high on {{ $labels.instance }}. Current 15m load: {{ $value }}"

      # Network Alerts
      - alert: HighNetworkTraffic
        expr: irate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*"}[5m]) > 100000000  # 100MB/s
        for: 5m
        labels:
          severity: warning
          service: node-exporter
        annotations:
          summary: "High network traffic detected"
          description: "High network receive traffic on {{ $labels.instance }} interface {{ $labels.device }}. Current rate: {{ $value | humanize }}B/s"

      # System Alerts
      - alert: NodeDown
        expr: up{job="node-exporter"} == 0
        for: 1m
        labels:
          severity: critical
          service: node-exporter
        annotations:
          summary: "Node Exporter is down"
          description: "Node Exporter on {{ $labels.instance }} has been down for more than 1 minute."

      - alert: SystemClockSkew
        expr: abs(node_timex_offset_seconds) > 0.05
        for: 2m
        labels:
          severity: warning
          service: node-exporter
        annotations:
          summary: "System clock skew detected"
          description: "Clock skew detected on {{ $labels.instance }}. Offset: {{ $value }}s"

      # Filesystem Alerts
      - alert: FilesystemReadOnly
        expr: node_filesystem_readonly{fstype!="rootfs"} == 1
        for: 1m
        labels:
          severity: critical
          service: node-exporter
        annotations:
          summary: "Filesystem is read-only"
          description: "Filesystem {{ $labels.mountpoint }} on {{ $labels.instance }} is read-only."

      - alert: HighInodeUsage
        expr: (1 - (node_filesystem_files_free / node_filesystem_files)) * 100 > 90
        for: 5m
        labels:
          severity: warning
          service: node-exporter
        annotations:
          summary: "High inode usage detected"
          description: "Inode usage is above 90% on {{ $labels.instance }} at {{ $labels.mountpoint }}. Current value: {{ $value }}%"
```

### Script de Configuração de Alertas

```bash
#!/bin/bash
# setup-node-exporter-alerts.sh

PROMETHEUS_CONFIG_DIR="/etc/prometheus"
RULES_DIR="${PROMETHEUS_CONFIG_DIR}/rules"
ALERTMANAGER_CONFIG="/etc/alertmanager/alertmanager.yml"

echo "🚨 Configurando alertas do Node Exporter..."

# Criar diretório de regras
sudo mkdir -p "$RULES_DIR"

# Copiar regras de alerta
sudo cp node-exporter-alerts.yml "$RULES_DIR/"

# Atualizar prometheus.yml
cat >> prometheus-alerts.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Configurar Alertmanager
cat > alertmanager-node-config.yml << 'EOF'
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@company.com'

route:
  group_by: ['alertname', 'instance']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
    - match:
        severity: warning
      receiver: 'warning-alerts'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://localhost:5001/'

  - name: 'critical-alerts'
    email_configs:
      - to: 'admin@company.com'
        subject: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Instance: {{ .Labels.instance }}
          Severity: {{ .Labels.severity }}
          {{ end }}
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts'
        title: '🚨 Critical Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

  - name: 'warning-alerts'
    email_configs:
      - to: 'team@company.com'
        subject: '⚠️ WARNING: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Instance: {{ .Labels.instance }}
          {{ end }}
EOF

echo "✅ Configuração de alertas concluída!"
echo "📝 Reinicie o Prometheus e Alertmanager para aplicar as mudanças"
```

## 📈 Dashboards Avançados

### Dashboard de Performance Detalhada

```bash
#!/bin/bash
# create-performance-dashboard.sh

cat > performance-dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "Node Performance Analysis",
    "panels": [
      {
        "title": "CPU Usage by Core",
        "type": "heatmap",
        "targets": [
          {
            "expr": "irate(node_cpu_seconds_total{mode!=\"idle\"}[5m])",
            "legendFormat": "CPU {{cpu}}"
          }
        ]
      },
      {
        "title": "Memory Breakdown",
        "type": "piechart",
        "targets": [
          {
            "expr": "node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes",
            "legendFormat": "Used"
          },
          {
            "expr": "node_memory_Buffers_bytes",
            "legendFormat": "Buffers"
          },
          {
            "expr": "node_memory_Cached_bytes",
            "legendFormat": "Cached"
          },
          {
            "expr": "node_memory_MemFree_bytes",
            "legendFormat": "Free"
          }
        ]
      },
      {
        "title": "Disk Latency",
        "type": "timeseries",
        "targets": [
          {
            "expr": "irate(node_disk_io_time_seconds_total[5m])",
            "legendFormat": "{{device}} I/O Time"
          }
        ]
      },
      {
        "title": "Network Errors",
        "type": "timeseries",
        "targets": [
          {
            "expr": "irate(node_network_receive_errs_total[5m])",
            "legendFormat": "RX Errors - {{device}}"
          },
          {
            "expr": "irate(node_network_transmit_errs_total[5m])",
            "legendFormat": "TX Errors - {{device}}"
          }
        ]
      }
    ]
  }
}
EOF

# Importar dashboard
curl -X POST \
  -H "Content-Type: application/json" \
  -u "admin:admin" \
  -d @performance-dashboard.json \
  "http://localhost:3000/api/dashboards/db"

echo "✅ Dashboard de performance criado!"
```

## 🔔 Notificações Avançadas

### Integração com Slack

```bash
#!/bin/bash
# setup-slack-notifications.sh

SLACK_WEBHOOK_URL="YOUR_SLACK_WEBHOOK_URL"
CHANNEL="#infrastructure-alerts"

cat > slack-notification-template.yml << EOF
template_files:
  - "templates/*.tmpl"

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: '${SLACK_WEBHOOK_URL}'
        channel: '${CHANNEL}'
        username: 'Prometheus'
        icon_emoji: ':warning:'
        title: '{{ if eq .Status "firing" }}🚨{{ else }}✅{{ end }} {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          *Instance:* {{ .Labels.instance }}
          *Severity:* {{ .Labels.severity }}
          *Status:* {{ .Status }}
          {{ if .GeneratorURL }}*Source:* <{{ .GeneratorURL }}|View in Prometheus>{{ end }}
          {{ end }}
        send_resolved: true
EOF

echo "✅ Configuração do Slack criada!"
```

### Template de Email Personalizado

```html
<!-- email-template.html -->
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        .alert { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .critical { background-color: #ffebee; border-left: 5px solid #f44336; }
        .warning { background-color: #fff3e0; border-left: 5px solid #ff9800; }
        .resolved { background-color: #e8f5e8; border-left: 5px solid #4caf50; }
    </style>
</head>
<body>
    <h2>{{ if eq .Status "firing" }}🚨 Alert Fired{{ else }}✅ Alert Resolved{{ end }}</h2>
    
    {{ range .Alerts }}
    <div class="alert {{ .Labels.severity }}">
        <h3>{{ .Annotations.summary }}</h3>
        <p><strong>Description:</strong> {{ .Annotations.description }}</p>
        <p><strong>Instance:</strong> {{ .Labels.instance }}</p>
        <p><strong>Severity:</strong> {{ .Labels.severity }}</p>
        <p><strong>Time:</strong> {{ .StartsAt.Format "2006-01-02 15:04:05" }}</p>
        {{ if .GeneratorURL }}
        <p><a href="{{ .GeneratorURL }}">View in Prometheus</a></p>
        {{ end }}
    </div>
    {{ end }}
</body>
</html>
```

## 🧪 Exercício Prático

### Script Principal do Exercício

```bash
#!/bin/bash
# exercicio-dashboards-alertas.sh

echo "🎯 Exercício: Dashboards e Alertas do Node Exporter"
echo "================================================"

# Função para verificar serviços
check_service() {
    local service=$1
    local port=$2
    if curl -s "http://localhost:${port}" > /dev/null; then
        echo "✅ $service está rodando na porta $port"
        return 0
    else
        echo "❌ $service não está acessível na porta $port"
        return 1
    fi
}

# Verificar pré-requisitos
echo "📋 Verificando pré-requisitos..."
check_service "Prometheus" "9090" || exit 1
check_service "Grafana" "3000" || exit 1
check_service "Node Exporter" "9100" || exit 1

# Cenário 1: Importar dashboards
echo "\n📊 Cenário 1: Importando dashboards..."
./import-node-exporter-dashboard.sh
./create-custom-dashboard.sh
./create-performance-dashboard.sh

# Cenário 2: Configurar alertas
echo "\n🚨 Cenário 2: Configurando alertas..."
./setup-node-exporter-alerts.sh

# Cenário 3: Testar alertas
echo "\n🧪 Cenário 3: Testando alertas..."
echo "Gerando carga de CPU para testar alertas..."
stress --cpu 4 --timeout 300s &
STRESS_PID=$!

echo "Aguardando 2 minutos para alertas dispararem..."
sleep 120

# Verificar alertas no Prometheus
echo "\n📈 Verificando alertas ativos..."
curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | select(.state=="firing") | {alertname: .labels.alertname, instance: .labels.instance, state: .state}'

# Parar stress test
kill $STRESS_PID 2>/dev/null

echo "\n✅ Exercício concluído!"
echo "🌐 Acesse os dashboards:"
echo "   - Node Exporter Full: http://localhost:3000/d/rYdddlPWk/node-exporter-full"
echo "   - Infrastructure Overview: http://localhost:3000/d/infrastructure/infrastructure-overview"
echo "   - Performance Analysis: http://localhost:3000/d/performance/node-performance-analysis"
echo "🚨 Verifique alertas: http://localhost:9090/alerts"
```

### Critérios de Validação

```bash
#!/bin/bash
# validacao-dashboards-alertas.sh

echo "🔍 Validando configuração de dashboards e alertas..."

SCORE=0
TOTAL=10

# Teste 1: Dashboards importados
if curl -s "http://localhost:3000/api/search?query=Node%20Exporter" | grep -q "Node Exporter"; then
    echo "✅ Dashboards do Node Exporter encontrados"
    ((SCORE++))
else
    echo "❌ Dashboards do Node Exporter não encontrados"
fi

# Teste 2: Regras de alerta carregadas
if curl -s "http://localhost:9090/api/v1/rules" | grep -q "node-exporter-alerts"; then
    echo "✅ Regras de alerta carregadas"
    ((SCORE++))
else
    echo "❌ Regras de alerta não carregadas"
fi

# Teste 3: Alertmanager configurado
if curl -s "http://localhost:9093/api/v1/status" | grep -q "success"; then
    echo "✅ Alertmanager está funcionando"
    ((SCORE++))
else
    echo "❌ Alertmanager não está funcionando"
fi

# Teste 4: Métricas sendo coletadas
if curl -s "http://localhost:9090/api/v1/query?query=up{job='node-exporter'}" | grep -q '"value":\[.*,"1"\]'; then
    echo "✅ Node Exporter está coletando métricas"
    ((SCORE++))
else
    echo "❌ Node Exporter não está coletando métricas"
fi

# Teste 5: Dashboard acessível
if curl -s "http://localhost:3000/api/health" | grep -q "ok"; then
    echo "✅ Grafana está acessível"
    ((SCORE++))
else
    echo "❌ Grafana não está acessível"
fi

echo "\n📊 Pontuação: $SCORE/$TOTAL"

if [ $SCORE -eq $TOTAL ]; then
    echo "🎉 Parabéns! Configuração perfeita!"
elif [ $SCORE -ge 7 ]; then
    echo "👍 Boa configuração! Alguns ajustes menores necessários."
else
    echo "⚠️ Configuração precisa de melhorias."
fi
```

## 📚 Resumo do Módulo

Neste módulo você aprendeu:

### 🎯 **Conceitos Principais**
- **Dashboards Profissionais**: Criação e importação de dashboards do Grafana
- **Visualizações Avançadas**: Gráficos, gauges, heatmaps e tabelas
- **Alertas Inteligentes**: Regras baseadas em métricas do Node Exporter
- **Notificações**: Integração com Slack, email e webhooks

### 🛠️ **Habilidades Desenvolvidas**
- Importação e customização de dashboards
- Configuração de regras de alerta
- Integração com sistemas de notificação
- Monitoramento proativo de infraestrutura

### 📈 **Próximos Passos**
- **Módulo 06**: Troubleshooting e Otimização
- **Módulo 07**: Projeto Final

---

## 🔗 Navegação

- [← Módulo Anterior: Integração com Prometheus](04-integracao-prometheus.md)
- [→ Próximo Módulo: Troubleshooting e Otimização](06-troubleshooting-otimizacao.md)
- [🏠 Voltar ao Índice](README.md)

---

*Documentação do Node Exporter - Módulo 05*
*Observability Stack - Especialização em Monitoramento*
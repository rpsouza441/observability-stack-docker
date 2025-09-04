# Módulo 06: Alertas

## Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- Configurar alertas no Grafana 9+
- Criar regras de alerta baseadas em queries
- Configurar contact points e notification policies
- Implementar silenciamentos e inibições
- Integrar com sistemas externos (Slack, email, PagerDuty)
- Gerenciar alertas em escala
- Troubleshooting de alertas

## 1. Introdução ao Sistema de Alertas

### 1.1 Arquitetura do Grafana Alerting

```mermaid
graph TD
    A[Alert Rules] --> B[Alert Manager]
    B --> C[Contact Points]
    B --> D[Notification Policies]
    B --> E[Silences]
    
    C --> F[Email]
    C --> G[Slack]
    C --> H[PagerDuty]
    C --> I[Webhook]
    
    D --> J[Routing]
    D --> K[Grouping]
    D --> L[Timing]
    
    E --> M[Temporary Muting]
    E --> N[Maintenance Windows]
```

### 1.2 Componentes Principais

**Alert Rules (Regras de Alerta):**
- Definem condições para disparar alertas
- Baseadas em queries de data sources
- Incluem thresholds e avaliação temporal

**Contact Points (Pontos de Contato):**
- Definem como e onde enviar notificações
- Suportam múltiplos canais (email, Slack, etc.)

**Notification Policies (Políticas de Notificação):**
- Controlam roteamento de alertas
- Definem agrupamento e timing

## 2. Configuração Básica

### 2.1 Habilitando Alertas

**Configuração no grafana.ini:**
```ini
[alerting]
# Habilitar o novo sistema de alertas
enabled = true

# Desabilitar alertas legados
execute_alerts = false

# Configurações de avaliação
evaluation_timeout_seconds = 30
max_annotation_age = 0s
max_alerts = 0

# Configurações de notificação
min_interval_seconds = 10
```

**Docker Compose:**
```yaml
version: '3.8'

services:
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_ALERTING_ENABLED=true
      - GF_ALERTING_EXECUTE_ALERTS=false
      - GF_UNIFIED_ALERTING_ENABLED=true
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./config/grafana.ini:/etc/grafana/grafana.ini

volumes:
  grafana-storage:
```

### 2.2 Verificação da Configuração

**Script de Verificação:**
```bash
#!/bin/bash
# check-alerting.sh

GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"

echo "Verificando status do alerting..."
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/alertmanager/grafana/api/v1/status" | jq .

echo "\nVerificando regras de alerta..."
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/ruler/grafana/api/v1/rules" | jq .
```

## 3. Criando Alert Rules

### 3.1 Regra Básica de CPU

**Configuração via UI:**
```json
{
  "uid": "cpu-high-alert",
  "title": "High CPU Usage",
  "condition": "C",
  "data": [
    {
      "refId": "A",
      "queryType": "",
      "relativeTimeRange": {
        "from": 600,
        "to": 0
      },
      "datasourceUid": "prometheus-uid",
      "model": {
        "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
        "interval": "",
        "refId": "A"
      }
    },
    {
      "refId": "B",
      "queryType": "",
      "relativeTimeRange": {
        "from": 0,
        "to": 0
      },
      "datasourceUid": "-100",
      "model": {
        "conditions": [
          {
            "evaluator": {
              "params": [80],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": ["A"]
            },
            "reducer": {
              "params": [],
              "type": "last"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "type": "__expr__",
          "uid": "-100"
        },
        "expression": "A",
        "hide": false,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "reducer": "last",
        "refId": "B",
        "type": "reduce"
      }
    },
    {
      "refId": "C",
      "queryType": "",
      "relativeTimeRange": {
        "from": 0,
        "to": 0
      },
      "datasourceUid": "-100",
      "model": {
        "conditions": [
          {
            "evaluator": {
              "params": [80, 0],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": []
            },
            "reducer": {
              "params": [],
              "type": "avg"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "name": "Expression",
          "type": "__expr__",
          "uid": "-100"
        },
        "expression": "B > 80",
        "hide": false,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "refId": "C",
        "type": "threshold"
      }
    }
  ],
  "intervalSeconds": 60,
  "maxDataPoints": 43200,
  "noDataState": "NoData",
  "execErrState": "Alerting",
  "for": "5m",
  "annotations": {
    "description": "CPU usage is above 80% for more than 5 minutes on {{ $labels.instance }}",
    "runbook_url": "https://wiki.company.com/runbooks/high-cpu",
    "summary": "High CPU usage detected"
  },
  "labels": {
    "severity": "warning",
    "team": "infrastructure"
  }
}
```

### 3.2 Regras Avançadas

**Alerta de Memória com Múltiplas Condições:**
```json
{
  "uid": "memory-critical-alert",
  "title": "Critical Memory Usage",
  "condition": "D",
  "data": [
    {
      "refId": "A",
      "model": {
        "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
        "refId": "A"
      }
    },
    {
      "refId": "B",
      "model": {
        "expr": "node_load5",
        "refId": "B"
      }
    },
    {
      "refId": "C",
      "model": {
        "expression": "A > 90",
        "refId": "C",
        "type": "threshold"
      }
    },
    {
      "refId": "D",
      "model": {
        "expression": "C AND B > 2",
        "refId": "D",
        "type": "math"
      }
    }
  ],
  "intervalSeconds": 30,
  "for": "2m",
  "annotations": {
    "description": "Memory usage is above 90% AND load is above 2 on {{ $labels.instance }}",
    "summary": "Critical system resources"
  },
  "labels": {
    "severity": "critical",
    "team": "sre"
  }
}
```

**Alerta de Disponibilidade de Serviço:**
```json
{
  "uid": "service-down-alert",
  "title": "Service Down",
  "condition": "B",
  "data": [
    {
      "refId": "A",
      "model": {
        "expr": "up{job=\"api\"}",
        "refId": "A"
      }
    },
    {
      "refId": "B",
      "model": {
        "expression": "A < 1",
        "refId": "B",
        "type": "threshold"
      }
    }
  ],
  "intervalSeconds": 30,
  "for": "1m",
  "noDataState": "Alerting",
  "execErrState": "Alerting",
  "annotations": {
    "description": "Service {{ $labels.job }} on {{ $labels.instance }} is down",
    "summary": "Service unavailable"
  },
  "labels": {
    "severity": "critical",
    "service": "{{ $labels.job }}"
  }
}
```

## 4. Contact Points

### 4.1 Email Contact Point

**Configuração SMTP:**
```json
{
  "name": "email-alerts",
  "type": "email",
  "settings": {
    "addresses": "ops-team@company.com;sre-team@company.com",
    "subject": "[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}",
    "message": "{{ range .Alerts }}\n**Alert:** {{ .Annotations.summary }}\n**Description:** {{ .Annotations.description }}\n**Severity:** {{ .Labels.severity }}\n**Instance:** {{ .Labels.instance }}\n**Time:** {{ .StartsAt.Format \"2006-01-02 15:04:05\" }}\n{{ end }}"
  }
}
```

**Configuração no grafana.ini:**
```ini
[smtp]
enabled = true
host = smtp.gmail.com:587
user = alerts@company.com
password = app-password
from_address = alerts@company.com
from_name = Grafana Alerts
skip_verify = false
```

### 4.2 Slack Contact Point

**Webhook Configuration:**
```json
{
  "name": "slack-alerts",
  "type": "slack",
  "settings": {
    "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
    "channel": "#alerts",
    "username": "Grafana",
    "title": "{{ .Status | toUpper }}: {{ .GroupLabels.alertname }}",
    "text": "{{ range .Alerts }}\n:warning: *{{ .Annotations.summary }}*\n{{ .Annotations.description }}\n*Severity:* {{ .Labels.severity }}\n*Instance:* {{ .Labels.instance }}\n{{ end }}",
    "color": "{{ if eq .Status \"firing\" }}danger{{ else }}good{{ end }}"
  }
}
```

**Slack App Configuration:**
```json
{
  "name": "slack-app-alerts",
  "type": "slack",
  "settings": {
    "token": "xoxb-your-bot-token",
    "channel": "#monitoring",
    "title": "{{ .Status | toUpper }}: {{ .GroupLabels.alertname }}",
    "text": "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}",
    "blocks": [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*Alert:* {{ .GroupLabels.alertname }}\n*Status:* {{ .Status | toUpper }}\n*Severity:* {{ .CommonLabels.severity }}"
        }
      },
      {
        "type": "section",
        "fields": [
          {
            "type": "mrkdwn",
            "text": "*Instance:*\n{{ .CommonLabels.instance }}"
          },
          {
            "type": "mrkdwn",
            "text": "*Time:*\n{{ .StartsAt.Format \"2006-01-02 15:04:05\" }}"
          }
        ]
      }
    ]
  }
}
```

### 4.3 PagerDuty Contact Point

**Integration Configuration:**
```json
{
  "name": "pagerduty-critical",
  "type": "pagerduty",
  "settings": {
    "integrationKey": "your-pagerduty-integration-key",
    "severity": "{{ .CommonLabels.severity }}",
    "class": "{{ .CommonLabels.alertname }}",
    "component": "{{ .CommonLabels.job }}",
    "group": "{{ .CommonLabels.team }}",
    "summary": "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}",
    "source": "Grafana"
  }
}
```

### 4.4 Webhook Contact Point

**Custom Webhook:**
```json
{
  "name": "custom-webhook",
  "type": "webhook",
  "settings": {
    "url": "https://api.company.com/alerts",
    "httpMethod": "POST",
    "username": "grafana",
    "password": "webhook-password",
    "title": "Grafana Alert",
    "message": "{{ .CommonAnnotations.summary }}"
  }
}
```

**Payload Customizado:**
```json
{
  "name": "teams-webhook",
  "type": "webhook",
  "settings": {
    "url": "https://company.webhook.office.com/webhookb2/...",
    "httpMethod": "POST",
    "title": "{{ .Status | toUpper }}: {{ .GroupLabels.alertname }}",
    "message": "{\n  \"@type\": \"MessageCard\",\n  \"@context\": \"https://schema.org/extensions\",\n  \"summary\": \"{{ .CommonAnnotations.summary }}\",\n  \"themeColor\": \"{{ if eq .Status \"firing\" }}FF0000{{ else }}00FF00{{ end }}\",\n  \"sections\": [\n    {\n      \"activityTitle\": \"{{ .GroupLabels.alertname }}\",\n      \"activitySubtitle\": \"{{ .CommonAnnotations.description }}\",\n      \"facts\": [\n        {\n          \"name\": \"Severity\",\n          \"value\": \"{{ .CommonLabels.severity }}\"\n        },\n        {\n          \"name\": \"Instance\",\n          \"value\": \"{{ .CommonLabels.instance }}\"\n        }\n      ]\n    }\n  ]\n}"
  }
}
```

## 5. Notification Policies

### 5.1 Política Básica

**Configuração Padrão:**
```json
{
  "receiver": "default-contact-point",
  "group_by": ["alertname", "cluster", "service"],
  "group_wait": "10s",
  "group_interval": "5m",
  "repeat_interval": "12h",
  "routes": [
    {
      "receiver": "critical-alerts",
      "matchers": [
        {
          "name": "severity",
          "value": "critical",
          "isRegex": false
        }
      ],
      "group_wait": "0s",
      "group_interval": "1m",
      "repeat_interval": "5m"
    },
    {
      "receiver": "warning-alerts",
      "matchers": [
        {
          "name": "severity",
          "value": "warning",
          "isRegex": false
        }
      ],
      "group_wait": "30s",
      "group_interval": "10m",
      "repeat_interval": "24h"
    }
  ]
}
```

### 5.2 Políticas Avançadas

**Roteamento por Equipe:**
```json
{
  "receiver": "default",
  "group_by": ["alertname"],
  "routes": [
    {
      "receiver": "infrastructure-team",
      "matchers": [
        {
          "name": "team",
          "value": "infrastructure",
          "isRegex": false
        }
      ],
      "routes": [
        {
          "receiver": "infra-critical",
          "matchers": [
            {
              "name": "severity",
              "value": "critical",
              "isRegex": false
            }
          ],
          "group_wait": "0s",
          "repeat_interval": "5m"
        }
      ]
    },
    {
      "receiver": "application-team",
      "matchers": [
        {
          "name": "team",
          "value": "application",
          "isRegex": false
        }
      ]
    },
    {
      "receiver": "business-hours",
      "matchers": [
        {
          "name": "severity",
          "value": "info",
          "isRegex": false
        }
      ],
      "active_time_intervals": ["business-hours"]
    }
  ]
}
```

**Time Intervals:**
```json
{
  "name": "business-hours",
  "time_intervals": [
    {
      "times": [
        {
          "start_time": "09:00",
          "end_time": "17:00"
        }
      ],
      "weekdays": ["monday:friday"]
    }
  ]
}
```

## 6. Silences (Silenciamentos)

### 6.1 Criando Silences

**Silence via API:**
```bash
#!/bin/bash
# create-silence.sh

GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"

# Silence para manutenção
curl -X POST \
  "$GRAFANA_URL/api/alertmanager/grafana/api/v1/silences" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {
        "name": "instance",
        "value": "server-01:9100",
        "isRegex": false
      }
    ],
    "startsAt": "2024-01-15T20:00:00Z",
    "endsAt": "2024-01-15T22:00:00Z",
    "createdBy": "ops-team",
    "comment": "Scheduled maintenance window"
  }'
```

**Silence por Regex:**
```json
{
  "matchers": [
    {
      "name": "alertname",
      "value": ".*CPU.*",
      "isRegex": true
    },
    {
      "name": "severity",
      "value": "warning",
      "isRegex": false
    }
  ],
  "startsAt": "2024-01-15T00:00:00Z",
  "endsAt": "2024-01-16T00:00:00Z",
  "createdBy": "maintenance-script",
  "comment": "Suppressing CPU warnings during load test"
}
```

### 6.2 Gerenciamento de Silences

**Script de Automação:**
```bash
#!/bin/bash
# manage-silences.sh

GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"

function list_silences() {
    echo "Active silences:"
    curl -s -H "Authorization: Bearer $API_KEY" \
         "$GRAFANA_URL/api/alertmanager/grafana/api/v1/silences" | \
         jq -r '.[] | select(.status.state == "active") | "ID: \(.id) | \(.comment) | Ends: \(.endsAt)"'
}

function delete_silence() {
    local silence_id=$1
    curl -X DELETE \
         -H "Authorization: Bearer $API_KEY" \
         "$GRAFANA_URL/api/alertmanager/grafana/api/v1/silence/$silence_id"
}

function create_maintenance_silence() {
    local instance=$1
    local duration_hours=${2:-2}
    local end_time=$(date -d "+$duration_hours hours" -u +"%Y-%m-%dT%H:%M:%SZ")
    
    curl -X POST \
         "$GRAFANA_URL/api/alertmanager/grafana/api/v1/silences" \
         -H "Authorization: Bearer $API_KEY" \
         -H "Content-Type: application/json" \
         -d "{
           \"matchers\": [
             {
               \"name\": \"instance\",
               \"value\": \"$instance\",
               \"isRegex\": false
             }
           ],
           \"startsAt\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
           \"endsAt\": \"$end_time\",
           \"createdBy\": \"maintenance-script\",
           \"comment\": \"Automated maintenance silence for $instance\"
         }"
}

# Uso
case "$1" in
    list)
        list_silences
        ;;
    delete)
        delete_silence "$2"
        ;;
    maintenance)
        create_maintenance_silence "$2" "$3"
        ;;
    *)
        echo "Usage: $0 {list|delete <id>|maintenance <instance> [hours]}"
        ;;
esac
```

## 7. Templates e Customização

### 7.1 Templates de Mensagem

**Template Avançado para Email:**
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        .alert-critical { background-color: #ff4444; color: white; }
        .alert-warning { background-color: #ffaa00; color: white; }
        .alert-info { background-color: #4444ff; color: white; }
        .alert-resolved { background-color: #44ff44; color: black; }
        .alert-box { padding: 10px; margin: 5px; border-radius: 5px; }
    </style>
</head>
<body>
    <h2>Grafana Alert Notification</h2>
    
    {{ range .Alerts }}
    <div class="alert-box alert-{{ .Labels.severity }}">
        <h3>{{ .Annotations.summary }}</h3>
        <p><strong>Description:</strong> {{ .Annotations.description }}</p>
        <p><strong>Instance:</strong> {{ .Labels.instance }}</p>
        <p><strong>Severity:</strong> {{ .Labels.severity }}</p>
        <p><strong>Started:</strong> {{ .StartsAt.Format "2006-01-02 15:04:05" }}</p>
        {{ if .EndsAt }}
        <p><strong>Ended:</strong> {{ .EndsAt.Format "2006-01-02 15:04:05" }}</p>
        {{ end }}
        {{ if .Annotations.runbook_url }}
        <p><a href="{{ .Annotations.runbook_url }}">View Runbook</a></p>
        {{ end }}
    </div>
    {{ end }}
    
    <hr>
    <p><small>Generated by Grafana at {{ .ExternalURL }}</small></p>
</body>
</html>
```

### 7.2 Funções de Template

**Exemplos de Funções:**
```go
// Formatação de tempo
{{ .StartsAt.Format "2006-01-02 15:04:05" }}

// Condicionais
{{ if eq .Status "firing" }}🔥{{ else }}✅{{ end }}

// Loops
{{ range .Alerts }}
  Alert: {{ .Annotations.summary }}
{{ end }}

// Agrupamento
{{ range .GroupLabels }}
  {{ . }}: {{ index $.CommonLabels . }}
{{ end }}

// Formatação de valores
{{ .Value | printf "%.2f" }}%

// Strings
{{ .Labels.instance | title }}
{{ .Annotations.description | upper }}
```

## 8. Monitoramento e Troubleshooting

### 8.1 Métricas de Alerting

**Queries Úteis:**
```promql
# Alertas ativos por severidade
sum by (severity) (grafana_alerting_active_alerts)

# Taxa de avaliação de regras
rate(grafana_alerting_rule_evaluations_total[5m])

# Falhas na avaliação
rate(grafana_alerting_rule_evaluation_failures_total[5m])

# Notificações enviadas
rate(grafana_alerting_notifications_sent_total[5m])

# Falhas em notificações
rate(grafana_alerting_notifications_failed_total[5m])
```

### 8.2 Dashboard de Monitoramento

**JSON do Dashboard:**
```json
{
  "dashboard": {
    "title": "Grafana Alerting Overview",
    "panels": [
      {
        "title": "Active Alerts by Severity",
        "type": "stat",
        "targets": [
          {
            "expr": "sum by (severity) (grafana_alerting_active_alerts)",
            "legendFormat": "{{ severity }}"
          }
        ]
      },
      {
        "title": "Rule Evaluation Rate",
        "type": "timeseries",
        "targets": [
          {
            "expr": "rate(grafana_alerting_rule_evaluations_total[5m])",
            "legendFormat": "Evaluations/sec"
          }
        ]
      },
      {
        "title": "Notification Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "(rate(grafana_alerting_notifications_sent_total[5m]) / (rate(grafana_alerting_notifications_sent_total[5m]) + rate(grafana_alerting_notifications_failed_total[5m]))) * 100",
            "legendFormat": "Success Rate %"
          }
        ]
      }
    ]
  }
}
```

### 8.3 Troubleshooting Comum

**Problemas e Soluções:**

1. **Alertas não disparando:**
```bash
# Verificar logs do Grafana
docker logs grafana | grep -i alert

# Verificar configuração da regra
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/ruler/grafana/api/v1/rules" | jq .

# Testar query manualmente
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/ds/query" \
     -d '{"queries":[{"expr":"your_query","refId":"A"}]}'
```

2. **Notificações não chegando:**
```bash
# Verificar contact points
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/alertmanager/grafana/config" | jq .alertmanager_config.receivers

# Testar contact point
curl -X POST \
     "$GRAFANA_URL/api/alertmanager/grafana/config/api/v1/receivers/test" \
     -H "Authorization: Bearer $API_KEY" \
     -d '{"name":"your-contact-point","grafana_managed_receiver_configs":[...]}'
```

3. **Performance issues:**
```bash
# Verificar métricas de performance
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/ds/query" \
     -d '{"queries":[{"expr":"grafana_alerting_rule_evaluation_duration_seconds","refId":"A"}]}'
```

## 9. Exercícios Práticos

### Exercício 1: Sistema de Alertas Básico

**Objetivo:** Configurar alertas para monitoramento de infraestrutura

**Tarefas:**
1. Criar regra de alerta para CPU > 80%
2. Configurar contact point para email
3. Criar notification policy
4. Testar o sistema

**Validação:**
```bash
# Simular alta CPU
stress --cpu 4 --timeout 300s

# Verificar alerta ativo
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/alertmanager/grafana/api/v1/alerts" | \
     jq '.[] | select(.labels.alertname == "High CPU Usage")'
```

### Exercício 2: Integração com Slack

**Objetivo:** Configurar notificações no Slack

**Webhook URL:** `https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK`

**Template de Mensagem:**
```json
{
  "text": ":warning: *{{ .Status | toUpper }}*: {{ .GroupLabels.alertname }}",
  "attachments": [
    {
      "color": "{{ if eq .Status \"firing\" }}danger{{ else }}good{{ end }}",
      "fields": [
        {
          "title": "Instance",
          "value": "{{ .CommonLabels.instance }}",
          "short": true
        },
        {
          "title": "Severity",
          "value": "{{ .CommonLabels.severity }}",
          "short": true
        }
      ]
    }
  ]
}
```

### Exercício 3: Alertas Avançados

**Objetivo:** Implementar alertas complexos com múltiplas condições

**Cenário:** Alerta quando CPU > 80% E Memória > 90% E Load > 2

**Implementação:**
```json
{
  "data": [
    {"refId": "A", "expr": "cpu_usage_percent"},
    {"refId": "B", "expr": "memory_usage_percent"},
    {"refId": "C", "expr": "node_load5"},
    {"refId": "D", "expression": "A > 80 AND B > 90 AND C > 2"}
  ]
}
```

## 10. Resumo do Módulo

### Conceitos Aprendidos

- ✅ **Alert Rules**: Criação e configuração de regras
- ✅ **Contact Points**: Email, Slack, PagerDuty, Webhook
- ✅ **Notification Policies**: Roteamento e timing
- ✅ **Silences**: Gerenciamento de silenciamentos
- ✅ **Templates**: Customização de mensagens
- ✅ **Troubleshooting**: Diagnóstico e resolução

### Próximos Passos

- **Módulo 07**: Provisioning e automação
- **Módulo 08**: Troubleshooting avançado
- **Módulo 09**: Projeto final integrado

### Recursos Adicionais

- [Grafana Alerting Documentation](https://grafana.com/docs/grafana/latest/alerting/)
- [Alert Rule Examples](https://grafana.com/docs/grafana/latest/alerting/alerting-rules/)
- [Contact Points Reference](https://grafana.com/docs/grafana/latest/alerting/contact-points/)

---

**Navegação:**
- [← Módulo 05: Visualizações](05-visualizacoes.md)
- [→ Módulo 07: Provisioning](07-provisioning.md)
- [🏠 Início](../README.md)
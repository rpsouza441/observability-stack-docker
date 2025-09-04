# Módulo 04: Dashboards

## Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- Criar e gerenciar dashboards no Grafana
- Configurar painéis com diferentes tipos de visualização
- Implementar variáveis para dashboards dinâmicos
- Utilizar templates e bibliotecas de dashboards
- Organizar dashboards em pastas e tags
- Compartilhar e exportar dashboards

## 1. Conceitos Fundamentais

### 1.1 O que são Dashboards

Um dashboard é uma coleção de painéis organizados em uma grade que fornece uma visão consolidada dos dados. No Grafana, dashboards são:

- **Interativos**: Permitem drill-down e filtragem
- **Responsivos**: Adaptam-se a diferentes tamanhos de tela
- **Compartilháveis**: Podem ser exportados e importados
- **Versionados**: Mantêm histórico de alterações

### 1.2 Anatomia de um Dashboard

```json
{
  "dashboard": {
    "id": null,
    "title": "Infrastructure Overview",
    "tags": ["infrastructure", "monitoring"],
    "timezone": "browser",
    "panels": [],
    "templating": {
      "list": []
    },
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "timepicker": {},
    "refresh": "30s",
    "version": 1
  }
}
```

## 2. Criando Dashboards

### 2.1 Criação Manual

**Passo a passo:**

1. **Novo Dashboard**
```bash
# Acesse: Grafana UI > + > Dashboard
# Ou use a API
curl -X POST \
  http://admin:admin@localhost:3000/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d '{
    "dashboard": {
      "title": "My New Dashboard",
      "panels": []
    }
  }'
```

2. **Configurações Básicas**
```json
{
  "title": "Sistema de Monitoramento",
  "description": "Dashboard principal para monitoramento de infraestrutura",
  "tags": ["production", "infrastructure"],
  "timezone": "America/Sao_Paulo",
  "refresh": "30s",
  "time": {
    "from": "now-6h",
    "to": "now"
  }
}
```

### 2.2 Importação de Dashboards

**Dashboard JSON completo:**
```json
{
  "dashboard": {
    "id": null,
    "title": "Node Exporter Full",
    "tags": ["prometheus", "node-exporter"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %"
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
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      }
    ],
    "time": {"from": "now-1h", "to": "now"},
    "refresh": "30s"
  }
}
```

## 3. Painéis (Panels)

### 3.1 Tipos de Painéis

**Time Series (Gráfico de Linha)**
```json
{
  "id": 1,
  "title": "Memory Usage Over Time",
  "type": "timeseries",
  "targets": [
    {
      "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
      "legendFormat": "Memory Usage %"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "custom": {
        "drawStyle": "line",
        "lineInterpolation": "linear",
        "lineWidth": 2,
        "fillOpacity": 10
      },
      "unit": "percent"
    }
  }
}
```

**Stat Panel (Valor Único)**
```json
{
  "id": 2,
  "title": "Current CPU Usage",
  "type": "stat",
  "targets": [
    {
      "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
      "legendFormat": "CPU %"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "mappings": [],
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {"color": "green", "value": null},
          {"color": "yellow", "value": 70},
          {"color": "red", "value": 90}
        ]
      },
      "unit": "percent"
    }
  },
  "options": {
    "reduceOptions": {
      "values": false,
      "calcs": ["lastNotNull"],
      "fields": ""
    },
    "orientation": "auto",
    "textMode": "auto",
    "colorMode": "value",
    "graphMode": "area",
    "justifyMode": "auto"
  }
}
```

**Table Panel**
```json
{
  "id": 3,
  "title": "Disk Usage by Mount Point",
  "type": "table",
  "targets": [
    {
      "expr": "100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes)",
      "format": "table",
      "instant": true
    }
  ],
  "fieldConfig": {
    "defaults": {
      "custom": {
        "align": "auto",
        "displayMode": "auto"
      },
      "mappings": [],
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {"color": "green", "value": null},
          {"color": "yellow", "value": 80},
          {"color": "red", "value": 90}
        ]
      },
      "unit": "percent"
    },
    "overrides": [
      {
        "matcher": {"id": "byName", "options": "mountpoint"},
        "properties": [
          {"id": "custom.width", "value": 200}
        ]
      }
    ]
  }
}
```

### 3.2 Layout e Posicionamento

**Grid System:**
```json
{
  "gridPos": {
    "h": 8,    // Altura (unidades de grid)
    "w": 12,   // Largura (máximo 24)
    "x": 0,    // Posição horizontal
    "y": 0     // Posição vertical
  }
}
```

**Exemplo de Layout Completo:**
```json
{
  "panels": [
    {
      "title": "CPU Usage",
      "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
    },
    {
      "title": "Memory Usage",
      "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0}
    },
    {
      "title": "Disk Usage",
      "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0}
    },
    {
      "title": "Network Traffic",
      "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0}
    },
    {
      "title": "System Load",
      "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
    }
  ]
}
```

## 4. Variáveis de Dashboard

### 4.1 Tipos de Variáveis

**Query Variable (Prometheus):**
```json
{
  "name": "instance",
  "type": "query",
  "label": "Instance",
  "query": "label_values(up, instance)",
  "refresh": 1,
  "includeAll": true,
  "allValue": ".*",
  "multi": true,
  "current": {
    "selected": false,
    "text": "All",
    "value": "$__all"
  }
}
```

**Custom Variable:**
```json
{
  "name": "environment",
  "type": "custom",
  "label": "Environment",
  "query": "production,staging,development",
  "current": {
    "selected": false,
    "text": "production",
    "value": "production"
  }
}
```

**Interval Variable:**
```json
{
  "name": "interval",
  "type": "interval",
  "label": "Interval",
  "query": "1m,5m,10m,30m,1h",
  "current": {
    "selected": false,
    "text": "5m",
    "value": "5m"
  },
  "auto": true,
  "auto_count": 30,
  "auto_min": "10s"
}
```

### 4.2 Usando Variáveis em Queries

**PromQL com Variáveis:**
```promql
# Usando variável de instância
rate(node_cpu_seconds_total{instance=~"$instance", mode!="idle"}[5m])

# Usando múltiplas variáveis
node_memory_MemAvailable_bytes{instance=~"$instance", job=~"$job"}

# Usando variável de intervalo
rate(http_requests_total[$interval])

# Usando variável customizada
up{environment="$environment"}
```

**Exemplo Completo de Dashboard com Variáveis:**
```json
{
  "templating": {
    "list": [
      {
        "name": "datasource",
        "type": "datasource",
        "query": "prometheus",
        "current": {
          "value": "Prometheus",
          "text": "Prometheus"
        }
      },
      {
        "name": "job",
        "type": "query",
        "datasource": "$datasource",
        "query": "label_values(up, job)",
        "refresh": 1,
        "includeAll": true,
        "multi": true
      },
      {
        "name": "instance",
        "type": "query",
        "datasource": "$datasource",
        "query": "label_values(up{job=~\"$job\"}, instance)",
        "refresh": 2,
        "includeAll": true,
        "multi": true
      }
    ]
  }
}
```

## 5. Templates e Bibliotecas

### 5.1 Dashboard Templates

**Template Básico de Infraestrutura:**
```json
{
  "dashboard": {
    "title": "Infrastructure Template",
    "tags": ["template", "infrastructure"],
    "templating": {
      "list": [
        {
          "name": "instance",
          "type": "query",
          "query": "label_values(up, instance)",
          "includeAll": true,
          "multi": true
        }
      ]
    },
    "panels": [
      {
        "title": "System Overview",
        "type": "row",
        "collapsed": false,
        "panels": [
          {
            "title": "CPU Usage",
            "type": "stat",
            "targets": [
              {
                "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{instance=~\"$instance\", mode=\"idle\"}[5m])) * 100)"
              }
            ]
          },
          {
            "title": "Memory Usage",
            "type": "stat",
            "targets": [
              {
                "expr": "(1 - (node_memory_MemAvailable_bytes{instance=~\"$instance\"} / node_memory_MemTotal_bytes{instance=~\"$instance\"})) * 100"
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### 5.2 Dashboards da Comunidade

**Importando Dashboards Populares:**

1. **Node Exporter Full (ID: 1860)**
```bash
# Via API
curl -X POST \
  http://admin:admin@localhost:3000/api/dashboards/import \
  -H 'Content-Type: application/json' \
  -d '{
    "dashboard": {
      "id": 1860
    },
    "overwrite": true,
    "inputs": [
      {
        "name": "DS_PROMETHEUS",
        "type": "datasource",
        "pluginId": "prometheus",
        "value": "Prometheus"
      }
    ]
  }'
```

2. **Kubernetes Cluster Monitoring (ID: 7249)**
3. **Docker Container & Host Metrics (ID: 10619)**
4. **NGINX Ingress Controller (ID: 9614)**

## 6. Organização e Gestão

### 6.1 Pastas e Tags

**Estrutura de Pastas:**
```json
{
  "folders": [
    {
      "title": "Infrastructure",
      "dashboards": [
        "Node Exporter",
        "Docker Monitoring",
        "Network Overview"
      ]
    },
    {
      "title": "Applications",
      "dashboards": [
        "Web Application",
        "Database Performance",
        "API Monitoring"
      ]
    },
    {
      "title": "Business",
      "dashboards": [
        "Sales Dashboard",
        "User Analytics",
        "Revenue Tracking"
      ]
    }
  ]
}
```

**Sistema de Tags:**
```json
{
  "tags": [
    "production",
    "staging",
    "infrastructure",
    "application",
    "business",
    "alerts",
    "performance"
  ]
}
```

### 6.2 Permissões e Compartilhamento

**Configuração de Permissões:**
```json
{
  "dashboard": {
    "title": "Production Dashboard",
    "meta": {
      "canEdit": false,
      "canSave": false,
      "canStar": true
    }
  }
}
```

**Links de Compartilhamento:**
```bash
# Gerar snapshot
curl -X POST \
  http://admin:admin@localhost:3000/api/snapshots \
  -H 'Content-Type: application/json' \
  -d '{
    "dashboard": {...},
    "name": "Production Snapshot",
    "expires": 3600
  }'
```

## 7. Automação e Provisioning

### 7.1 Dashboard como Código

**Arquivo de Provisioning:**
```yaml
# config/provisioning/dashboards/dashboards.yml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

**Docker Compose com Provisioning:**
```yaml
version: '3.8'

services:
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    volumes:
      - ./config/provisioning:/etc/grafana/provisioning
      - ./dashboards:/etc/grafana/provisioning/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
```

### 7.2 Backup e Versionamento

**Script de Backup:**
```bash
#!/bin/bash
# backup-dashboards.sh

GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"
BACKUP_DIR="./backups/$(date +%Y%m%d)"

mkdir -p "$BACKUP_DIR"

# Listar todos os dashboards
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/search?type=dash-db" | \
     jq -r '.[] | .uid' | \
while read uid; do
  echo "Backing up dashboard: $uid"
  curl -H "Authorization: Bearer $API_KEY" \
       "$GRAFANA_URL/api/dashboards/uid/$uid" > \
       "$BACKUP_DIR/$uid.json"
done
```

## 8. Exercícios Práticos

### Exercício 1: Dashboard Básico

**Objetivo:** Criar um dashboard de monitoramento de sistema

**Passos:**
1. Criar novo dashboard
2. Adicionar painéis para CPU, Memória, Disco
3. Configurar thresholds e cores
4. Adicionar variável de instância

**Validação:**
```bash
# Verificar se dashboard foi criado
curl -H "Authorization: Bearer $API_KEY" \
     "http://localhost:3000/api/search?query=Sistema" | jq .
```

### Exercício 2: Dashboard com Variáveis

**Objetivo:** Implementar dashboard dinâmico

**Template:**
```json
{
  "templating": {
    "list": [
      {
        "name": "job",
        "type": "query",
        "query": "label_values(up, job)"
      },
      {
        "name": "instance",
        "type": "query",
        "query": "label_values(up{job=~\"$job\"}, instance)"
      }
    ]
  }
}
```

### Exercício 3: Importação e Customização

**Objetivo:** Importar dashboard da comunidade e customizar

**Passos:**
1. Importar Node Exporter Full (ID: 1860)
2. Customizar painéis
3. Adicionar painéis específicos
4. Configurar alertas visuais

## 9. Resumo do Módulo

### Conceitos Aprendidos

- ✅ **Estrutura de Dashboards**: Painéis, layout, configurações
- ✅ **Tipos de Painéis**: Time series, stat, table, gauge
- ✅ **Variáveis**: Query, custom, interval, datasource
- ✅ **Templates**: Reutilização e padronização
- ✅ **Organização**: Pastas, tags, permissões
- ✅ **Automação**: Provisioning e backup

### Próximos Passos

- **Módulo 05**: Visualizações avançadas e customizações
- **Módulo 06**: Sistema de alertas e notificações
- **Módulo 07**: Provisioning e automação completa

### Recursos Adicionais

- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Community Dashboards](https://grafana.com/grafana/dashboards/)
- [Dashboard API Reference](https://grafana.com/docs/grafana/latest/http_api/dashboard/)

---

**Navegação:**
- [← Módulo 03: Data Sources](03-data-sources.md)
- [→ Módulo 05: Visualizações](05-visualizacoes.md)
- [🏠 Início](../README.md)
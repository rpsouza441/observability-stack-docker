# 📊 MÓDULO 09: INTEGRAÇÃO GRAFANA

> **Objetivo:** Dominar a integração entre Prometheus e Grafana para visualizações eficazes  
> **Duração:** 90 minutos  
> **Nível:** Intermediário

---

## 🎯 O QUE VOCÊ VAI APRENDER

Neste módulo você irá:
- ✅ Configurar Grafana com Prometheus como datasource
- ✅ Criar dashboards eficazes e informativos
- ✅ Usar variáveis e templating avançado
- ✅ Implementar alertas visuais no Grafana
- ✅ Aplicar boas práticas de visualização

---

## 🚀 CONFIGURAÇÃO INICIAL

### **🔧 Docker Compose com Grafana**

```yaml
# docker-compose.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./rules:/etc/prometheus/rules
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    command:
      - '--path.rootfs=/host'
    volumes:
      - '/:/host:ro,rslave'

volumes:
  grafana-storage:
```

### **📁 Estrutura de Diretórios**

```bash
# Criar estrutura para Grafana
mkdir -p grafana/provisioning/{datasources,dashboards}
mkdir -p grafana/dashboards

# Estrutura final:
# .
# ├── docker-compose.yml
# ├── prometheus.yml
# ├── rules/
# └── grafana/
#     ├── provisioning/
#     │   ├── datasources/
#     │   └── dashboards/
#     └── dashboards/
```

### **🔌 Configuração do Datasource**

```yaml
# grafana/provisioning/datasources/prometheus.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      httpMethod: POST
      queryTimeout: 60s
      timeInterval: 15s
    secureJsonData: {}
```

### **📊 Configuração de Dashboards**

```yaml
# grafana/provisioning/dashboards/dashboards.yml
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
      path: /var/lib/grafana/dashboards
```

---

## 📈 CRIANDO DASHBOARDS EFICAZES

### **🖥️ Dashboard de Sistema - Visão Geral**

```json
{
  "dashboard": {
    "id": null,
    "title": "System Overview",
    "tags": ["prometheus", "system"],
    "timezone": "browser",
    "refresh": "30s",
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "templating": {
      "list": [
        {
          "name": "instance",
          "type": "query",
          "query": "label_values(up, instance)",
          "refresh": 1,
          "includeAll": true,
          "multi": true
        },
        {
          "name": "job",
          "type": "query",
          "query": "label_values(up, job)",
          "refresh": 1,
          "includeAll": true,
          "multi": true
        }
      ]
    },
    "panels": [
      {
        "title": "System Uptime",
        "type": "stat",
        "targets": [
          {
            "expr": "avg(up{instance=~\"$instance\", job=~\"$job\"})",
            "legendFormat": "Uptime %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "min": 0,
            "max": 1,
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 0.8},
                {"color": "green", "value": 0.95}
              ]
            }
          }
        }
      },
      {
        "title": "CPU Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\", instance=~\"$instance\"}[5m])) * 100)",
            "legendFormat": "{{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        }
      },
      {
        "title": "Memory Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes{instance=~\"$instance\"} / node_memory_MemTotal_bytes{instance=~\"$instance\"})) * 100",
            "legendFormat": "{{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        }
      },
      {
        "title": "Disk Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "(1 - (node_filesystem_free_bytes{instance=~\"$instance\", fstype!=\"tmpfs\"} / node_filesystem_size_bytes{instance=~\"$instance\", fstype!=\"tmpfs\"})) * 100",
            "legendFormat": "{{instance}} - {{mountpoint}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        }
      }
    ]
  }
}
```

### **🌐 Dashboard de Aplicação Web**

```json
{
  "dashboard": {
    "title": "Web Application Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "type": "timeseries",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{job=~\"$job\"}[5m])) by (instance)",
            "legendFormat": "{{instance}} - Total"
          },
          {
            "expr": "sum(rate(http_requests_total{job=~\"$job\", status=~\"2..\"}[5m])) by (instance)",
            "legendFormat": "{{instance}} - 2xx"
          },
          {
            "expr": "sum(rate(http_requests_total{job=~\"$job\", status=~\"4..\"}[5m])) by (instance)",
            "legendFormat": "{{instance}} - 4xx"
          },
          {
            "expr": "sum(rate(http_requests_total{job=~\"$job\", status=~\"5..\"}[5m])) by (instance)",
            "legendFormat": "{{instance}} - 5xx"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "reqps"
          }
        }
      },
      {
        "title": "Error Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "(sum(rate(http_requests_total{job=~\"$job\", status=~\"5..\"}[5m])) / sum(rate(http_requests_total{job=~\"$job\"}[5m]))) * 100",
            "legendFormat": "Error Rate"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "green", "value": 0},
                {"color": "yellow", "value": 1},
                {"color": "red", "value": 5}
              ]
            }
          }
        }
      },
      {
        "title": "Response Time",
        "type": "timeseries",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket{job=~\"$job\"}[5m])) by (le, instance))",
            "legendFormat": "{{instance}} - P50"
          },
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job=~\"$job\"}[5m])) by (le, instance))",
            "legendFormat": "{{instance}} - P95"
          },
          {
            "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job=~\"$job\"}[5m])) by (le, instance))",
            "legendFormat": "{{instance}} - P99"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s"
          }
        }
      }
    ]
  }
}
```

---

## 🎨 VARIÁVEIS E TEMPLATING

### **📋 Tipos de Variáveis**

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
        "datasource": "${datasource}",
        "query": "label_values(up, job)",
        "refresh": 1,
        "includeAll": true,
        "multi": true,
        "allValue": ".*"
      },
      {
        "name": "instance",
        "type": "query",
        "datasource": "${datasource}",
        "query": "label_values(up{job=~\"$job\"}, instance)",
        "refresh": 2,
        "includeAll": true,
        "multi": true,
        "allValue": ".*"
      },
      {
        "name": "interval",
        "type": "interval",
        "query": "1m,5m,10m,30m,1h,6h,12h,1d,7d,14d,30d",
        "current": {
          "value": "5m",
          "text": "5m"
        }
      },
      {
        "name": "environment",
        "type": "custom",
        "query": "production,staging,development",
        "current": {
          "value": "production",
          "text": "production"
        }
      }
    ]
  }
}
```

### **🔄 Variáveis Avançadas**

```json
{
  "templating": {
    "list": [
      {
        "name": "node",
        "type": "query",
        "query": "label_values(node_uname_info, nodename)",
        "regex": "/([^.]+).*/",
        "refresh": 1
      },
      {
        "name": "disk",
        "type": "query",
        "query": "label_values(node_filesystem_size_bytes{instance=~\"$instance\", fstype!=\"tmpfs\"}, mountpoint)",
        "refresh": 2,
        "includeAll": true,
        "multi": true
      },
      {
        "name": "network_device",
        "type": "query",
        "query": "label_values(node_network_receive_bytes_total{instance=~\"$instance\", device!=\"lo\"}, device)",
        "refresh": 2,
        "includeAll": true,
        "multi": true
      }
    ]
  }
}
```

### **🎯 Queries com Variáveis**

```promql
# === USANDO VARIÁVEIS ===
# CPU por instância selecionada
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle", instance=~"$instance"}[5m])) * 100)

# Memória por job selecionado
(1 - (node_memory_MemAvailable_bytes{job=~"$job"} / node_memory_MemTotal_bytes{job=~"$job"})) * 100

# Disco por mountpoint selecionado
(1 - (node_filesystem_free_bytes{instance=~"$instance", mountpoint=~"$disk"} / node_filesystem_size_bytes{instance=~"$instance", mountpoint=~"$disk"})) * 100

# Rede por device selecionado
rate(node_network_receive_bytes_total{instance=~"$instance", device=~"$network_device"}[5m])

# === VARIÁVEIS CONDICIONAIS ===
# Mostrar apenas se variável está definida
${instance:+node_load1{instance=~"$instance"}}

# Valor padrão se variável vazia
${job:-".*"}

# === REGEX COM VARIÁVEIS ===
# Filtro flexível
up{job=~"$job", instance=~"$instance", environment="$environment"}

# Exclusão com variável
up{job!~"$excluded_jobs"}
```

---

## 📊 TIPOS DE VISUALIZAÇÃO

### **📈 Time Series (Gráficos de Linha)**

```json
{
  "type": "timeseries",
  "title": "CPU Usage Over Time",
  "targets": [
    {
      "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
      "legendFormat": "{{instance}}"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "min": 0,
      "max": 100,
      "custom": {
        "drawStyle": "line",
        "lineInterpolation": "linear",
        "lineWidth": 2,
        "fillOpacity": 10,
        "gradientMode": "none",
        "spanNulls": false,
        "pointSize": 5,
        "stacking": {
          "mode": "none",
          "group": "A"
        }
      }
    }
  },
  "options": {
    "tooltip": {
      "mode": "multi",
      "sort": "desc"
    },
    "legend": {
      "displayMode": "table",
      "placement": "bottom",
      "values": ["min", "max", "mean", "current"]
    }
  }
}
```

### **📊 Stat Panels (Valores Únicos)**

```json
{
  "type": "stat",
  "title": "Current CPU Usage",
  "targets": [
    {
      "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
      "legendFormat": "CPU Usage"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "min": 0,
      "max": 100,
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {"color": "green", "value": 0},
          {"color": "yellow", "value": 70},
          {"color": "red", "value": 90}
        ]
      },
      "mappings": [],
      "color": {
        "mode": "thresholds"
      }
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
    "colorMode": "background",
    "graphMode": "area",
    "justifyMode": "auto"
  }
}
```

### **📋 Table (Tabelas)**

```json
{
  "type": "table",
  "title": "System Resources Summary",
  "targets": [
    {
      "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
      "legendFormat": "CPU %",
      "format": "table",
      "instant": true
    },
    {
      "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
      "legendFormat": "Memory %",
      "format": "table",
      "instant": true
    },
    {
      "expr": "node_load1",
      "legendFormat": "Load 1m",
      "format": "table",
      "instant": true
    }
  ],
  "fieldConfig": {
    "defaults": {
      "custom": {
        "align": "auto",
        "displayMode": "auto"
      }
    },
    "overrides": [
      {
        "matcher": {"id": "byName", "options": "CPU %"},
        "properties": [
          {"id": "unit", "value": "percent"},
          {"id": "decimals", "value": 1},
          {
            "id": "thresholds",
            "value": {
              "steps": [
                {"color": "green", "value": 0},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 90}
              ]
            }
          }
        ]
      }
    ]
  }
}
```

### **🥧 Pie Chart (Gráfico de Pizza)**

```json
{
  "type": "piechart",
  "title": "CPU Usage by Mode",
  "targets": [
    {
      "expr": "avg by(mode) (rate(node_cpu_seconds_total[5m]))",
      "legendFormat": "{{mode}}"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "percentunit",
      "custom": {
        "hideFrom": {
          "legend": false,
          "tooltip": false,
          "vis": false
        }
      }
    }
  },
  "options": {
    "reduceOptions": {
      "values": false,
      "calcs": ["lastNotNull"],
      "fields": ""
    },
    "pieType": "pie",
    "tooltip": {
      "mode": "single",
      "sort": "none"
    },
    "legend": {
      "displayMode": "list",
      "placement": "right",
      "values": ["percent"]
    }
  }
}
```

---

## 🚨 ALERTAS NO GRAFANA

### **⚠️ Configuração de Alertas**

```json
{
  "alert": {
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
          "model": {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "intervalMs": 1000,
            "maxDataPoints": 43200,
            "refId": "A"
          },
          "params": ["A", "5m", "now"]
        },
        "reducer": {
          "params": [],
          "type": "last"
        },
        "type": "query"
      }
    ],
    "executionErrorState": "alerting",
    "for": "5m",
    "frequency": "10s",
    "handler": 1,
    "name": "High CPU Usage",
    "noDataState": "no_data",
    "notifications": [
      {
        "uid": "slack-notifications"
      }
    ]
  }
}
```

### **📧 Notification Channels**

```json
{
  "name": "slack-notifications",
  "type": "slack",
  "settings": {
    "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
    "channel": "#alerts",
    "username": "Grafana",
    "title": "{{ range .Alerts }}{{ .AlertName }}{{ end }}",
    "text": "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ .Annotations.description }}{{ end }}",
    "iconEmoji": ":exclamation:"
  }
}
```

---

## 🎨 BOAS PRÁTICAS DE VISUALIZAÇÃO

### **📏 Design Principles**

```json
{
  "dashboard": {
    "title": "Well-Designed Dashboard",
    "description": "Following visualization best practices",
    "tags": ["production", "monitoring"],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s",
    "panels": [
      {
        "title": "Key Metrics Overview",
        "type": "row",
        "collapsed": false,
        "panels": [
          {
            "title": "System Health",
            "type": "stat",
            "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
            "targets": [
              {
                "expr": "avg(up)",
                "legendFormat": "Uptime"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "unit": "percentunit",
                "thresholds": {
                  "steps": [
                    {"color": "red", "value": 0},
                    {"color": "yellow", "value": 0.95},
                    {"color": "green", "value": 0.99}
                  ]
                }
              }
            }
          }
        ]
      }
    ]
  }
}
```

### **🎯 Organização de Dashboards**

```bash
# === ESTRUTURA RECOMENDADA ===
# 1. Overview Dashboard (visão geral)
# 2. Detailed Dashboards (por componente)
# 3. Troubleshooting Dashboards (para debug)
# 4. Business Dashboards (métricas de negócio)

# === NOMENCLATURA ===
# [Environment] [Component] [Purpose]
# Exemplos:
# - "PROD - System - Overview"
# - "PROD - Application - Performance"
# - "PROD - Database - Health"
# - "DEV - Infrastructure - Debug"

# === TAGS ORGANIZACIONAIS ===
# - environment: prod, staging, dev
# - component: system, app, database, network
# - team: backend, frontend, devops, dba
# - purpose: overview, detailed, troubleshooting
```

### **📊 Métricas Essenciais por Dashboard**

```json
{
  "system_overview": {
    "key_metrics": [
      "System uptime and availability",
      "CPU usage (average and per-core)",
      "Memory usage (used/available)",
      "Disk usage (per filesystem)",
      "Network I/O (bytes/packets)",
      "Load average (1m, 5m, 15m)"
    ]
  },
  "application_performance": {
    "key_metrics": [
      "Request rate (RPS)",
      "Error rate (percentage)",
      "Response time (P50, P95, P99)",
      "Active connections",
      "Queue depth/length",
      "Throughput (business metrics)"
    ]
  },
  "database_health": {
    "key_metrics": [
      "Connection count",
      "Query performance (slow queries)",
      "Lock waits and deadlocks",
      "Buffer pool usage",
      "Replication lag",
      "Transaction rate"
    ]
  }
}
```

---

## 🔧 CONFIGURAÇÕES AVANÇADAS

### **🎨 Customização Visual**

```json
{
  "fieldConfig": {
    "defaults": {
      "color": {
        "mode": "palette-classic"
      },
      "custom": {
        "axisLabel": "",
        "axisPlacement": "auto",
        "barAlignment": 0,
        "drawStyle": "line",
        "fillOpacity": 10,
        "gradientMode": "none",
        "hideFrom": {
          "legend": false,
          "tooltip": false,
          "vis": false
        },
        "lineInterpolation": "linear",
        "lineWidth": 1,
        "pointSize": 5,
        "scaleDistribution": {
          "type": "linear"
        },
        "showPoints": "never",
        "spanNulls": false,
        "stacking": {
          "group": "A",
          "mode": "none"
        },
        "thresholdsStyle": {
          "mode": "off"
        }
      },
      "mappings": [],
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {"color": "green", "value": null},
          {"color": "red", "value": 80}
        ]
      },
      "unit": "percent"
    },
    "overrides": [
      {
        "matcher": {
          "id": "byName",
          "options": "Critical Metric"
        },
        "properties": [
          {
            "id": "color",
            "value": {
              "mode": "fixed",
              "fixedColor": "red"
            }
          },
          {
            "id": "custom.lineWidth",
            "value": 3
          }
        ]
      }
    ]
  }
}
```

### **📱 Responsividade**

```json
{
  "panels": [
    {
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "options": {
        "legend": {
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true,
          "values": ["min", "max", "mean"]
        }
      },
      "targets": [
        {
          "expr": "query_here",
          "legendFormat": "{{instance}}"
        }
      ]
    }
  ],
  "refresh": "30s",
  "schemaVersion": 30,
  "style": "dark",
  "tags": ["prometheus"],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": ""
}
```

---

## 🧪 EXERCÍCIOS PRÁTICOS

### **🎯 Exercício 1: Dashboard Básico**

```json
{
  "task": "Criar dashboard com:",
  "requirements": [
    "1. Panel de uptime dos serviços",
    "2. Gráfico de CPU usage por instância",
    "3. Tabela com resumo de recursos",
    "4. Variável para filtrar por job",
    "5. Alertas para CPU > 80%"
  ],
  "bonus": [
    "Adicionar thresholds coloridos",
    "Configurar refresh automático",
    "Adicionar descrições nos panels"
  ]
}
```

### **🎯 Exercício 2: Dashboard Avançado**

```json
{
  "task": "Criar dashboard de aplicação web com:",
  "requirements": [
    "1. Request rate por endpoint",
    "2. Error rate com threshold",
    "3. Latência P50, P95, P99",
    "4. Heatmap de response times",
    "5. Variáveis para job e instance"
  ],
  "advanced": [
    "Correlacionar métricas de app com sistema",
    "Adicionar annotations para deploys",
    "Criar drill-down entre dashboards"
  ]
}
```

### **🎯 Exercício 3: Dashboard Executivo**

```json
{
  "task": "Criar dashboard executivo com:",
  "requirements": [
    "1. SLA/SLO metrics",
    "2. Business metrics (usuários, transações)",
    "3. Cost metrics (se disponível)",
    "4. Availability por serviço",
    "5. Trends de crescimento"
  ],
  "presentation": [
    "Design limpo e profissional",
    "Métricas em formato de negócio",
    "Cores e thresholds apropriados"
  ]
}
```

---

## 🎓 RESUMO DO MÓDULO

### **Conceitos Aprendidos:**
- ✅ **Configuração:** Datasources, provisioning, docker-compose
- ✅ **Dashboards:** Criação, organização, boas práticas
- ✅ **Variáveis:** Query, custom, interval, templating
- ✅ **Visualizações:** Time series, stat, table, pie chart
- ✅ **Alertas:** Configuração, notification channels
- ✅ **Design:** Responsividade, customização, UX

### **Próximos Passos:**
1. 🚀 **[Módulo 10: Projeto Final](10-projeto-final.md)** - Implementação completa
2. 📚 **Prática:** Criar dashboards para seus próprios casos de uso
3. 🔍 **Explorar:** Plugins avançados do Grafana

---

**📚 Módulo Anterior:** [08 - Troubleshooting](08-troubleshooting.md)  
**📚 Próximo Módulo:** [10 - Projeto Final](10-projeto-final.md)  
**🏠 Voltar ao:** [README Principal](README.md)

---

*Módulo criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*
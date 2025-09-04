# Módulo 07: Provisioning

## Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- Implementar provisioning completo do Grafana
- Configurar data sources automaticamente
- Provisionar dashboards e pastas
- Automatizar configuração de alertas
- Gerenciar usuários e organizações via código
- Implementar CI/CD para configurações do Grafana
- Versionamento e backup de configurações

## 1. Introdução ao Provisioning

### 1.1 O que é Provisioning

Provisioning é o processo de configurar o Grafana automaticamente através de arquivos de configuração, permitindo:

- **Infrastructure as Code (IaC)**
- **Versionamento de configurações**
- **Deployments automatizados**
- **Consistência entre ambientes**
- **Backup e restore simplificados**

### 1.2 Tipos de Provisioning

```mermaid
graph TD
    A[Grafana Provisioning] --> B[Data Sources]
    A --> C[Dashboards]
    A --> D[Alert Rules]
    A --> E[Contact Points]
    A --> F[Notification Policies]
    A --> G[Folders]
    A --> H[Users & Teams]
    A --> I[Plugins]
    
    B --> B1[Prometheus]
    B --> B2[InfluxDB]
    B --> B3[MySQL]
    
    C --> C1[JSON Files]
    C --> C2[Dashboard Providers]
    
    D --> D1[Alert Rules]
    D --> D2[Recording Rules]
```

## 2. Estrutura de Provisioning

### 2.1 Diretório de Configuração

**Estrutura Padrão:**
```
provisioning/
├── datasources/
│   ├── datasources.yml
│   └── prometheus.yml
├── dashboards/
│   ├── dashboards.yml
│   └── dashboard-files/
│       ├── infrastructure/
│       │   ├── node-exporter.json
│       │   └── docker-monitoring.json
│       └── applications/
│           ├── api-monitoring.json
│           └── database-monitoring.json
├── alerting/
│   ├── rules.yml
│   ├── contact-points.yml
│   └── policies.yml
├── plugins/
│   └── plugins.yml
└── notifiers/
    └── notifiers.yml
```

### 2.2 Docker Compose Setup

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./provisioning:/etc/grafana/provisioning:ro
      - ./dashboards:/var/lib/grafana/dashboards:ro
    networks:
      - monitoring
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-storage:/prometheus
    networks:
      - monitoring
    restart: unless-stopped

volumes:
  grafana-storage:
  prometheus-storage:

networks:
  monitoring:
    driver: bridge
```

## 3. Data Sources Provisioning

### 3.1 Configuração Básica

**provisioning/datasources/datasources.yml:**
```yaml
apiVersion: 1

datasources:
  # Prometheus
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
    jsonData:
      httpMethod: POST
      manageAlerts: true
      prometheusType: Prometheus
      prometheusVersion: 2.40.0
      cacheLevel: 'High'
      disableRecordingRules: false
      incrementalQueryOverlapWindow: 10m
      queryTimeout: 60s
    secureJsonData:
      # Para autenticação básica (se necessário)
      # basicAuthPassword: 'password'
      # Para bearer token (se necessário)
      # httpHeaderValue1: 'Bearer your-token'

  # InfluxDB v2
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    database: monitoring
    user: grafana
    editable: false
    jsonData:
      version: Flux
      organization: myorg
      defaultBucket: monitoring
      tlsSkipVerify: true
    secureJsonData:
      token: 'your-influxdb-token'

  # MySQL
  - name: MySQL
    type: mysql
    url: mysql:3306
    database: grafana
    user: grafana
    editable: false
    jsonData:
      maxOpenConns: 100
      maxIdleConns: 100
      maxIdleConnsAuto: true
      connMaxLifetime: 14400
      timezone: 'UTC'
    secureJsonData:
      password: 'mysql-password'

  # Loki
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false
    jsonData:
      maxLines: 1000
      derivedFields:
        - datasourceUid: 'jaeger-uid'
          matcherRegex: 'traceID=(\w+)'
          name: 'TraceID'
          url: '$${__value.raw}'

  # Jaeger
  - name: Jaeger
    type: jaeger
    uid: jaeger-uid
    access: proxy
    url: http://jaeger:16686
    editable: false
    jsonData:
      tracesToLogs:
        datasourceUid: 'loki'
        tags: ['job', 'instance', 'pod', 'namespace']
        mappedTags: [{ key: 'service.name', value: 'service' }]
        mapTagNamesEnabled: false
        spanStartTimeShift: '1h'
        spanEndTimeShift: '-1h'
        filterByTraceID: false
        filterBySpanID: false
```

### 3.2 Data Sources Avançados

**CloudWatch:**
```yaml
  - name: CloudWatch
    type: cloudwatch
    jsonData:
      authType: keys
      defaultRegion: us-east-1
      customMetricsNamespaces: 'AWS/EC2,AWS/RDS,CWAgent'
      assumeRoleArn: 'arn:aws:iam::123456789012:role/GrafanaCloudWatchRole'
    secureJsonData:
      accessKey: 'AKIAIOSFODNN7EXAMPLE'
      secretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
```

**Azure Monitor:**
```yaml
  - name: Azure Monitor
    type: grafana-azure-monitor-datasource
    jsonData:
      azureAuthType: msi
      subscriptionId: 'your-subscription-id'
      tenantId: 'your-tenant-id'
      clientId: 'your-client-id'
      cloudName: azuremonitor
    secureJsonData:
      clientSecret: 'your-client-secret'
```

**Google Cloud Monitoring:**
```yaml
  - name: Google Cloud Monitoring
    type: stackdriver
    jsonData:
      authenticationType: gce
      defaultProject: 'your-project-id'
      gceDefaultProject: 'your-project-id'
    secureJsonData:
      privateKey: |
        -----BEGIN PRIVATE KEY-----
        your-service-account-private-key
        -----END PRIVATE KEY-----
```

## 4. Dashboard Provisioning

### 4.1 Dashboard Providers

**provisioning/dashboards/dashboards.yml:**
```yaml
apiVersion: 1

providers:
  # Infrastructure dashboards
  - name: 'infrastructure'
    orgId: 1
    folder: 'Infrastructure'
    folderUid: 'infrastructure'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards/infrastructure

  # Application dashboards
  - name: 'applications'
    orgId: 1
    folder: 'Applications'
    folderUid: 'applications'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards/applications

  # Business dashboards
  - name: 'business'
    orgId: 1
    folder: 'Business'
    folderUid: 'business'
    type: file
    disableDeletion: true
    updateIntervalSeconds: 30
    allowUiUpdates: false
    options:
      path: /var/lib/grafana/dashboards/business

  # External dashboards (from URL)
  - name: 'external'
    orgId: 1
    folder: 'External'
    type: file
    disableDeletion: true
    updateIntervalSeconds: 3600
    allowUiUpdates: false
    options:
      path: /var/lib/grafana/dashboards/external
```

### 4.2 Dashboard Templates

**Template Base para Node Exporter:**
```json
{
  "dashboard": {
    "id": null,
    "uid": "node-exporter-full",
    "title": "Node Exporter Full",
    "description": "Complete Node Exporter dashboard for system monitoring",
    "tags": ["prometheus", "node-exporter", "infrastructure"],
    "timezone": "browser",
    "editable": true,
    "graphTooltip": 1,
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "timepicker": {
      "refresh_intervals": ["5s", "10s", "30s", "1m", "5m", "15m", "30m", "1h", "2h", "1d"],
      "time_options": ["5m", "15m", "1h", "6h", "12h", "24h", "2d", "7d", "30d"]
    },
    "templating": {
      "list": [
        {
          "name": "datasource",
          "type": "datasource",
          "query": "prometheus",
          "current": {
            "value": "${DS_PROMETHEUS}",
            "text": "Prometheus"
          },
          "hide": 0,
          "includeAll": false,
          "multi": false,
          "options": [],
          "refresh": 1,
          "regex": "",
          "skipUrlSync": false
        },
        {
          "name": "job",
          "type": "query",
          "datasource": "${datasource}",
          "query": "label_values(up, job)",
          "current": {},
          "hide": 0,
          "includeAll": true,
          "multi": true,
          "options": [],
          "refresh": 1,
          "regex": "",
          "skipUrlSync": false,
          "sort": 1,
          "tagValuesQuery": "",
          "tagsQuery": "",
          "useTags": false
        },
        {
          "name": "instance",
          "type": "query",
          "datasource": "${datasource}",
          "query": "label_values(up{job=~\"$job\"}, instance)",
          "current": {},
          "hide": 0,
          "includeAll": true,
          "multi": true,
          "options": [],
          "refresh": 2,
          "regex": "",
          "skipUrlSync": false,
          "sort": 1
        }
      ]
    },
    "panels": [
      {
        "id": 1,
        "title": "System Overview",
        "type": "row",
        "collapsed": false,
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 0},
        "panels": []
      },
      {
        "id": 2,
        "title": "CPU Usage",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 1},
        "targets": [
          {
            "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{instance=~\"$instance\", mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{ instance }}",
            "refId": "A"
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
        "id": 3,
        "title": "Memory Usage",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 1},
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes{instance=~\"$instance\"} / node_memory_MemTotal_bytes{instance=~\"$instance\"})) * 100",
            "legendFormat": "{{ instance }}",
            "refId": "A"
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
                {"color": "yellow", "value": 80},
                {"color": "red", "value": 95}
              ]
            }
          }
        }
      }
    ],
    "refresh": "30s",
    "schemaVersion": 36,
    "version": 1
  },
  "overwrite": true
}
```

### 4.3 Script de Geração de Dashboards

**generate-dashboards.sh:**
```bash
#!/bin/bash
# Script para gerar dashboards automaticamente

DASHBOARD_DIR="./dashboards"
TEMPLATE_DIR="./templates"
OUTPUT_DIR="./provisioning/dashboards/dashboard-files"

# Função para substituir variáveis em templates
generate_dashboard() {
    local template_file=$1
    local output_file=$2
    local datasource_uid=${3:-"prometheus"}
    local folder=${4:-"Generated"}
    
    # Substituir variáveis no template
    sed -e "s/\${DS_PROMETHEUS}/$datasource_uid/g" \
        -e "s/\${FOLDER}/$folder/g" \
        "$template_file" > "$output_file"
    
    echo "Dashboard gerado: $output_file"
}

# Criar diretórios se não existirem
mkdir -p "$OUTPUT_DIR/infrastructure"
mkdir -p "$OUTPUT_DIR/applications"
mkdir -p "$OUTPUT_DIR/business"

# Gerar dashboards de infraestrutura
for template in "$TEMPLATE_DIR/infrastructure"/*.json; do
    filename=$(basename "$template")
    generate_dashboard "$template" "$OUTPUT_DIR/infrastructure/$filename" "prometheus" "Infrastructure"
done

# Gerar dashboards de aplicação
for template in "$TEMPLATE_DIR/applications"/*.json; do
    filename=$(basename "$template")
    generate_dashboard "$template" "$OUTPUT_DIR/applications/$filename" "prometheus" "Applications"
done

echo "Todos os dashboards foram gerados com sucesso!"
```

## 5. Alert Provisioning

### 5.1 Alert Rules

**provisioning/alerting/rules.yml:**
```yaml
apiVersion: 1

groups:
  - name: infrastructure.rules
    orgId: 1
    folder: Infrastructure Alerts
    interval: 1m
    rules:
      - uid: high-cpu-usage
        title: High CPU Usage
        condition: C
        data:
          - refId: A
            queryType: ''
            relativeTimeRange:
              from: 300
              to: 0
            datasourceUid: prometheus
            model:
              expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
              interval: ''
              refId: A
          - refId: B
            queryType: ''
            relativeTimeRange:
              from: 0
              to: 0
            datasourceUid: __expr__
            model:
              conditions:
                - evaluator:
                    params: [80]
                    type: gt
                  operator:
                    type: and
                  query:
                    params: [A]
                  reducer:
                    params: []
                    type: last
                  type: query
              datasource:
                type: __expr__
                uid: __expr__
              expression: A
              hide: false
              intervalMs: 1000
              maxDataPoints: 43200
              reducer: last
              refId: B
              type: reduce
          - refId: C
            queryType: ''
            relativeTimeRange:
              from: 0
              to: 0
            datasourceUid: __expr__
            model:
              conditions:
                - evaluator:
                    params: [80, 0]
                    type: gt
                  operator:
                    type: and
                  query:
                    params: []
                  reducer:
                    params: []
                    type: avg
                  type: query
              datasource:
                name: Expression
                type: __expr__
                uid: __expr__
              expression: B > 80
              hide: false
              intervalMs: 1000
              maxDataPoints: 43200
              refId: C
              type: threshold
        noDataState: NoData
        execErrState: Alerting
        for: 5m
        annotations:
          description: 'CPU usage is above 80% for more than 5 minutes on {{ $labels.instance }}'
          runbook_url: 'https://wiki.company.com/runbooks/high-cpu'
          summary: 'High CPU usage detected'
        labels:
          severity: warning
          team: infrastructure

      - uid: service-down
        title: Service Down
        condition: B
        data:
          - refId: A
            queryType: ''
            relativeTimeRange:
              from: 60
              to: 0
            datasourceUid: prometheus
            model:
              expr: up{job="api"}
              interval: ''
              refId: A
          - refId: B
            queryType: ''
            relativeTimeRange:
              from: 0
              to: 0
            datasourceUid: __expr__
            model:
              expression: A < 1
              refId: B
              type: threshold
        noDataState: Alerting
        execErrState: Alerting
        for: 1m
        annotations:
          description: 'Service {{ $labels.job }} on {{ $labels.instance }} is down'
          summary: 'Service unavailable'
        labels:
          severity: critical
          service: '{{ $labels.job }}'
```

### 5.2 Contact Points

**provisioning/alerting/contact-points.yml:**
```yaml
apiVersion: 1

contactPoints:
  - orgId: 1
    name: email-alerts
    receivers:
      - uid: email-receiver
        type: email
        settings:
          addresses: 'ops-team@company.com;sre-team@company.com'
          subject: '[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}'
          message: |
            {{ range .Alerts }}
            **Alert:** {{ .Annotations.summary }}
            **Description:** {{ .Annotations.description }}
            **Severity:** {{ .Labels.severity }}
            **Instance:** {{ .Labels.instance }}
            **Time:** {{ .StartsAt.Format "2006-01-02 15:04:05" }}
            {{ end }}

  - orgId: 1
    name: slack-alerts
    receivers:
      - uid: slack-receiver
        type: slack
        settings:
          url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
          channel: '#alerts'
          username: 'Grafana'
          title: '{{ .Status | toUpper }}: {{ .GroupLabels.alertname }}'
          text: |
            {{ range .Alerts }}
            :warning: *{{ .Annotations.summary }}*
            {{ .Annotations.description }}
            *Severity:* {{ .Labels.severity }}
            *Instance:* {{ .Labels.instance }}
            {{ end }}
          color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'

  - orgId: 1
    name: pagerduty-critical
    receivers:
      - uid: pagerduty-receiver
        type: pagerduty
        settings:
          integrationKey: 'your-pagerduty-integration-key'
          severity: '{{ .CommonLabels.severity }}'
          class: '{{ .CommonLabels.alertname }}'
          component: '{{ .CommonLabels.job }}'
          group: '{{ .CommonLabels.team }}'
          summary: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
          source: 'Grafana'

  - orgId: 1
    name: webhook-custom
    receivers:
      - uid: webhook-receiver
        type: webhook
        settings:
          url: 'https://api.company.com/alerts'
          httpMethod: 'POST'
          username: 'grafana'
          password: 'webhook-password'
          title: 'Grafana Alert'
          message: '{{ .CommonAnnotations.summary }}'
```

### 5.3 Notification Policies

**provisioning/alerting/policies.yml:**
```yaml
apiVersion: 1

policies:
  - orgId: 1
    receiver: default-contact-point
    group_by: ['alertname', 'cluster', 'service']
    group_wait: 10s
    group_interval: 5m
    repeat_interval: 12h
    routes:
      # Critical alerts - immediate notification
      - receiver: pagerduty-critical
        matchers:
          - name: severity
            value: critical
            isRegex: false
        group_wait: 0s
        group_interval: 1m
        repeat_interval: 5m
        routes:
          # Infrastructure team for infrastructure alerts
          - receiver: email-alerts
            matchers:
              - name: team
                value: infrastructure
                isRegex: false
            continue: true
          # Slack for all critical alerts
          - receiver: slack-alerts
            continue: true
      
      # Warning alerts
      - receiver: slack-alerts
        matchers:
          - name: severity
            value: warning
            isRegex: false
        group_wait: 30s
        group_interval: 10m
        repeat_interval: 24h
      
      # Info alerts - business hours only
      - receiver: email-alerts
        matchers:
          - name: severity
            value: info
            isRegex: false
        active_time_intervals:
          - business-hours
        group_wait: 5m
        group_interval: 30m
        repeat_interval: 168h  # 1 week
      
      # Team-specific routing
      - receiver: infrastructure-team
        matchers:
          - name: team
            value: infrastructure
            isRegex: false
        routes:
          - receiver: webhook-custom
            matchers:
              - name: alertname
                value: ".*Database.*"
                isRegex: true
            continue: true

mute_time_intervals:
  - name: business-hours
    time_intervals:
      - times:
          - start_time: '09:00'
            end_time: '17:00'
        weekdays: ['monday:friday']
        months: ['1:12']
        days_of_month: ['1:31']
  
  - name: maintenance-window
    time_intervals:
      - times:
          - start_time: '02:00'
            end_time: '04:00'
        weekdays: ['saturday']
```

## 6. Plugins Provisioning

### 6.1 Plugin Configuration

**provisioning/plugins/plugins.yml:**
```yaml
apiVersion: 1

apps:
  # Instalar plugins automaticamente
  - type: grafana-clock-panel
    name: clock
    disabled: false
    jsonData:
      autoUpdate: true
  
  - type: grafana-worldmap-panel
    name: worldmap
    disabled: false
  
  - type: grafana-piechart-panel
    name: piechart
    disabled: false
  
  - type: vonage-status-panel
    name: status-panel
    disabled: false

  # Plugin customizado
  - type: custom-plugin
    name: company-plugin
    disabled: false
    jsonData:
      apiUrl: 'https://api.company.com'
      refreshInterval: 30
    secureJsonData:
      apiKey: 'your-api-key'
```

### 6.2 Script de Instalação de Plugins

**install-plugins.sh:**
```bash
#!/bin/bash
# Script para instalar plugins do Grafana

PLUGINS=(
    "grafana-clock-panel"
    "grafana-worldmap-panel"
    "grafana-piechart-panel"
    "vonage-status-panel"
    "grafana-polystat-panel"
    "briangann-gauge-panel"
    "natel-discrete-panel"
    "grafana-kubernetes-app"
)

echo "Instalando plugins do Grafana..."

for plugin in "${PLUGINS[@]}"; do
    echo "Instalando $plugin..."
    grafana-cli plugins install "$plugin"
done

echo "Reiniciando Grafana..."
sudo systemctl restart grafana-server

echo "Plugins instalados com sucesso!"
```

## 7. CI/CD Integration

### 7.1 GitHub Actions

**.github/workflows/grafana-deploy.yml:**
```yaml
name: Deploy Grafana Configuration

on:
  push:
    branches: [main]
    paths:
      - 'grafana/**'
      - 'provisioning/**'
  pull_request:
    branches: [main]
    paths:
      - 'grafana/**'
      - 'provisioning/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Validate JSON files
        run: |
          find . -name "*.json" -type f -exec sh -c '
            for file do
              echo "Validating $file"
              jq empty "$file" || exit 1
            done
          ' sh {} +
      
      - name: Validate YAML files
        run: |
          find . -name "*.yml" -o -name "*.yaml" -type f -exec sh -c '
            for file do
              echo "Validating $file"
              python -c "import yaml; yaml.safe_load(open('$file'))" || exit 1
            done
          ' sh {} +

  deploy-staging:
    needs: validate
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    environment: staging
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Staging
        run: |
          # Sync configurations to staging Grafana
          rsync -av --delete provisioning/ staging-server:/etc/grafana/provisioning/
          
          # Restart Grafana
          ssh staging-server 'sudo systemctl restart grafana-server'
          
          # Wait for Grafana to be ready
          sleep 30
          
          # Validate deployment
          curl -f http://staging-grafana:3000/api/health || exit 1

  deploy-production:
    needs: validate
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: actions/checkout@v3
      
      - name: Backup current configuration
        run: |
          # Backup current Grafana configuration
          ssh prod-server 'tar -czf /backup/grafana-$(date +%Y%m%d-%H%M%S).tar.gz /etc/grafana/provisioning/'
      
      - name: Deploy to Production
        run: |
          # Sync configurations
          rsync -av --delete provisioning/ prod-server:/etc/grafana/provisioning/
          
          # Restart Grafana
          ssh prod-server 'sudo systemctl restart grafana-server'
          
          # Wait and validate
          sleep 30
          curl -f http://prod-grafana:3000/api/health || exit 1
      
      - name: Notify deployment
        run: |
          curl -X POST -H 'Content-type: application/json' \
            --data '{"text":"Grafana configuration deployed to production"}' \
            ${{ secrets.SLACK_WEBHOOK_URL }}
```

### 7.2 GitLab CI

**.gitlab-ci.yml:**
```yaml
stages:
  - validate
  - deploy-staging
  - deploy-production

variables:
  GRAFANA_IMAGE: grafana/grafana:latest

validate-config:
  stage: validate
  image: alpine:latest
  before_script:
    - apk add --no-cache jq python3 py3-yaml
  script:
    - echo "Validating JSON files..."
    - find . -name "*.json" -exec jq empty {} \;
    - echo "Validating YAML files..."
    - find . -name "*.yml" -o -name "*.yaml" -exec python3 -c "import yaml; yaml.safe_load(open('{}'))" \;
    - echo "All configuration files are valid"

deploy-staging:
  stage: deploy-staging
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker-compose -f docker-compose.staging.yml up -d grafana
    - sleep 30
    - docker-compose -f docker-compose.staging.yml exec -T grafana curl -f http://localhost:3000/api/health
  environment:
    name: staging
    url: http://staging-grafana.company.com
  only:
    - merge_requests

deploy-production:
  stage: deploy-production
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - echo "Creating backup..."
    - docker exec grafana tar -czf /var/lib/grafana/backup-$(date +%Y%m%d-%H%M%S).tar.gz /etc/grafana/provisioning/
  script:
    - docker-compose -f docker-compose.prod.yml up -d grafana
    - sleep 30
    - docker-compose -f docker-compose.prod.yml exec -T grafana curl -f http://localhost:3000/api/health
  after_script:
    - |
      curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"Grafana configuration deployed to production"}' \
        $SLACK_WEBHOOK_URL
  environment:
    name: production
    url: http://grafana.company.com
  only:
    - main
  when: manual
```

## 8. Backup e Restore

### 8.1 Script de Backup

**backup-grafana.sh:**
```bash
#!/bin/bash
# Script completo de backup do Grafana

set -e

# Configurações
GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"
BACKUP_DIR="./backups/$(date +%Y%m%d-%H%M%S)"
GRAFANA_DATA_DIR="/var/lib/grafana"
PROVISIONING_DIR="/etc/grafana/provisioning"

# Criar diretório de backup
mkdir -p "$BACKUP_DIR"

echo "Iniciando backup do Grafana..."

# 1. Backup das configurações de provisioning
echo "Backup das configurações de provisioning..."
cp -r "$PROVISIONING_DIR" "$BACKUP_DIR/provisioning"

# 2. Backup dos dados do Grafana
echo "Backup dos dados do Grafana..."
cp -r "$GRAFANA_DATA_DIR" "$BACKUP_DIR/grafana-data"

# 3. Backup via API
echo "Backup via API..."
mkdir -p "$BACKUP_DIR/api-export"

# Backup de data sources
echo "Exportando data sources..."
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/datasources" > \
     "$BACKUP_DIR/api-export/datasources.json"

# Backup de dashboards
echo "Exportando dashboards..."
mkdir -p "$BACKUP_DIR/api-export/dashboards"
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/search?type=dash-db" | \
     jq -r '.[] | .uid' | \
while read uid; do
    echo "Exportando dashboard: $uid"
    curl -H "Authorization: Bearer $API_KEY" \
         "$GRAFANA_URL/api/dashboards/uid/$uid" > \
         "$BACKUP_DIR/api-export/dashboards/$uid.json"
done

# Backup de folders
echo "Exportando folders..."
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/folders" > \
     "$BACKUP_DIR/api-export/folders.json"

# Backup de alert rules
echo "Exportando alert rules..."
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/ruler/grafana/api/v1/rules" > \
     "$BACKUP_DIR/api-export/alert-rules.json"

# Backup de contact points
echo "Exportando contact points..."
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/alertmanager/grafana/config" > \
     "$BACKUP_DIR/api-export/alertmanager-config.json"

# Backup de users (se admin)
echo "Exportando users..."
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/users" > \
     "$BACKUP_DIR/api-export/users.json" 2>/dev/null || echo "Sem permissão para exportar users"

# Backup de organizations
echo "Exportando organizations..."
curl -H "Authorization: Bearer $API_KEY" \
     "$GRAFANA_URL/api/orgs" > \
     "$BACKUP_DIR/api-export/organizations.json" 2>/dev/null || echo "Sem permissão para exportar orgs"

# Criar arquivo de metadados
echo "Criando metadados do backup..."
cat > "$BACKUP_DIR/metadata.json" << EOF
{
  "backup_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "grafana_version": "$(curl -s $GRAFANA_URL/api/health | jq -r .version)",
  "backup_type": "full",
  "grafana_url": "$GRAFANA_URL"
}
EOF

# Compactar backup
echo "Compactando backup..."
tar -czf "$BACKUP_DIR.tar.gz" -C "$(dirname $BACKUP_DIR)" "$(basename $BACKUP_DIR)"
rm -rf "$BACKUP_DIR"

echo "Backup concluído: $BACKUP_DIR.tar.gz"
echo "Tamanho do backup: $(du -h $BACKUP_DIR.tar.gz | cut -f1)"
```

### 8.2 Script de Restore

**restore-grafana.sh:**
```bash
#!/bin/bash
# Script de restore do Grafana

set -e

# Parâmetros
BACKUP_FILE="$1"
GRAFANA_URL="http://localhost:3000"
API_KEY="your-api-key"
RESTORE_DIR="./restore-temp"

if [ -z "$BACKUP_FILE" ]; then
    echo "Uso: $0 <backup-file.tar.gz>"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Arquivo de backup não encontrado: $BACKUP_FILE"
    exit 1
fi

echo "Iniciando restore do Grafana..."
echo "Backup file: $BACKUP_FILE"

# Extrair backup
echo "Extraindo backup..."
rm -rf "$RESTORE_DIR"
mkdir -p "$RESTORE_DIR"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR" --strip-components=1

# Verificar metadados
if [ -f "$RESTORE_DIR/metadata.json" ]; then
    echo "Metadados do backup:"
    cat "$RESTORE_DIR/metadata.json" | jq .
fi

# Função para aguardar Grafana estar pronto
wait_for_grafana() {
    echo "Aguardando Grafana estar pronto..."
    for i in {1..30}; do
        if curl -s "$GRAFANA_URL/api/health" > /dev/null; then
            echo "Grafana está pronto!"
            return 0
        fi
        echo "Tentativa $i/30..."
        sleep 2
    done
    echo "Grafana não respondeu após 60 segundos"
    exit 1
}

# 1. Restore de data sources
if [ -f "$RESTORE_DIR/api-export/datasources.json" ]; then
    echo "Restaurando data sources..."
    jq -c '.[]' "$RESTORE_DIR/api-export/datasources.json" | while read datasource; do
        name=$(echo "$datasource" | jq -r '.name')
        echo "Restaurando data source: $name"
        
        # Remover campos que não devem ser enviados
        clean_datasource=$(echo "$datasource" | jq 'del(.id, .version)')
        
        curl -X POST \
             -H "Authorization: Bearer $API_KEY" \
             -H "Content-Type: application/json" \
             -d "$clean_datasource" \
             "$GRAFANA_URL/api/datasources" || echo "Falha ao restaurar $name"
    done
fi

# 2. Restore de folders
if [ -f "$RESTORE_DIR/api-export/folders.json" ]; then
    echo "Restaurando folders..."
    jq -c '.[]' "$RESTORE_DIR/api-export/folders.json" | while read folder; do
        title=$(echo "$folder" | jq -r '.title')
        echo "Restaurando folder: $title"
        
        clean_folder=$(echo "$folder" | jq 'del(.id, .version)')
        
        curl -X POST \
             -H "Authorization: Bearer $API_KEY" \
             -H "Content-Type: application/json" \
             -d "$clean_folder" \
             "$GRAFANA_URL/api/folders" || echo "Falha ao restaurar folder $title"
    done
fi

# 3. Restore de dashboards
if [ -d "$RESTORE_DIR/api-export/dashboards" ]; then
    echo "Restaurando dashboards..."
    for dashboard_file in "$RESTORE_DIR/api-export/dashboards"/*.json; do
        if [ -f "$dashboard_file" ]; then
            dashboard_uid=$(basename "$dashboard_file" .json)
            echo "Restaurando dashboard: $dashboard_uid"
            
            # Extrair apenas o dashboard do JSON
            dashboard_data=$(jq '.dashboard' "$dashboard_file")
            
            # Criar payload para import
            import_payload=$(jq -n --argjson dashboard "$dashboard_data" '{
                dashboard: $dashboard,
                overwrite: true,
                inputs: []
            }')
            
            curl -X POST \
                 -H "Authorization: Bearer $API_KEY" \
                 -H "Content-Type: application/json" \
                 -d "$import_payload" \
                 "$GRAFANA_URL/api/dashboards/import" || echo "Falha ao restaurar dashboard $dashboard_uid"
        fi
    done
fi

# 4. Restore de alert rules
if [ -f "$RESTORE_DIR/api-export/alert-rules.json" ]; then
    echo "Restaurando alert rules..."
    # Implementar restore de alert rules conforme necessário
    echo "Alert rules backup encontrado, mas restore manual pode ser necessário"
fi

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf "$RESTORE_DIR"

echo "Restore concluído!"
echo "Verifique o Grafana em: $GRAFANA_URL"
```

## 9. Exercícios Práticos

### Exercício 1: Setup Completo de Provisioning

**Objetivo:** Configurar provisioning completo do zero

**Tarefas:**
1. Criar estrutura de diretórios
2. Configurar data sources
3. Provisionar dashboards
4. Configurar alertas
5. Testar com Docker Compose

**Validação:**
```bash
# Verificar data sources
curl -H "Authorization: Bearer $API_KEY" \
     "http://localhost:3000/api/datasources" | jq .

# Verificar dashboards
curl -H "Authorization: Bearer $API_KEY" \
     "http://localhost:3000/api/search" | jq .

# Verificar alertas
curl -H "Authorization: Bearer $API_KEY" \
     "http://localhost:3000/api/ruler/grafana/api/v1/rules" | jq .
```

### Exercício 2: CI/CD Pipeline

**Objetivo:** Implementar pipeline de deploy automatizado

**Componentes:**
- Validação de configurações
- Deploy para staging
- Testes automatizados
- Deploy para produção

### Exercício 3: Backup e Disaster Recovery

**Objetivo:** Implementar estratégia completa de backup

**Cenário:**
1. Configurar backup automático diário
2. Simular falha do Grafana
3. Executar restore completo
4. Validar integridade dos dados

## 10. Resumo do Módulo

### Conceitos Aprendidos

- ✅ **Provisioning Structure**: Organização e estrutura de arquivos
- ✅ **Data Sources**: Configuração automática de fontes de dados
- ✅ **Dashboards**: Provisioning e templates de dashboards
- ✅ **Alerting**: Automação de regras e notificações
- ✅ **CI/CD**: Integração com pipelines de deploy
- ✅ **Backup/Restore**: Estratégias de backup e recuperação

### Próximos Passos

- **Módulo 08**: Troubleshooting e diagnóstico
- **Módulo 09**: Projeto final integrado

### Recursos Adicionais

- [Grafana Provisioning Documentation](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [Configuration Management](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/)
- [API Reference](https://grafana.com/docs/grafana/latest/http_api/)

---

**Navegação:**
- [← Módulo 06: Alertas](06-alertas.md)
- [→ Módulo 08: Troubleshooting](08-troubleshooting.md)
- [🏠 Início](../README.md)
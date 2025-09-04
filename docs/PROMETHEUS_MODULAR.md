# Configuração Modular do Prometheus

## Visão Geral

A configuração modular do Prometheus permite separar diferentes aspectos da configuração em arquivos independentes, melhorando a manutenibilidade, escalabilidade e organização da stack de observabilidade.

## Benefícios da Modularização

### 1. **Manutenibilidade Aprimorada**
- Cada equipe pode manter seus próprios arquivos de configuração
- Mudanças isoladas não afetam outras configurações
- Facilita debugging e troubleshooting

### 2. **Escalabilidade**
- Adicionar novos grupos de hosts sem editar `prometheus.yml` principal
- Crescimento incremental da infraestrutura
- Suporte a ambientes multi-tenant

### 3. **Organização**
- Separação lógica por função (targets, rules, alerting)
- Estrutura de diretórios clara e intuitiva
- Versionamento granular de configurações

### 4. **Validação Incremental**
- `promtool check config` não quebra tudo se apenas um arquivo secundário tiver erro
- Validação independente de regras e targets
- Rollback mais seguro e controlado

## Estrutura de Diretórios

```
prometheus/
├── prometheus.yml          # Configuração principal
├── rules/                  # Regras de alerting
│   ├── general.yml        # Regras gerais (InstanceDown, CPU, Memory)
│   ├── docker.yml         # Regras específicas do Docker
│   └── snmp.yml           # Regras para dispositivos SNMP
├── targets/               # Grupos de hosts
│   ├── node-exporters.yml # Servidores Linux/Windows
│   ├── cadvisor.yml       # Containers Docker
│   └── snmp-switches.yml  # Switches e dispositivos de rede
└── alertmanager/
    ├── alertmanager.yml   # Configuração principal
    └── receivers.d/       # Receivers modulares
        ├── n8n.yml        # Webhook para n8n
        ├── email.yml      # Notificações por email
        └── teams.yml      # Microsoft Teams
```

## 1. Prometheus - Configuração Principal

### Como o Prometheus Carrega Configurações

O Prometheus carrega a configuração principal (`prometheus.yml`) e pode referenciar:
- **`rule_files`**: Lista de arquivos contendo regras de alerting
- **`file_sd_configs`**: Service discovery baseado em arquivos
- **Includes dinâmicos**: Carregamento automático de diretórios

### Exemplo: prometheus.yml Modular

```yaml
# Configuração global
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    region: 'us-east-1'

# Configuração do Alertmanager
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
      timeout: 10s
      api_version: v2

# Carregamento de regras modulares
rule_files:
  - "/etc/prometheus/rules/*.yml"
  - "/etc/prometheus/rules/**/*.yml"

# Configurações de scraping modulares
scrape_configs:
  # Node Exporters (servidores)
  - job_name: 'node-exporters'
    file_sd_configs:
      - files:
          - '/etc/prometheus/targets/node-exporters.yml'
        refresh_interval: 30s
    scrape_interval: 15s
    metrics_path: /metrics
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
      - source_labels: [__meta_filepath]
        target_label: config_file

  # cAdvisor (containers)
  - job_name: 'cadvisor'
    file_sd_configs:
      - files:
          - '/etc/prometheus/targets/cadvisor.yml'
        refresh_interval: 30s
    scrape_interval: 30s
    metrics_path: /metrics

  # SNMP Exporter (dispositivos de rede)
  - job_name: 'snmp-switches'
    file_sd_configs:
      - files:
          - '/etc/prometheus/targets/snmp-switches.yml'
        refresh_interval: 60s
    scrape_interval: 60s
    metrics_path: /snmp
    params:
      module: [if_mib]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116

  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 15s

  # Alertmanager monitoring
  - job_name: 'alertmanager'
    static_configs:
      - targets: ['alertmanager:9093']
    scrape_interval: 15s
```

## 2. Grupos de Hosts (Targets)

### Estrutura dos Arquivos de Targets

Cada arquivo em `targets/` define um grupo específico de hosts com suas labels e configurações.

### Exemplo: targets/node-exporters.yml

```yaml
# Servidores Linux/Windows com Node Exporter
- targets:
    - '10.0.1.10:9100'  # web-server-01
    - '10.0.1.11:9100'  # web-server-02
    - '10.0.1.20:9100'  # db-server-01
  labels:
    environment: 'production'
    team: 'infrastructure'
    service: 'web'
    datacenter: 'dc1'

- targets:
    - '10.0.2.10:9100'  # app-server-01
    - '10.0.2.11:9100'  # app-server-02
  labels:
    environment: 'production'
    team: 'backend'
    service: 'api'
    datacenter: 'dc1'

- targets:
    - '10.0.3.10:9182'  # windows-server-01 (Windows Exporter)
    - '10.0.3.11:9182'  # windows-server-02
  labels:
    environment: 'production'
    team: 'infrastructure'
    service: 'windows'
    datacenter: 'dc1'
    os: 'windows'
```

### Exemplo: targets/cadvisor.yml

```yaml
# Hosts Docker com cAdvisor
- targets:
    - '10.0.1.10:8080'  # docker-host-01
    - '10.0.1.11:8080'  # docker-host-02
    - '10.0.1.12:8080'  # docker-host-03
  labels:
    environment: 'production'
    team: 'platform'
    service: 'containers'
    datacenter: 'dc1'
    container_runtime: 'docker'

- targets:
    - '10.0.2.20:8080'  # k8s-node-01
    - '10.0.2.21:8080'  # k8s-node-02
  labels:
    environment: 'production'
    team: 'platform'
    service: 'kubernetes'
    datacenter: 'dc1'
    container_runtime: 'containerd'
```

### Exemplo: targets/snmp-switches.yml

```yaml
# Switches e dispositivos de rede
- targets:
    - '10.0.0.1'  # core-switch-01
    - '10.0.0.2'  # core-switch-02
  labels:
    environment: 'production'
    team: 'network'
    device_type: 'switch'
    vendor: 'cisco'
    model: 'catalyst-3850'
    datacenter: 'dc1'
    snmp_module: 'cisco_ios'

- targets:
    - '10.0.0.10'  # access-switch-01
    - '10.0.0.11'  # access-switch-02
    - '10.0.0.12'  # access-switch-03
  labels:
    environment: 'production'
    team: 'network'
    device_type: 'switch'
    vendor: 'ubiquiti'
    model: 'unifi-switch'
    datacenter: 'dc1'
    snmp_module: 'unifi'

- targets:
    - '10.0.0.254'  # firewall-01
  labels:
    environment: 'production'
    team: 'security'
    device_type: 'firewall'
    vendor: 'pfsense'
    model: 'sg-3100'
    datacenter: 'dc1'
    snmp_module: 'pfsense'
```

## 3. Rule Files (Regras de Alerting)

### Separação Temática de Regras

As regras são organizadas por domínio/função para facilitar manutenção e responsabilidade.

### Exemplo: rules/general.yml

```yaml
groups:
  - name: general.rules
    interval: 30s
    rules:
      # Instância down
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Instância {{ $labels.instance }} está down"
          description: "A instância {{ $labels.instance }} do job {{ $labels.job }} está down há mais de 1 minuto."
          runbook_url: "https://wiki.company.com/runbooks/instance-down"

      # CPU alto
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "CPU alto na instância {{ $labels.instance }}"
          description: "CPU usage está em {{ $value }}% na instância {{ $labels.instance }}."
          runbook_url: "https://wiki.company.com/runbooks/high-cpu"

      # Memória alta
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "Memória alta na instância {{ $labels.instance }}"
          description: "Memory usage está em {{ $value }}% na instância {{ $labels.instance }}."
          runbook_url: "https://wiki.company.com/runbooks/high-memory"

      # Disco cheio
      - alert: DiskSpaceLow
        expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 90
        for: 2m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Espaço em disco baixo na instância {{ $labels.instance }}"
          description: "Filesystem {{ $labels.mountpoint }} está {{ $value }}% cheio na instância {{ $labels.instance }}."
          runbook_url: "https://wiki.company.com/runbooks/disk-space"
```

### Exemplo: rules/docker.yml

```yaml
groups:
  - name: docker.rules
    interval: 30s
    rules:
      # Container restarts frequentes
      - alert: ContainerHighRestartRate
        expr: rate(container_start_time_seconds[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "Container {{ $labels.name }} reiniciando frequentemente"
          description: "Container {{ $labels.name }} na instância {{ $labels.instance }} está reiniciando {{ $value }} vezes por segundo."

      # Container com CPU alto
      - alert: ContainerHighCPU
        expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "Container {{ $labels.name }} com CPU alto"
          description: "Container {{ $labels.name }} está usando {{ $value }}% de CPU."

      # Container com memória alta
      - alert: ContainerHighMemory
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 90
        for: 5m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "Container {{ $labels.name }} com memória alta"
          description: "Container {{ $labels.name }} está usando {{ $value }}% da memória limite."

      # Container down
      - alert: ContainerDown
        expr: container_last_seen < (time() - 60)
        for: 1m
        labels:
          severity: critical
          team: platform
        annotations:
          summary: "Container {{ $labels.name }} está down"
          description: "Container {{ $labels.name }} não está respondendo há mais de 1 minuto."
```

### Exemplo: rules/snmp.yml

```yaml
groups:
  - name: snmp.rules
    interval: 60s
    rules:
      # Dispositivo SNMP down
      - alert: SNMPDeviceDown
        expr: up{job="snmp-switches"} == 0
        for: 2m
        labels:
          severity: critical
          team: network
        annotations:
          summary: "Dispositivo SNMP {{ $labels.instance }} está down"
          description: "O dispositivo {{ $labels.instance }} não está respondendo ao SNMP há mais de 2 minutos."
          runbook_url: "https://wiki.company.com/runbooks/snmp-device-down"

      # Interface down
      - alert: InterfaceDown
        expr: ifOperStatus{job="snmp-switches"} == 2
        for: 1m
        labels:
          severity: warning
          team: network
        annotations:
          summary: "Interface {{ $labels.ifDescr }} down no dispositivo {{ $labels.instance }}"
          description: "A interface {{ $labels.ifDescr }} no dispositivo {{ $labels.instance }} está down."

      # Erros de interface altos
      - alert: HighInterfaceErrors
        expr: rate(ifInErrors[5m]) + rate(ifOutErrors[5m]) > 10
        for: 5m
        labels:
          severity: warning
          team: network
        annotations:
          summary: "Erros altos na interface {{ $labels.ifDescr }}"
          description: "Interface {{ $labels.ifDescr }} no dispositivo {{ $labels.instance }} tem {{ $value }} erros por segundo."

      # Utilização de interface alta
      - alert: HighInterfaceUtilization
        expr: (rate(ifInOctets[5m]) + rate(ifOutOctets[5m])) * 8 / ifSpeed * 100 > 80
        for: 10m
        labels:
          severity: warning
          team: network
        annotations:
          summary: "Utilização alta na interface {{ $labels.ifDescr }}"
          description: "Interface {{ $labels.ifDescr }} no dispositivo {{ $labels.instance }} está {{ $value }}% utilizada."
```

## 4. Alertmanager Modular

### Estrutura Modular do Alertmanager

O Alertmanager pode ser configurado de forma modular usando includes para receivers e rotas.

### Exemplo: alertmanager.yml Principal

```yaml
# Configuração global
global:
  smtp_smarthost: 'smtp.company.com:587'
  smtp_from: 'alerts@company.com'
  smtp_auth_username: 'alerts@company.com'
  smtp_auth_password_file: '/etc/alertmanager/smtp_password'
  resolve_timeout: 5m

# Templates customizados
templates:
  - '/etc/alertmanager/templates/*.tmpl'

# Roteamento principal
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  routes:
    # Alertas críticos para n8n (automação)
    - match:
        severity: critical
      receiver: 'n8n-webhook'
      group_wait: 5s
      repeat_interval: 30m
      continue: true

    # Alertas de infraestrutura para equipe de infra
    - match:
        team: infrastructure
      receiver: 'infra-team'
      group_by: ['alertname', 'instance']

    # Alertas de rede para equipe de rede
    - match:
        team: network
      receiver: 'network-team'
      group_by: ['alertname', 'device_type']

    # Alertas de plataforma para equipe de platform
    - match:
        team: platform
      receiver: 'platform-team'
      group_by: ['alertname', 'container_name']

# Receivers modulares
receivers:
  - name: 'default'
    webhook_configs:
      - url: 'http://n8n:5678/webhook/alerts-default'
        send_resolved: true

  - name: 'n8n-webhook'
    webhook_configs:
      - url: 'http://n8n:5678/webhook/alerts-critical'
        send_resolved: true
        http_config:
          bearer_token_file: '/etc/alertmanager/n8n_token'
        title: 'Alerta Crítico - {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          **Alerta:** {{ .Annotations.summary }}
          **Descrição:** {{ .Annotations.description }}
          **Severidade:** {{ .Labels.severity }}
          **Instância:** {{ .Labels.instance }}
          **Status:** {{ .Status }}
          {{ end }}

  - name: 'infra-team'
    email_configs:
      - to: 'infra-team@company.com'
        subject: '[INFRA] {{ .GroupLabels.alertname }} - {{ .Status }}'
        body: |
          {{ range .Alerts }}
          Alerta: {{ .Annotations.summary }}
          Descrição: {{ .Annotations.description }}
          Instância: {{ .Labels.instance }}
          Severidade: {{ .Labels.severity }}
          {{ end }}
    webhook_configs:
      - url: 'http://n8n:5678/webhook/alerts-infra'
        send_resolved: true

  - name: 'network-team'
    email_configs:
      - to: 'network-team@company.com'
        subject: '[NETWORK] {{ .GroupLabels.alertname }} - {{ .Status }}'
    webhook_configs:
      - url: 'https://company.webhook.office.com/webhookb2/teams-network'
        send_resolved: true
        title: 'Alerta de Rede'
        text: |
          {{ range .Alerts }}
          **Dispositivo:** {{ .Labels.instance }}
          **Tipo:** {{ .Labels.device_type }}
          **Alerta:** {{ .Annotations.summary }}
          **Status:** {{ .Status }}
          {{ end }}

  - name: 'platform-team'
    email_configs:
      - to: 'platform-team@company.com'
        subject: '[PLATFORM] {{ .GroupLabels.alertname }} - {{ .Status }}'
    webhook_configs:
      - url: 'http://n8n:5678/webhook/alerts-platform'
        send_resolved: true

# Regras de inibição
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']

  - source_match:
      alertname: 'InstanceDown'
    target_match_re:
      alertname: '(HighCPUUsage|HighMemoryUsage|DiskSpaceLow)'
    equal: ['instance']
```

## 5. Grafana - Provisioning Modular

### Estrutura de Provisioning

```
grafana/provisioning/
├── datasources/
│   ├── prometheus.yaml
│   ├── alertmanager.yaml
│   └── loki.yaml
└── dashboards/
    ├── default.yaml
    ├── infrastructure.yaml
    ├── network.yaml
    └── applications.yaml
```

### Exemplo: datasources/prometheus.yaml

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
    jsonData:
      timeInterval: 15s
      queryTimeout: 60s
      httpMethod: POST
      exemplarTraceIdDestinations:
        - name: trace_id
          datasourceUid: jaeger
    version: 1

  - name: Prometheus-Infra
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    editable: false
    jsonData:
      timeInterval: 15s
      customQueryParameters: 'team=infrastructure'
    version: 1
```

### Exemplo: dashboards/infrastructure.yaml

```yaml
apiVersion: 1

providers:
  - name: 'infrastructure'
    orgId: 1
    folder: 'Infrastructure'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /etc/grafana/dashboards/infrastructure
      foldersFromFilesStructure: true
```

## 6. Comandos de Validação

### Validação do Prometheus

```bash
# Validar configuração principal
promtool check config prometheus.yml

# Validar regras específicas
promtool check rules rules/general.yml
promtool check rules rules/docker.yml
promtool check rules rules/snmp.yml

# Validar todas as regras
promtool check rules rules/*.yml

# Testar queries das regras
promtool query instant http://localhost:9090 'up'
promtool query range http://localhost:9090 'rate(container_cpu_usage_seconds_total[5m])' --start=2024-01-01T00:00:00Z --end=2024-01-01T01:00:00Z --step=60s

# Validar targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
```

### Validação do Alertmanager

```bash
# Validar configuração
amtool check-config alertmanager.yml

# Testar roteamento
amtool config routes --config.file=alertmanager.yml

# Simular alerta
amtool alert add --config.file=alertmanager.yml --alertmanager.url=http://localhost:9093 \
  alertname="TestAlert" \
  severity="warning" \
  instance="test-instance" \
  summary="Teste de alerta"

# Verificar silences
amtool silence query --config.file=alertmanager.yml --alertmanager.url=http://localhost:9093
```

### Scripts de Validação Automatizada

```bash
#!/bin/bash
# validate-config.sh

set -e

echo "=== Validando Configuração do Prometheus ==="
promtool check config prometheus.yml

echo "=== Validando Regras ==="
for rule_file in rules/*.yml; do
    echo "Validando $rule_file..."
    promtool check rules "$rule_file"
done

echo "=== Validando Targets ==="
for target_file in targets/*.yml; do
    echo "Validando sintaxe de $target_file..."
    python3 -c "import yaml; yaml.safe_load(open('$target_file'))"
done

echo "=== Validando Alertmanager ==="
amtool check-config alertmanager.yml

echo "=== Todas as validações passaram! ==="
```

## 7. Procedimentos de Atualização

### Hot Reload

```bash
# Reload Prometheus (sem reiniciar)
curl -X POST http://localhost:9090/-/reload

# Reload Alertmanager
curl -X POST http://localhost:9093/-/reload

# Verificar status após reload
curl -s http://localhost:9090/api/v1/status/config | jq '.status'
curl -s http://localhost:9093/api/v1/status | jq '.status'
```

### Workflow de Atualização Segura

```bash
#!/bin/bash
# update-config.sh

set -e

CONFIG_DIR="/etc/prometheus"
BACKUP_DIR="/backup/prometheus-$(date +%Y%m%d-%H%M%S)"

echo "=== Criando backup ==="
mkdir -p "$BACKUP_DIR"
cp -r "$CONFIG_DIR"/* "$BACKUP_DIR/"

echo "=== Validando nova configuração ==="
./validate-config.sh

echo "=== Aplicando configuração ==="
docker-compose exec prometheus kill -HUP 1

echo "=== Verificando saúde dos serviços ==="
sleep 5
curl -f http://localhost:9090/-/healthy
curl -f http://localhost:9093/-/healthy

echo "=== Atualização concluída com sucesso! ==="
echo "Backup salvo em: $BACKUP_DIR"
```

## 8. Monitoramento da Configuração

### Métricas de Configuração

```yaml
# Adicionar ao rules/prometheus-meta.yml
groups:
  - name: prometheus-meta.rules
    rules:
      - alert: PrometheusConfigReloadFailed
        expr: prometheus_config_last_reload_successful == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Falha no reload da configuração do Prometheus"
          description: "O último reload da configuração do Prometheus falhou."

      - alert: PrometheusRuleEvaluationFailures
        expr: rate(prometheus_rule_evaluation_failures_total[5m]) > 0
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Falhas na avaliação de regras do Prometheus"
          description: "{{ $value }} falhas por segundo na avaliação de regras."

      - alert: AlertmanagerConfigInconsistent
        expr: count by (job) (alertmanager_config_hash) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Configuração inconsistente do Alertmanager"
          description: "Múltiplas versões de configuração detectadas no cluster Alertmanager."
```

## 9. Troubleshooting

### Problemas Comuns

#### 1. Targets não aparecem
```bash
# Verificar sintaxe dos arquivos de targets
yaml-lint targets/*.yml

# Verificar permissões
ls -la targets/

# Verificar logs do Prometheus
docker-compose logs prometheus | grep -i "file_sd"
```

#### 2. Regras não carregam
```bash
# Validar sintaxe das regras
promtool check rules rules/*.yml

# Verificar se os arquivos estão no path correto
docker-compose exec prometheus ls -la /etc/prometheus/rules/

# Verificar logs de avaliação
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | select(.health != "ok")'
```

#### 3. Alertas não disparam
```bash
# Verificar se as regras estão ativas
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | select(.type == "alerting")'

# Verificar alertas ativos
curl -s http://localhost:9090/api/v1/alerts

# Testar query manualmente
curl -s "http://localhost:9090/api/v1/query?query=up==0"
```

## 10. Melhores Práticas

### Organização
- **Nomenclatura consistente**: Use prefixos claros (infra-, net-, app-)
- **Labels padronizadas**: environment, team, service, datacenter
- **Documentação inline**: Comentários explicativos nos YAMLs

### Performance
- **Intervalos otimizados**: Ajuste scrape_interval por tipo de serviço
- **Cardinality control**: Evite labels com alta cardinalidade
- **Retention policies**: Configure retenção adequada por importância

### Segurança
- **Secrets management**: Use arquivos externos para senhas
- **Network segmentation**: Isole componentes por função
- **Access control**: Implemente RBAC no Grafana

### Manutenção
- **Versionamento**: Use Git para controlar mudanças
- **Testing**: Valide configurações antes de aplicar
- **Monitoring**: Monitore a própria stack de observabilidade
- **Backup**: Mantenha backups regulares das configurações

---

## Conclusão

A configuração modular do Prometheus oferece:
- **Escalabilidade**: Crescimento incremental sem complexidade
- **Manutenibilidade**: Mudanças isoladas e seguras
- **Organização**: Estrutura clara e responsabilidades definidas
- **Confiabilidade**: Validação incremental e rollback seguro

Esta abordagem é essencial para ambientes de produção que precisam de flexibilidade, confiabilidade e facilidade de manutenção.
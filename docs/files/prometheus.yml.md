# Documentação: prometheus.yml

## Visão Geral

O arquivo `prometheus.yml` é o arquivo de configuração principal do Prometheus, definindo como o servidor coleta, processa e armazena métricas. Esta configuração está otimizada para um ambiente de produção com foco em performance, confiabilidade e escalabilidade.

## Estrutura da Configuração

### 1. Configurações Globais

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
```

**Parâmetros:**
- **scrape_interval**: Intervalo padrão entre coletas (15 segundos)
- **evaluation_interval**: Frequência de avaliação de regras de alerta
- **scrape_timeout**: Timeout máximo para cada scrape

**Considerações:**
- 15s é um bom equilíbrio entre granularidade e performance
- Timeout de 10s evita scrapes lentos que impactem performance
- Intervalos menores aumentam precisão mas consomem mais recursos

### 2. Configuração de Alertas

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

**Características:**
- **Service Discovery**: Usa nome do container Docker
- **Alta Disponibilidade**: Suporta múltiplos Alertmanagers
- **Failover**: Automático entre instâncias disponíveis

**Configuração Avançada:**
```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
      timeout: 10s
      api_version: v2
      path_prefix: /
```

### 3. Arquivos de Regras

```yaml
rule_files:
  - "rules/*.yml"
  - "rules/*.yaml"
```

**Organização:**
- **Padrão Glob**: Carrega todos os arquivos .yml/.yaml da pasta rules
- **Modularidade**: Permite separar regras por categoria
- **Manutenibilidade**: Facilita organização e versionamento

**Estrutura Recomendada:**
```
rules/
├── 00-general.yml          # Alertas gerais de infraestrutura
├── 01-applications.yml     # Alertas específicos de aplicações
├── 02-network.yml          # Alertas de rede e SNMP
└── 03-custom.yml          # Alertas customizados
```

## Configurações de Scrape

### 1. Prometheus (Auto-monitoramento)

```yaml
- job_name: 'prometheus'
  static_configs:
    - targets: ['localhost:9090']
  scrape_interval: 15s
  metrics_path: /metrics
```

**Métricas Importantes:**
- `prometheus_tsdb_head_samples_appended_total`: Amostras inseridas
- `prometheus_config_last_reload_successful`: Status do último reload
- `prometheus_rule_evaluation_duration_seconds`: Performance das regras
- `prometheus_target_scrapes_exceeded_sample_limit_total`: Targets com muitas métricas

### 2. Node Exporter (Métricas do Sistema)

```yaml
- job_name: 'node-exporter'
  static_configs:
    - targets: ['node-exporter:9100']
  scrape_interval: 15s
  scrape_timeout: 10s
```

**Métricas Principais:**
- `node_cpu_seconds_total`: Uso de CPU por core
- `node_memory_MemAvailable_bytes`: Memória disponível
- `node_filesystem_avail_bytes`: Espaço disponível em disco
- `node_load1`, `node_load5`, `node_load15`: Load average
- `node_network_receive_bytes_total`: Tráfego de rede recebido
- `node_network_transmit_bytes_total`: Tráfego de rede enviado

**Configuração Avançada:**
```yaml
- job_name: 'node-exporter'
  static_configs:
    - targets: ['node-exporter:9100']
  scrape_interval: 15s
  scrape_timeout: 10s
  metric_relabel_configs:
    # Remove métricas desnecessárias para economizar espaço
    - source_labels: [__name__]
      regex: 'node_textfile_scrape_error|node_time_seconds'
      action: drop
```

### 3. cAdvisor (Métricas de Containers)

```yaml
- job_name: 'cadvisor'
  static_configs:
    - targets: ['cadvisor:8080']
  scrape_interval: 30s
  scrape_timeout: 15s
```

**Métricas Principais:**
- `container_cpu_usage_seconds_total`: Uso de CPU por container
- `container_memory_usage_bytes`: Uso de memória
- `container_network_receive_bytes_total`: Tráfego de rede
- `container_fs_usage_bytes`: Uso de filesystem
- `container_last_seen`: Última vez que o container foi visto

**Otimizações:**
```yaml
- job_name: 'cadvisor'
  static_configs:
    - targets: ['cadvisor:8080']
  scrape_interval: 30s  # Intervalo maior para reduzir carga
  scrape_timeout: 15s
  metric_relabel_configs:
    # Manter apenas containers nomeados
    - source_labels: [container_label_com_docker_compose_service]
      regex: ''
      action: drop
```

### 4. Windows Exporter (Opcional)

```yaml
- job_name: 'windows-exporter'
  static_configs:
    - targets: ['windows-host:9182']
  scrape_interval: 30s
  scrape_timeout: 15s
```

**Métricas Principais:**
- `windows_cpu_time_total`: Tempo de CPU
- `windows_memory_available_bytes`: Memória disponível
- `windows_logical_disk_free_bytes`: Espaço livre em disco
- `windows_service_state`: Estado dos serviços Windows
- `windows_system_system_up_time`: Uptime do sistema

### 5. SNMP Exporter (Dispositivos de Rede)

```yaml
- job_name: 'snmp-exporter'
  static_configs:
    - targets:
        - 192.168.1.1    # Router/Firewall
        - 192.168.1.10   # Switch principal
        - 192.168.1.20   # Access Point
  metrics_path: /snmp
  params:
    module: [if_mib]  # Módulo padrão para interfaces
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:9116
```

**Configuração Multi-Módulo:**
```yaml
# UniFi Access Points
- job_name: 'snmp-unifi'
  static_configs:
    - targets: ['192.168.1.20', '192.168.1.21']
  metrics_path: /snmp
  params:
    module: [unifi_ap]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:9116

# pfSense Firewall
- job_name: 'snmp-pfsense'
  static_configs:
    - targets: ['192.168.1.1']
  metrics_path: /snmp
  params:
    module: [pfsense]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:9116
```

## Service Discovery

### Docker Service Discovery

```yaml
- job_name: 'docker-containers'
  docker_sd_configs:
    - host: unix:///var/run/docker.sock
      refresh_interval: 30s
  relabel_configs:
    # Apenas containers com label prometheus.scrape=true
    - source_labels: [__meta_docker_container_label_prometheus_scrape]
      regex: 'true'
      action: keep
    # Usar porta customizada se definida
    - source_labels: [__meta_docker_container_label_prometheus_port]
      regex: '(.+)'
      target_label: __address__
      replacement: '${1}'
    # Usar path customizado se definido
    - source_labels: [__meta_docker_container_label_prometheus_path]
      regex: '(.+)'
      target_label: __metrics_path__
      replacement: '${1}'
```

### File-based Service Discovery

```yaml
- job_name: 'file-discovery'
  file_sd_configs:
    - files:
        - '/etc/prometheus/targets/*.json'
        - '/etc/prometheus/targets/*.yml'
      refresh_interval: 30s
```

**Exemplo de arquivo de targets:**
```json
[
  {
    "targets": ["app1:8080", "app2:8080"],
    "labels": {
      "job": "web-applications",
      "environment": "production"
    }
  }
]
```

## Configurações Avançadas

### 1. Relabeling

```yaml
relabel_configs:
  # Adicionar label de ambiente
  - target_label: environment
    replacement: production
  
  # Renomear instância para nome mais amigável
  - source_labels: [__meta_docker_container_name]
    regex: '/(.*)'
    target_label: container_name
    replacement: '${1}'
  
  # Filtrar apenas containers específicos
  - source_labels: [__meta_docker_container_label_monitoring]
    regex: 'enabled'
    action: keep
```

### 2. Metric Relabeling

```yaml
metric_relabel_configs:
  # Remover métricas com alta cardinalidade
  - source_labels: [__name__]
    regex: 'container_tasks_state|container_memory_failures_total'
    action: drop
  
  # Normalizar labels
  - source_labels: [container_label_com_docker_compose_service]
    target_label: service
  
  # Adicionar prefixo a métricas
  - source_labels: [__name__]
    regex: '(.*)'
    target_label: __name__
    replacement: 'mycompany_${1}'
```

### 3. Configurações de Performance

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
  
  # Configurações de performance
  external_labels:
    cluster: 'production'
    region: 'us-east-1'

# Configurações de storage
storage:
  tsdb:
    retention.time: 15d
    retention.size: 10GB
    wal-compression: true
```

## Monitoramento de Aplicações

### 1. Aplicações Web

```yaml
- job_name: 'web-applications'
  static_configs:
    - targets:
        - 'app1:8080'
        - 'app2:8080'
        - 'api:3000'
  scrape_interval: 15s
  metrics_path: /metrics
  scheme: http
```

### 2. Bancos de Dados

```yaml
# MySQL Exporter
- job_name: 'mysql'
  static_configs:
    - targets: ['mysql-exporter:9104']
  scrape_interval: 30s

# PostgreSQL Exporter
- job_name: 'postgresql'
  static_configs:
    - targets: ['postgres-exporter:9187']
  scrape_interval: 30s

# Redis Exporter
- job_name: 'redis'
  static_configs:
    - targets: ['redis-exporter:9121']
  scrape_interval: 30s
```

### 3. Message Queues

```yaml
# RabbitMQ
- job_name: 'rabbitmq'
  static_configs:
    - targets: ['rabbitmq:15692']
  scrape_interval: 30s

# Kafka
- job_name: 'kafka'
  static_configs:
    - targets: ['kafka-exporter:9308']
  scrape_interval: 30s
```

## Segurança

### 1. Autenticação Básica

```yaml
- job_name: 'secure-app'
  static_configs:
    - targets: ['secure-app:8080']
  basic_auth:
    username: monitoring
    password_file: /etc/prometheus/passwords/app.txt
```

### 2. TLS/HTTPS

```yaml
- job_name: 'https-app'
  static_configs:
    - targets: ['secure-app:8443']
  scheme: https
  tls_config:
    ca_file: /etc/prometheus/certs/ca.pem
    cert_file: /etc/prometheus/certs/client.pem
    key_file: /etc/prometheus/certs/client-key.pem
    insecure_skip_verify: false
```

### 3. Bearer Token

```yaml
- job_name: 'api-with-token'
  static_configs:
    - targets: ['api:8080']
  authorization:
    type: Bearer
    credentials_file: /etc/prometheus/tokens/api.token
```

## Troubleshooting

### 1. Validação da Configuração

```bash
# Verificar sintaxe
promtool check config prometheus.yml

# Verificar regras
promtool check rules rules/*.yml

# Testar query
promtool query instant 'up'
```

### 2. Reload da Configuração

```bash
# Via API (se --web.enable-lifecycle estiver habilitado)
curl -X POST http://localhost:9090/-/reload

# Via sinal
kill -HUP $(pidof prometheus)

# Via Docker
docker-compose exec prometheus kill -HUP 1
```

### 3. Debugging de Targets

```bash
# Verificar status dos targets
curl http://localhost:9090/api/v1/targets

# Verificar service discovery
curl http://localhost:9090/api/v1/targets/metadata
```

## Otimizações

### 1. Redução de Cardinalidade

```yaml
metric_relabel_configs:
  # Remover labels com alta cardinalidade
  - regex: 'container_label_.*'
    action: labeldrop
  
  # Agrupar valores similares
  - source_labels: [status_code]
    regex: '4..'
    target_label: status_class
    replacement: '4xx'
```

### 2. Sampling

```yaml
# Reduzir frequência para métricas menos críticas
- job_name: 'batch-jobs'
  static_configs:
    - targets: ['batch:8080']
  scrape_interval: 60s  # Menos frequente
  sample_limit: 1000    # Limitar número de amostras
```

### 3. Configuração de Memória

```yaml
# No docker-compose.yml
command:
  - '--storage.tsdb.retention.time=15d'
  - '--storage.tsdb.retention.size=10GB'
  - '--storage.tsdb.wal-compression'
  - '--query.max-concurrency=20'
  - '--query.max-samples=50000000'
```

## Melhores Práticas

### 1. Organização

- **Agrupe jobs por função**: infraestrutura, aplicações, rede
- **Use labels consistentes**: environment, service, team
- **Documente configurações customizadas**
- **Mantenha backup das configurações**

### 2. Performance

- **Monitore uso de recursos do Prometheus**
- **Configure retenção adequada**
- **Use relabeling para reduzir cardinalidade**
- **Monitore tempo de scrape dos targets**

### 3. Manutenção

- **Teste configurações em ambiente de desenvolvimento**
- **Use versionamento para mudanças**
- **Monitore logs do Prometheus**
- **Configure alertas para falhas de scrape**

### 4. Escalabilidade

- **Considere federação para múltiplos Prometheus**
- **Use service discovery quando possível**
- **Implemente sharding por função ou região**
- **Monitore crescimento dos dados**

Este arquivo é crítico para o funcionamento do Prometheus e deve ser mantido com cuidado especial, sempre testando mudanças antes de aplicar em produção.
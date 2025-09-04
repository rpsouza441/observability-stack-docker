# ⚙️ MÓDULO 03: ARQUIVO DE CONFIGURAÇÃO

> **Objetivo:** Dominar a configuração do prometheus.yml e suas seções principais  
> **Duração:** 60 minutos  
> **Nível:** Iniciante/Intermediário

---

## 🎯 O QUE VOCÊ VAI APRENDER

Neste módulo você irá:
- ✅ Entender a estrutura completa do prometheus.yml
- ✅ Configurar seções global, rule_files e alerting
- ✅ Dominar scrape_configs com diferentes cenários
- ✅ Usar service discovery e relabeling
- ✅ Implementar configurações avançadas de segurança

---

## 📋 ESTRUTURA DO PROMETHEUS.YML

### **🏗️ Visão Geral**

```yaml
# Estrutura completa do prometheus.yml
global:                    # Configurações globais
  # configurações padrão

rule_files:               # Arquivos de regras
  # lista de arquivos

alerting:                 # Configuração de alertas
  # alertmanagers

scrape_configs:           # Configuração de coleta
  # lista de jobs

remote_write:             # Escrita remota (opcional)
  # configurações de envio

remote_read:              # Leitura remota (opcional)
  # configurações de leitura
```

---

## 🌍 SEÇÃO GLOBAL

### **⚙️ Configurações Básicas**

```yaml
global:
  # Intervalo padrão para coleta de métricas
  scrape_interval: 15s
  
  # Timeout padrão para coleta
  scrape_timeout: 10s
  
  # Intervalo para avaliação de regras
  evaluation_interval: 15s
  
  # Labels externos (adicionados a todas as métricas)
  external_labels:
    cluster: 'production'
    datacenter: 'us-east-1'
    environment: 'prod'
    prometheus_replica: 'prometheus-01'
```

### **🔧 Configurações Avançadas**

```yaml
global:
  # Configurações básicas
  scrape_interval: 30s
  scrape_timeout: 10s
  evaluation_interval: 30s
  
  # Labels externos para identificação
  external_labels:
    cluster: 'k8s-prod'
    region: 'us-west-2'
    prometheus_replica: '{{ .Hostname }}'
  
  # Configurações de query
  query_log_file: '/prometheus/queries.log'
  
  # Configurações de body size
  body_size_limit: 0  # 0 = sem limite
  sample_limit: 0     # 0 = sem limite
  target_limit: 0     # 0 = sem limite
  label_limit: 0      # 0 = sem limite
  label_name_length_limit: 0
  label_value_length_limit: 0
```

### **💡 Boas Práticas para Global**

```yaml
# ✅ Configuração recomendada para produção
global:
  scrape_interval: 30s        # Não muito frequente
  scrape_timeout: 10s         # 1/3 do scrape_interval
  evaluation_interval: 30s    # Mesmo que scrape_interval
  
  external_labels:
    cluster: '{{ .CLUSTER_NAME }}'     # Variável de ambiente
    datacenter: '{{ .DATACENTER }}'    # Variável de ambiente
    prometheus_replica: '{{ .HOSTNAME }}'

# ❌ Configuração problemática
global:
  scrape_interval: 5s         # Muito frequente
  scrape_timeout: 15s         # Maior que scrape_interval
  evaluation_interval: 60s    # Muito diferente do scrape
```

---

## 📜 SEÇÃO RULE_FILES

### **📁 Configuração Básica**

```yaml
rule_files:
  - "rules/*.yml"              # Todos os arquivos .yml em rules/
  - "alerts/critical.yml"      # Arquivo específico
  - "alerts/warning.yml"
  - "recording/aggregations.yml"
```

### **🗂️ Organização Modular**

```yaml
rule_files:
  # Regras por severidade
  - "rules/critical/*.yml"
  - "rules/warning/*.yml"
  - "rules/info/*.yml"
  
  # Regras por serviço
  - "rules/infrastructure/*.yml"
  - "rules/applications/*.yml"
  - "rules/databases/*.yml"
  
  # Recording rules
  - "recording/*.yml"
```

### **📊 Exemplo de Estrutura de Arquivos**

```
rules/
├── critical/
│   ├── infrastructure.yml
│   ├── databases.yml
│   └── applications.yml
├── warning/
│   ├── performance.yml
│   ├── capacity.yml
│   └── availability.yml
├── info/
│   └── notifications.yml
recording/
├── infrastructure.yml
├── applications.yml
└── business.yml
```

---

## 🚨 SEÇÃO ALERTING

### **⚙️ Configuração Básica**

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - 'alertmanager:9093'
      timeout: 10s
      api_version: v2
```

### **🔧 Configuração Avançada**

```yaml
alerting:
  alert_relabel_configs:
    # Adicionar labels aos alertas
    - target_label: cluster
      replacement: 'production'
    
    # Remover labels sensíveis
    - regex: 'password|secret|key'
      action: labeldrop
  
  alertmanagers:
    # Alertmanager principal
    - static_configs:
        - targets:
          - 'alertmanager-01:9093'
          - 'alertmanager-02:9093'
      timeout: 10s
      api_version: v2
      path_prefix: '/alertmanager'
      scheme: https
      
      # Autenticação básica
      basic_auth:
        username: 'prometheus'
        password_file: '/etc/prometheus/alertmanager.password'
      
      # TLS
      tls_config:
        ca_file: '/etc/prometheus/ca.crt'
        cert_file: '/etc/prometheus/client.crt'
        key_file: '/etc/prometheus/client.key'
        insecure_skip_verify: false
    
    # Alertmanager de backup
    - kubernetes_sd_configs:
        - role: pod
          namespaces:
            names: ['monitoring']
      relabel_configs:
        - source_labels: [__meta_kubernetes_pod_label_app]
          action: keep
          regex: alertmanager
```

---

## 📊 SEÇÃO SCRAPE_CONFIGS

### **🎯 Job Básico**

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 30s
    scrape_timeout: 10s
    metrics_path: '/metrics'
    scheme: 'http'
```

### **🏷️ Labels Customizados**

```yaml
scrape_configs:
  - job_name: 'web-servers'
    static_configs:
      - targets:
          - 'web-01:9100'
          - 'web-02:9100'
        labels:
          tier: 'frontend'
          environment: 'production'
          datacenter: 'us-east-1'
      
      - targets:
          - 'web-03:9100'
          - 'web-04:9100'
        labels:
          tier: 'frontend'
          environment: 'production'
          datacenter: 'us-west-1'
```

### **🔐 Autenticação e TLS**

```yaml
scrape_configs:
  # Autenticação básica
  - job_name: 'secure-app'
    static_configs:
      - targets: ['secure-app:8080']
    basic_auth:
      username: 'monitoring'
      password_file: '/etc/prometheus/passwords/secure-app.txt'
    scheme: https
    tls_config:
      ca_file: '/etc/prometheus/ca.crt'
      insecure_skip_verify: false
  
  # Bearer token
  - job_name: 'api-service'
    static_configs:
      - targets: ['api:8080']
    authorization:
      type: Bearer
      credentials_file: '/etc/prometheus/tokens/api-service.token'
  
  # OAuth2
  - job_name: 'oauth-service'
    static_configs:
      - targets: ['oauth-service:8080']
    oauth2:
      client_id: 'prometheus-client'
      client_secret_file: '/etc/prometheus/oauth/client_secret'
      token_url: 'https://auth.example.com/oauth/token'
      scopes:
        - 'monitoring'
```

### **🎛️ Configurações Avançadas de Scraping**

```yaml
scrape_configs:
  - job_name: 'high-frequency-metrics'
    static_configs:
      - targets: ['fast-app:8080']
    
    # Configurações de timing
    scrape_interval: 5s
    scrape_timeout: 3s
    
    # Configurações de tamanho
    sample_limit: 10000
    target_limit: 100
    label_limit: 50
    label_name_length_limit: 200
    label_value_length_limit: 200
    body_size_limit: 10MB
    
    # Configurações de path e parâmetros
    metrics_path: '/custom/metrics'
    params:
      format: ['prometheus']
      debug: ['true']
    
    # Headers customizados
    headers:
      X-Prometheus-Scrape: 'true'
      User-Agent: 'Prometheus/2.45.0'
```

---

## 🔍 SERVICE DISCOVERY

### **☁️ Kubernetes Service Discovery**

```yaml
scrape_configs:
  # Descoberta de pods
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ['default', 'monitoring', 'kube-system']
    
    relabel_configs:
      # Manter apenas pods com annotation de scrape
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      
      # Usar porta da annotation ou padrão
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: (.+)
        replacement: ${1}
      
      # Usar path da annotation ou padrão
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      
      # Adicionar labels do Kubernetes
      - source_labels: [__meta_kubernetes_namespace]
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: kubernetes_pod_name
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: app
```

### **🐳 Docker Service Discovery**

```yaml
scrape_configs:
  - job_name: 'docker-containers'
    dockerswarm_sd_configs:
      - host: unix:///var/run/docker.sock
        role: tasks
        port: 8080
    
    relabel_configs:
      # Manter apenas containers com label de monitoramento
      - source_labels: [__meta_dockerswarm_service_label_prometheus_monitoring]
        action: keep
        regex: 'true'
      
      # Usar porta do label ou padrão
      - source_labels: [__meta_dockerswarm_service_label_prometheus_port]
        action: replace
        target_label: __address__
        regex: (.+)
        replacement: ${1}
      
      # Adicionar labels do Docker
      - source_labels: [__meta_dockerswarm_service_name]
        target_label: service_name
      - source_labels: [__meta_dockerswarm_service_label_environment]
        target_label: environment
```

### **☁️ AWS EC2 Service Discovery**

```yaml
scrape_configs:
  - job_name: 'aws-ec2'
    ec2_sd_configs:
      - region: us-east-1
        port: 9100
        filters:
          - name: tag:Environment
            values: ['production', 'staging']
          - name: tag:Monitoring
            values: ['enabled']
          - name: instance-state-name
            values: ['running']
    
    relabel_configs:
      # Usar IP privado
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '${1}:9100'
      
      # Adicionar tags como labels
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      - source_labels: [__meta_ec2_tag_Environment]
        target_label: environment
      - source_labels: [__meta_ec2_tag_Team]
        target_label: team
      - source_labels: [__meta_ec2_instance_type]
        target_label: instance_type
      - source_labels: [__meta_ec2_availability_zone]
        target_label: availability_zone
```

---

## 🏷️ RELABELING

### **🎯 Conceitos Básicos**

```yaml
relabel_configs:
  # Ações disponíveis:
  # - replace: substituir valor
  # - keep: manter apenas targets que fazem match
  # - drop: remover targets que fazem match
  # - labelmap: mapear labels
  # - labeldrop: remover labels
  # - labelkeep: manter apenas labels específicos
```

### **🔄 Exemplos Práticos**

```yaml
scrape_configs:
  - job_name: 'relabeling-examples'
    static_configs:
      - targets: ['app1:8080', 'app2:8080', 'db1:9100']
    
    relabel_configs:
      # 1. Filtrar apenas aplicações (não databases)
      - source_labels: [__address__]
        action: keep
        regex: 'app.*:.*'
      
      # 2. Extrair nome da aplicação do endereço
      - source_labels: [__address__]
        action: replace
        target_label: application
        regex: '([^:]+):.*'
        replacement: '${1}'
      
      # 3. Adicionar ambiente baseado no nome
      - source_labels: [application]
        action: replace
        target_label: environment
        regex: '.*-prod.*'
        replacement: 'production'
      
      # 4. Mapear labels do Kubernetes
      - regex: '__meta_kubernetes_pod_label_(.+)'
        action: labelmap
        replacement: 'k8s_${1}'
      
      # 5. Remover labels sensíveis
      - regex: '.*password.*|.*secret.*|.*key.*'
        action: labeldrop
      
      # 6. Manter apenas labels importantes
      - action: labelkeep
        regex: '__name__|job|instance|application|environment'
```

### **🎨 Relabeling Avançado**

```yaml
scrape_configs:
  - job_name: 'advanced-relabeling'
    kubernetes_sd_configs:
      - role: pod
    
    relabel_configs:
      # Construir endereço customizado
      - source_labels: [__meta_kubernetes_pod_ip, __meta_kubernetes_pod_container_port_number]
        action: replace
        target_label: __address__
        regex: '([^:]+);(.*)'
        replacement: '${1}:${2}'
      
      # Criar label composto
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_fqdn
        separator: '/'
        regex: '(.*)'
        replacement: '${1}'
      
      # Normalizar valores
      - source_labels: [__meta_kubernetes_pod_label_version]
        action: replace
        target_label: version
        regex: 'v?(.*)'
        replacement: '${1}'
      
      # Condicional baseado em múltiplos labels
      - source_labels: [__meta_kubernetes_pod_label_app, __meta_kubernetes_pod_label_component]
        action: replace
        target_label: service_type
        regex: 'web;frontend'
        replacement: 'web-frontend'
```

---

## 🔒 CONFIGURAÇÕES DE SEGURANÇA

### **🔐 Autenticação**

```yaml
scrape_configs:
  # Basic Auth
  - job_name: 'basic-auth-service'
    static_configs:
      - targets: ['secure-service:8080']
    basic_auth:
      username: 'prometheus'
      password_file: '/etc/prometheus/passwords/service.txt'
  
  # Bearer Token
  - job_name: 'token-auth-service'
    static_configs:
      - targets: ['api-service:8080']
    authorization:
      type: Bearer
      credentials_file: '/etc/prometheus/tokens/api.token'
  
  # OAuth2
  - job_name: 'oauth2-service'
    static_configs:
      - targets: ['oauth-service:8080']
    oauth2:
      client_id: 'prometheus'
      client_secret_file: '/etc/prometheus/oauth/secret'
      token_url: 'https://auth.company.com/oauth/token'
      endpoint_params:
        grant_type: 'client_credentials'
      scopes: ['monitoring', 'metrics']
```

### **🔒 TLS/SSL**

```yaml
scrape_configs:
  - job_name: 'tls-service'
    static_configs:
      - targets: ['secure-app:8443']
    scheme: https
    tls_config:
      # Certificados
      ca_file: '/etc/prometheus/tls/ca.crt'
      cert_file: '/etc/prometheus/tls/client.crt'
      key_file: '/etc/prometheus/tls/client.key'
      
      # Validação
      insecure_skip_verify: false
      server_name: 'secure-app.company.com'
      
      # Versões TLS permitidas
      min_version: 'TLS12'
      max_version: 'TLS13'
```

---

## 📤 REMOTE WRITE/READ

### **📤 Remote Write**

```yaml
remote_write:
  # Enviar para Thanos
  - url: 'http://thanos-receive:19291/api/v1/receive'
    name: 'thanos'
    remote_timeout: 30s
    
    # Configurações de queue
    queue_config:
      capacity: 10000
      max_shards: 200
      min_shards: 1
      max_samples_per_send: 2000
      batch_send_deadline: 5s
      min_backoff: 30ms
      max_backoff: 100ms
    
    # Filtros de métricas
    write_relabel_configs:
      # Enviar apenas métricas críticas
      - source_labels: [__name__]
        action: keep
        regex: 'up|.*_error_.*|.*_latency_.*'
  
  # Enviar para Cortex
  - url: 'https://cortex.company.com/api/v1/push'
    name: 'cortex'
    basic_auth:
      username: 'prometheus'
      password_file: '/etc/prometheus/cortex.password'
    
    # Headers customizados
    headers:
      X-Scope-OrgID: 'tenant-1'
```

### **📥 Remote Read**

```yaml
remote_read:
  - url: 'http://thanos-query:9090/api/v1/read'
    name: 'thanos-historical'
    remote_timeout: 1m
    
    # Filtros de leitura
    read_recent: false
    required_matchers:
      environment: 'production'
    
    # Headers
    headers:
      X-Tenant: 'production'
```

---

## 🧪 EXEMPLOS PRÁTICOS COMPLETOS

### **🏢 Ambiente Corporativo**

```yaml
# prometheus.yml para ambiente corporativo
global:
  scrape_interval: 30s
  evaluation_interval: 30s
  external_labels:
    cluster: 'prod-k8s'
    datacenter: 'us-east-1'
    prometheus_replica: 'prometheus-01'

rule_files:
  - 'rules/critical/*.yml'
  - 'rules/warning/*.yml'
  - 'recording/*.yml'

alerting:
  alertmanagers:
    - kubernetes_sd_configs:
        - role: service
          namespaces:
            names: ['monitoring']
      relabel_configs:
        - source_labels: [__meta_kubernetes_service_name]
          action: keep
          regex: alertmanager

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 15s
  
  # Kubernetes API Server
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names: ['default']
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    authorization:
      credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https
  
  # Node Exporter
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecure_skip_verify: true
    authorization:
      credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics
  
  # Application Pods
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

remote_write:
  - url: 'http://thanos-receive:19291/api/v1/receive'
    queue_config:
      max_samples_per_send: 1000
      batch_send_deadline: 5s
```

---

## ✅ VALIDAÇÃO E TROUBLESHOOTING

### **🔍 Comandos de Validação**

```bash
# Validar sintaxe do arquivo
promtool check config prometheus.yml

# Validar regras
promtool check rules rules/*.yml

# Testar queries
promtool query instant http://localhost:9090 'up'

# Verificar targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

### **🚨 Problemas Comuns**

```yaml
# ❌ Erro: Timeout maior que interval
scrape_configs:
  - job_name: 'bad-config'
    scrape_interval: 10s
    scrape_timeout: 15s    # ERRO: timeout > interval

# ✅ Correção
scrape_configs:
  - job_name: 'good-config'
    scrape_interval: 15s
    scrape_timeout: 10s    # OK: timeout < interval
```

```yaml
# ❌ Erro: Labels com caracteres inválidos
static_configs:
  - targets: ['app:8080']
    labels:
      app-name: 'my-app'     # ERRO: hífen em label name
      'service.type': 'web'  # ERRO: ponto em label name

# ✅ Correção
static_configs:
  - targets: ['app:8080']
    labels:
      app_name: 'my-app'     # OK: underscore
      service_type: 'web'    # OK: underscore
```

---

## 🎓 RESUMO DO MÓDULO

### **Conceitos Aprendidos:**
- ✅ **Estrutura completa:** Global, rule_files, alerting, scrape_configs
- ✅ **Service Discovery:** Kubernetes, Docker, AWS EC2
- ✅ **Relabeling:** Transformação e filtragem de labels
- ✅ **Segurança:** Autenticação, TLS, tokens
- ✅ **Remote Write/Read:** Integração com sistemas externos

### **Próximos Passos:**
1. 📊 **[Módulo 04: Coleta de Métricas](04-coleta-metricas.md)** - Exporters e targets
2. 🔍 **[Módulo 05: PromQL Básico](05-promql-basico.md)** - Linguagem de consulta
3. 🔍 **[Módulo 06: PromQL Avançado](06-promql-avancado.md)** - Funções complexas

---

**📚 Módulo Anterior:** [02 - Configuração Inicial](02-configuracao.md)  
**📚 Próximo Módulo:** [04 - Coleta de Métricas](04-coleta-metricas.md)  
**🏠 Voltar ao:** [README Principal](README.md)

---

*Módulo criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*
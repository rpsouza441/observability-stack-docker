# 🔧 MÓDULO 02: CONFIGURAÇÃO INICIAL

> **Objetivo:** Executar o Prometheus pela primeira vez e explorar a interface web  
> **Duração:** 45 minutos  
> **Nível:** Iniciante

---

## 🎯 O QUE VOCÊ VAI APRENDER

Neste módulo você irá:
- ✅ Executar o Prometheus usando Docker Compose
- ✅ Acessar e navegar pela interface web
- ✅ Fazer suas primeiras consultas PromQL
- ✅ Entender a estrutura de diretórios
- ✅ Verificar o status dos targets

---

## 📋 PRÉ-REQUISITOS

### **Ferramentas Necessárias:**
- 🐳 Docker Desktop ou Docker Engine
- 🐙 Docker Compose
- 🌐 Navegador web moderno
- 📝 Editor de texto

### **Verificação do Ambiente:**
```bash
# Verificar Docker
docker --version
# Saída esperada: Docker version 20.x.x

# Verificar Docker Compose
docker-compose --version
# Saída esperada: docker-compose version 1.29.x
```

---

## 🚀 PRIMEIRA EXECUÇÃO

### **1. 📁 Estrutura de Diretórios**

Crie a seguinte estrutura:
```
prometheus-lab/
├── docker-compose.yml
├── prometheus.yml
├── data/
└── rules/
    └── alerts.yml
```

```bash
# Criando estrutura
mkdir prometheus-lab
cd prometheus-lab
mkdir data rules
```

### **2. 🐳 Docker Compose**

Crie o arquivo `docker-compose.yml`:

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.45.0
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./rules:/etc/prometheus/rules:ro
      - ./data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    restart: unless-stopped
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:v1.6.1
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
```

### **3. ⚙️ Configuração Básica**

Crie o arquivo `prometheus.yml`:

```yaml
# Configuração global
global:
  scrape_interval: 15s          # Coleta métricas a cada 15 segundos
  evaluation_interval: 15s      # Avalia regras a cada 15 segundos
  external_labels:
    cluster: 'prometheus-lab'
    environment: 'development'

# Configuração de regras
rule_files:
  - "rules/*.yml"

# Configuração de alertas (será usado mais tarde)
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Configuração de coleta de métricas
scrape_configs:
  # Monitoramento do próprio Prometheus
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          service: 'prometheus'
          tier: 'monitoring'

  # Monitoramento do sistema (Node Exporter)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
        labels:
          service: 'node-exporter'
          tier: 'system'
    scrape_interval: 30s
    metrics_path: /metrics
```

### **4. 📊 Regras de Alerta Básicas**

Crie o arquivo `rules/alerts.yml`:

```yaml
groups:
  - name: basic-alerts
    rules:
      # Alerta se Prometheus estiver down
      - alert: PrometheusDown
        expr: up{job="prometheus"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Prometheus está down"
          description: "Prometheus não está respondendo há mais de 1 minuto."

      # Alerta se Node Exporter estiver down
      - alert: NodeExporterDown
        expr: up{job="node-exporter"} == 0
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Node Exporter está down"
          description: "Node Exporter na instância {{ $labels.instance }} está down."

      # Alerta de CPU alto
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "CPU usage alto"
          description: "CPU usage está em {{ $value }}% na instância {{ $labels.instance }}."
```

### **5. 🚀 Iniciando os Serviços**

```bash
# Iniciar em background
docker-compose up -d

# Verificar status
docker-compose ps

# Ver logs
docker-compose logs -f prometheus
```

**Saída esperada:**
```
Creating network "prometheus-lab_monitoring" with the default driver
Creating prometheus     ... done
Creating node-exporter  ... done
```

---

## 🌐 ACESSANDO A INTERFACE WEB

### **1. 🔗 URL de Acesso**
```
URL: http://localhost:9090
Usuário: Não requerido
Senha: Não requerida
```

### **2. 📱 Navegação Principal**

#### **🏠 Página Inicial**
- **Graph:** Interface para consultas PromQL
- **Alerts:** Visualização de alertas ativos
- **Status:** Informações sobre configuração e targets
- **Help:** Documentação e ajuda

#### **📊 Seção Graph**
```
Campos principais:
┌─────────────────────────────────────┐
│ Expression: [Campo para PromQL]     │
├─────────────────────────────────────┤
│ [Execute] [Add Panel]               │
├─────────────────────────────────────┤
│ 📈 Gráfico de resultado             │
├─────────────────────────────────────┤
│ 📋 Tabela de dados                  │
└─────────────────────────────────────┘
```

#### **🚨 Seção Alerts**
```
Estados dos alertas:
- 🟢 Inactive: Condição não atendida
- 🟡 Pending: Condição atendida, aguardando 'for'
- 🔴 Firing: Alerta ativo
```

#### **📋 Seção Status**
- **Targets:** Status de coleta de métricas
- **Configuration:** Configuração atual carregada
- **Rules:** Regras de alerta carregadas
- **Service Discovery:** Descoberta automática de serviços

---

## 🔍 PRIMEIRAS CONSULTAS

### **1. 📊 Consultas Básicas**

#### **Verificar se serviços estão UP:**
```promql
# Todos os targets
up

# Resultado esperado:
up{instance="localhost:9090", job="prometheus"} 1
up{instance="node-exporter:9100", job="node-exporter"} 1
```

#### **Métricas do Prometheus:**
```promql
# Número de amostras ingeridas por segundo
rate(prometheus_tsdb_symbol_table_size_bytes[5m])

# Uso de memória do Prometheus
process_resident_memory_bytes{job="prometheus"}

# Número de séries temporais
prometheus_tsdb_head_series
```

#### **Métricas do Sistema (Node Exporter):**
```promql
# CPU usage (invertido do idle)
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memória disponível em GB
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024

# Espaço em disco usado (%)
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100
```

### **2. 🎯 Exercícios Práticos**

#### **Exercício 1: Explorar Métricas**
```promql
# 1. Liste todas as métricas disponíveis
{__name__=~".+"}

# 2. Encontre métricas relacionadas a CPU
{__name__=~".*cpu.*"}

# 3. Veja métricas específicas do Node Exporter
{job="node-exporter"}
```

#### **Exercício 2: Filtros com Labels**
```promql
# 1. Métricas apenas do Prometheus
{job="prometheus"}

# 2. Métricas de uma instância específica
{instance="localhost:9090"}

# 3. Combinando múltiplos labels
{job="node-exporter", instance="node-exporter:9100"}
```

#### **Exercício 3: Funções Básicas**
```promql
# 1. Taxa de mudança (rate)
rate(prometheus_http_requests_total[5m])

# 2. Valor máximo
max(node_memory_MemTotal_bytes)

# 3. Agregação por job
sum by (job) (up)
```

---

## 📁 ESTRUTURA DE ARQUIVOS

### **1. 🗂️ Diretórios do Prometheus**

```
prometheus-lab/
├── docker-compose.yml          # Orquestração dos containers
├── prometheus.yml              # Configuração principal
├── data/                       # Dados da TSDB (persistente)
│   ├── chunks_head/
│   ├── wal/
│   └── queries.active
└── rules/                      # Regras de alerta
    └── alerts.yml
```

### **2. 💾 Diretório de Dados (data/)**

| Subdiretório | Descrição | Tamanho Típico |
|--------------|-----------|----------------|
| **chunks_head/** | Dados recentes em memória | 100MB - 1GB |
| **wal/** | Write-Ahead Log | 50MB - 500MB |
| **01ABCD.../** | Blocos de dados comprimidos | 1GB - 100GB |

### **3. 📊 Monitoramento do Armazenamento**

```promql
# Tamanho da base de dados
prometheus_tsdb_size_bytes

# Número de blocos
prometheus_tsdb_blocks_loaded

# Tempo de retenção configurado
prometheus_config_last_reload_success_timestamp_seconds
```

---

## ✅ VERIFICAÇÃO DE STATUS

### **1. 🎯 Status dos Targets**

Acesse: `http://localhost:9090/targets`

**Estados possíveis:**
- 🟢 **UP:** Target respondendo corretamente
- 🔴 **DOWN:** Target não acessível
- 🟡 **UNKNOWN:** Estado indeterminado

**Informações exibidas:**
```
Endpoint: http://node-exporter:9100/metrics
State: UP (1.234s ago)
Labels: instance="node-exporter:9100" job="node-exporter"
Last Scrape: 2025-01-15 10:30:45 UTC
Scrape Duration: 15.234ms
Error: (nenhum)
```

### **2. 📋 Verificação da Configuração**

Acesse: `http://localhost:9090/config`

**Validações importantes:**
- ✅ Sintaxe YAML correta
- ✅ Targets configurados corretamente
- ✅ Regras carregadas sem erro
- ✅ Intervalos de coleta apropriados

### **3. 🚨 Status das Regras**

Acesse: `http://localhost:9090/rules`

**Informações das regras:**
```
File: /etc/prometheus/rules/alerts.yml
Group: basic-alerts
Rules: 3 rules
Last Evaluation: 2025-01-15 10:30:45 UTC
Evaluation Time: 1.234ms
```

---

## 🛠️ COMANDOS ÚTEIS

### **1. 🐳 Gerenciamento Docker**

```bash
# Parar serviços
docker-compose down

# Reiniciar apenas o Prometheus
docker-compose restart prometheus

# Ver logs em tempo real
docker-compose logs -f

# Executar comando dentro do container
docker-compose exec prometheus sh
```

### **2. 🔄 Recarregar Configuração**

```bash
# Método 1: Sinal SIGHUP
docker-compose kill -s SIGHUP prometheus

# Método 2: API HTTP (se --web.enable-lifecycle estiver habilitado)
curl -X POST http://localhost:9090/-/reload

# Método 3: Reiniciar container
docker-compose restart prometheus
```

### **3. 🔍 Validação de Configuração**

```bash
# Validar prometheus.yml
docker run --rm -v $(pwd)/prometheus.yml:/prometheus.yml \
  prom/prometheus:v2.45.0 \
  promtool check config /prometheus.yml

# Validar regras
docker run --rm -v $(pwd)/rules:/rules \
  prom/prometheus:v2.45.0 \
  promtool check rules /rules/*.yml
```

---

## 🚨 TROUBLESHOOTING

### **1. ❌ Problemas Comuns**

#### **Prometheus não inicia:**
```bash
# Verificar logs
docker-compose logs prometheus

# Erros comuns:
# - Sintaxe YAML inválida
# - Porta já em uso
# - Permissões de arquivo
# - Volumes não montados
```

#### **Target DOWN:**
```bash
# Verificar conectividade
docker-compose exec prometheus wget -qO- http://node-exporter:9100/metrics

# Verificar se serviço está rodando
docker-compose ps

# Verificar logs do target
docker-compose logs node-exporter
```

#### **Interface web não carrega:**
```bash
# Verificar se porta está aberta
netstat -tlnp | grep 9090

# Verificar se container está rodando
docker ps | grep prometheus

# Testar acesso local
curl http://localhost:9090
```

### **2. 🔧 Soluções Rápidas**

```bash
# Limpar dados e reiniciar
docker-compose down
sudo rm -rf data/*
docker-compose up -d

# Verificar configuração antes de aplicar
docker run --rm -v $(pwd)/prometheus.yml:/prometheus.yml \
  prom/prometheus:v2.45.0 promtool check config /prometheus.yml

# Monitorar logs em tempo real
docker-compose logs -f --tail=50
```

---

## 🎯 EXERCÍCIOS PRÁTICOS

### **Exercício 1: Configuração Personalizada**
1. Modifique o `scrape_interval` para 30 segundos
2. Adicione um label customizado `datacenter: "local"`
3. Recarregue a configuração
4. Verifique se as mudanças foram aplicadas

### **Exercício 2: Exploração da Interface**
1. Execute 5 consultas PromQL diferentes
2. Explore todas as seções do menu Status
3. Identifique quantas métricas estão sendo coletadas
4. Verifique o tempo de última coleta de cada target

### **Exercício 3: Monitoramento Básico**
1. Crie uma consulta para monitorar CPU
2. Crie uma consulta para monitorar memória
3. Crie uma consulta para monitorar espaço em disco
4. Salve essas consultas para uso futuro

---

## 🎓 RESUMO DO MÓDULO

### **Conceitos Aprendidos:**
- ✅ **Docker Compose:** Orquestração de containers Prometheus
- ✅ **Interface Web:** Navegação e funcionalidades principais
- ✅ **PromQL Básico:** Primeiras consultas e filtros
- ✅ **Targets:** Verificação de status de coleta
- ✅ **Configuração:** Estrutura básica do prometheus.yml

### **Arquivos Criados:**
- 📄 `docker-compose.yml` - Orquestração dos serviços
- 📄 `prometheus.yml` - Configuração principal
- 📄 `rules/alerts.yml` - Regras básicas de alerta

### **Próximos Passos:**
1. 📝 **[Módulo 03: Arquivo de Configuração](03-arquivo-config.md)** - Detalhes do prometheus.yml
2. 📊 **[Módulo 04: Coleta de Métricas](04-coleta-metricas.md)** - Exporters e targets avançados
3. 🔍 **[Módulo 05: PromQL Básico](05-promql-basico.md)** - Linguagem de consulta

---

## 🔗 LINKS ÚTEIS

- **[Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)**
- **[Docker Hub - Prometheus](https://hub.docker.com/r/prom/prometheus)**
- **[Node Exporter](https://github.com/prometheus/node_exporter)**
- **[PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)**

---

**📚 Módulo Anterior:** [01 - Introdução](01-introducao.md)  
**📚 Próximo Módulo:** [03 - Arquivo de Configuração](03-arquivo-config.md)  
**🏠 Voltar ao:** [README Principal](README.md)

---

*Módulo criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*
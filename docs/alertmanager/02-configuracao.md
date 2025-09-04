# 🔧 ALERTMANAGER - CONFIGURAÇÃO PASSO A PASSO

> **Módulo 2:** Como configurar o Alertmanager do zero

---

## 📋 CONTEÚDO DESTE MÓDULO

1. [Primeira Execução](#1-primeira-execução)
2. [Estrutura de Arquivos](#2-estrutura-de-arquivos)
3. [Integração com Prometheus](#3-integração-com-prometheus)
4. [Verificação da Instalação](#4-verificação-da-instalação)

---

## 1. PRIMEIRA EXECUÇÃO

### 🚀 Passo 1: Iniciar o Alertmanager

```bash
# Iniciar o Alertmanager via Docker Compose
docker-compose up -d alertmanager

# Verificar se está rodando
docker-compose ps alertmanager

# Ver logs em tempo real
docker-compose logs -f alertmanager
```

**Saída esperada:**
```
alertmanager_1  | level=info ts=2024-01-15T10:00:00.000Z caller=main.go:175 msg="Starting Alertmanager" version="(version=0.25.0)"
alertmanager_1  | level=info ts=2024-01-15T10:00:00.001Z caller=main.go:176 build_context="(go=go1.19.4)"
alertmanager_1  | level=info ts=2024-01-15T10:00:00.002Z caller=cluster.go:161 component=cluster msg="setting advertise address explicitly" addr=172.18.0.4 port=9094
alertmanager_1  | level=info ts=2024-01-15T10:00:00.003Z caller=main.go:361 msg="Listening on address" address=:9093
```

### 🌐 Passo 2: Acessar a Interface Web

```
URL: http://localhost:9093
```

**O que você deve ver:**
- 🎛️ **Interface web do Alertmanager**
- 📊 **Aba "Alerts"** - mostra alertas ativos
- 🔇 **Aba "Silences"** - para gerenciar silenciamentos
- ⚙️ **Aba "Status"** - mostra configuração carregada

### 🔍 Passo 3: Verificar Status

```bash
# Verificar se a configuração foi carregada corretamente
curl http://localhost:9093/api/v2/status

# Verificar se há alertas ativos
curl http://localhost:9093/api/v2/alerts

# Verificar receivers configurados
curl http://localhost:9093/api/v2/receivers
```

---

## 2. ESTRUTURA DE ARQUIVOS

### 📁 Organização Recomendada

```
alerting/
├── alertmanager/
│   ├── alertmanager.yml        # ⚙️ Configuração principal
│   ├── templates/              # 📝 Templates personalizados
│   │   ├── email.tmpl
│   │   ├── slack.tmpl
│   │   └── webhook.tmpl
│   ├── data/                   # 💾 Dados persistentes
│   │   ├── silences
│   │   └── notifications
│   └── receivers.d/            # 📡 Receivers modulares (opcional)
│       ├── oncall.yml
│       ├── teams.yml
│       └── integrations.yml
└── prometheus/
    ├── prometheus.yml          # 🔗 Configuração do Prometheus
    └── rules/                  # 📏 Regras de alerta
        ├── infrastructure.yml
        ├── application.yml
        └── network.yml
```

### 📄 Arquivo Principal: alertmanager.yml

```yaml
# alertmanager.yml - Configuração mínima funcional
global:
  # Configurações SMTP básicas
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alertmanager@localhost'
  resolve_timeout: 5m

# Roteamento simples
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

# Receiver básico (webhook de teste)
receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://localhost:5001/'
        send_resolved: true
```

### 🐳 Configuração Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  alertmanager:
    image: prom/alertmanager:v0.25.0
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - ./alertmanager/templates:/etc/alertmanager/templates
      - alertmanager-data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
      - '--cluster.advertise-address=0.0.0.0:9093'
    restart: unless-stopped
    networks:
      - monitoring

volumes:
  alertmanager-data:

networks:
  monitoring:
    driver: bridge
```

---

## 3. INTEGRAÇÃO COM PROMETHEUS

### 🔗 Configurar Prometheus para Enviar Alertas

No arquivo `prometheus.yml`, adicione:

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# ⚠️ CONFIGURAÇÃO DE ALERTING
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - "alertmanager:9093"    # 🎯 Endereço do Alertmanager
      timeout: 10s              # ⏱️ Timeout para envio
      api_version: v2           # 📡 Versão da API (v1 ou v2)
      path_prefix: /            # 🛤️ Prefixo do caminho

# 📏 REGRAS DE ALERTA
rule_files:
  - "rules/*.yml"

# 🎯 TARGETS PARA MONITORAR
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'alertmanager'
    static_configs:
      - targets: ['alertmanager:9093']
```

### 📏 Criar Regra de Alerta de Teste

```yaml
# rules/test-alerts.yml
groups:
  - name: test-alerts
    rules:
      - alert: PrometheusTargetDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Target {{ $labels.instance }} is down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute."
      
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.8
        for: 5m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 80% on {{ $labels.instance }}"
```

### 🔄 Reiniciar Serviços

```bash
# Reiniciar Prometheus para carregar nova configuração
docker-compose restart prometheus

# Verificar se Prometheus consegue alcançar Alertmanager
docker-compose logs prometheus | grep alertmanager

# Verificar targets no Prometheus
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.job=="alertmanager")'
```

---

## 4. VERIFICAÇÃO DA INSTALAÇÃO

### ✅ Checklist de Verificação

#### **1. Alertmanager está rodando?**
```bash
# Status do container
docker-compose ps alertmanager

# Deve mostrar: Up
```

#### **2. Interface web acessível?**
```bash
# Testar acesso HTTP
curl -I http://localhost:9093

# Deve retornar: HTTP/1.1 200 OK
```

#### **3. Configuração carregada?**
```bash
# Verificar configuração via API
curl http://localhost:9093/api/v2/status | jq '.config'

# Deve mostrar a configuração YAML
```

#### **4. Prometheus consegue enviar alertas?**
```bash
# Verificar alertmanagers no Prometheus
curl http://localhost:9090/api/v1/alertmanagers | jq

# Deve mostrar o Alertmanager como ativo
```

#### **5. Regras de alerta carregadas?**
```bash
# Verificar regras no Prometheus
curl http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[].name'

# Deve mostrar os nomes dos alertas
```

### 🧪 Teste de Alerta Manual

```bash
# Enviar alerta de teste via API
curl -XPOST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[
    {
      "labels": {
        "alertname": "TestAlert",
        "severity": "warning",
        "instance": "localhost:9090",
        "job": "test"
      },
      "annotations": {
        "summary": "Teste de alerta manual",
        "description": "Este é um alerta de teste enviado manualmente"
      },
      "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
      "endsAt": "'$(date -u -d "+5 minutes" +%Y-%m-%dT%H:%M:%S.%3NZ)'"
    }
  ]'
```

**Verificar se o alerta apareceu:**
1. Acesse http://localhost:9093
2. Vá na aba "Alerts"
3. Deve aparecer "TestAlert" com status "firing"

### 🔍 Troubleshooting Comum

#### **Problema: Alertmanager não inicia**
```bash
# Ver logs detalhados
docker-compose logs alertmanager

# Problemas comuns:
# - Erro de sintaxe no alertmanager.yml
# - Porta 9093 já em uso
# - Permissões de arquivo
```

#### **Problema: Prometheus não consegue enviar alertas**
```bash
# Verificar conectividade de rede
docker-compose exec prometheus ping alertmanager

# Verificar configuração do Prometheus
docker-compose exec prometheus cat /etc/prometheus/prometheus.yml | grep -A 10 alerting
```

#### **Problema: Alertas não aparecem**
```bash
# Verificar se regras estão sendo avaliadas
curl http://localhost:9090/api/v1/rules

# Verificar se há alertas pendentes/firing
curl http://localhost:9090/api/v1/alerts

# Verificar logs do Alertmanager
docker-compose logs alertmanager | grep -i error
```

---

## 🎯 RESUMO DO MÓDULO

### ✅ O que você configurou:

1. **Alertmanager rodando** via Docker Compose
2. **Interface web acessível** em http://localhost:9093
3. **Prometheus integrado** enviando alertas para Alertmanager
4. **Regras de teste** criadas e funcionando
5. **Verificação completa** da instalação

### 🔧 Arquivos criados:
- `alertmanager/alertmanager.yml` - Configuração principal
- `rules/test-alerts.yml` - Regras de alerta de teste
- `docker-compose.yml` - Configuração dos containers

### 🚀 Próximos Passos

Agora que o Alertmanager está funcionando, vamos **entender em detalhes** o arquivo de configuração:

**Próximo módulo:** [03-arquivo-config.md](03-arquivo-config.md) - Entendendo o alertmanager.yml

---

## 🔗 Links Relacionados

- **[Anterior: Introdução](01-introducao.md)**
- **[Próximo: Arquivo de Configuração](03-arquivo-config.md)**
- **[Voltar ao Índice](README.md)**
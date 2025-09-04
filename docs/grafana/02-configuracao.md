# Módulo 02 - Configuração Inicial do Grafana

## 📋 Objetivos do Módulo

Ao final deste módulo, você será capaz de:

- ✅ Instalar o Grafana em diferentes ambientes
- ✅ Configurar o Grafana com Docker e Docker Compose
- ✅ Realizar a configuração inicial da interface
- ✅ Integrar com Prometheus como primeira data source
- ✅ Navegar pela interface e criar seu primeiro dashboard
- ✅ Configurar usuários e permissões básicas

## 🚀 Métodos de Instalação

### 1. Instalação com Docker (Recomendado)

#### Docker Run Simples

```bash
# Executar Grafana standalone
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -v grafana-storage:/var/lib/grafana \
  grafana/grafana:latest
```

#### Docker Compose Básico

```yaml
# docker-compose.yml
version: '3.8'

services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    networks:
      - monitoring

volumes:
  grafana-data:

networks:
  monitoring:
    driver: bridge
```

#### Executar o Ambiente

```bash
# Iniciar os serviços
docker-compose up -d

# Verificar status
docker-compose ps

# Ver logs
docker-compose logs grafana
```

### 2. Docker Compose Completo com Stack

```yaml
# docker-compose.yml - Stack completo
version: '3.8'

services:
  # Prometheus
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    networks:
      - monitoring

  # Node Exporter
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    networks:
      - monitoring

  # Grafana
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    depends_on:
      - prometheus
    networks:
      - monitoring

volumes:
  prometheus-data:
  grafana-data:

networks:
  monitoring:
    driver: bridge
```

### 3. Configuração do Prometheus

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  # Grafana
  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']
```

## ⚙️ Configuração Inicial do Grafana

### 1. Primeiro Acesso

#### Acessar a Interface

1. **URL**: http://localhost:3000
2. **Usuário padrão**: admin
3. **Senha padrão**: admin (ou definida no Docker Compose)

#### Alterar Senha Inicial

```bash
# Via interface web (recomendado)
# Ou via CLI do container
docker exec -it grafana grafana-cli admin reset-admin-password newpassword
```

### 2. Configuração de Data Source

#### Adicionar Prometheus via Interface

1. **Navegação**: Configuration → Data Sources → Add data source
2. **Tipo**: Prometheus
3. **URL**: http://prometheus:9090 (Docker) ou http://localhost:9090
4. **Access**: Server (default)

#### Configuração via JSON

```json
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://prometheus:9090",
  "access": "proxy",
  "basicAuth": false,
  "isDefault": true,
  "jsonData": {
    "httpMethod": "POST",
    "timeInterval": "15s"
  }
}
```

### 3. Provisioning Automático

#### Estrutura de Diretórios

```
grafana/
├── provisioning/
│   ├── datasources/
│   │   └── prometheus.yml
│   ├── dashboards/
│   │   └── dashboard-provider.yml
│   └── notifiers/
│       └── slack.yml
└── dashboards/
    ├── infrastructure.json
    └── application.json
```

#### Data Source Provisioning

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
      timeInterval: 15s
      queryTimeout: 60s
    secureJsonData:
      # httpHeaderValue1: 'Bearer token_here'
```

#### Dashboard Provisioning

```yaml
# grafana/provisioning/dashboards/dashboard-provider.yml
apiVersion: 1

providers:
  - name: 'Infrastructure'
    orgId: 1
    folder: 'Infrastructure'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

## 🎯 Primeiro Dashboard

### 1. Criar Dashboard Manualmente

#### Passos Básicos

1. **Criar**: Dashboard → New Dashboard
2. **Adicionar Painel**: Add Panel
3. **Configurar Query**: Selecionar data source e métrica
4. **Personalizar**: Título, tipo de visualização, cores
5. **Salvar**: Save dashboard

#### Query de Exemplo

```promql
# CPU Usage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk Usage
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```

### 2. Dashboard JSON Completo

```json
{
  "dashboard": {
    "id": null,
    "title": "System Overview",
    "tags": ["infrastructure", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "timeseries",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "targets": [
          {
            "expr": "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %",
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
                {"color": "green", "value": 0},
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
        "type": "gauge",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "Memory Usage",
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
                {"color": "green", "value": 0},
                {"color": "yellow", "value": 80},
                {"color": "red", "value": 95}
              ]
            }
          }
        },
        "options": {
          "reduceOptions": {
            "values": false,
            "calcs": ["lastNotNull"]
          }
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
```

## 👥 Configuração de Usuários

### 1. Configurações de Segurança

#### Variáveis de Ambiente

```yaml
# docker-compose.yml
environment:
  # Admin user
  - GF_SECURITY_ADMIN_USER=admin
  - GF_SECURITY_ADMIN_PASSWORD=secure_password
  
  # Disable sign up
  - GF_USERS_ALLOW_SIGN_UP=false
  
  # Anonymous access
  - GF_AUTH_ANONYMOUS_ENABLED=false
  
  # Session settings
  - GF_SESSION_LIFE_TIME=86400
  - GF_SESSION_COOKIE_SECURE=true
```

### 2. Gerenciamento de Usuários

#### Criar Usuário via CLI

```bash
# Criar usuário
docker exec -it grafana grafana-cli admin create-user \
  --name "John Doe" \
  --email "john@example.com" \
  --login "john" \
  --password "password123"

# Listar usuários
docker exec -it grafana grafana-cli admin list-users

# Resetar senha
docker exec -it grafana grafana-cli admin reset-admin-password newpassword
```

#### Configurar Permissões

```bash
# Adicionar usuário a organização
docker exec -it grafana grafana-cli org add-user \
  --org-id 1 \
  --user-id 2 \
  --role Editor

# Roles disponíveis: Viewer, Editor, Admin
```

### 3. Configuração LDAP (Opcional)

```ini
# ldap.toml
[[servers]]
host = "ldap.example.com"
port = 389
use_ssl = false
start_tls = false
bind_dn = "cn=admin,dc=example,dc=com"
bind_password = "password"

search_filter = "(cn=%s)"
search_base_dns = ["dc=example,dc=com"]

[servers.attributes]
name = "givenName"
surname = "sn"
username = "cn"
member_of = "memberOf"
email = "email"

[[servers.group_mappings]]
group_dn = "cn=admins,ou=groups,dc=example,dc=com"
org_role = "Admin"

[[servers.group_mappings]]
group_dn = "cn=users,ou=groups,dc=example,dc=com"
org_role = "Editor"
```

## 🔧 Configurações Avançadas

### 1. Arquivo de Configuração Principal

```ini
# grafana.ini
[default]
instance_name = grafana

[paths]
data = /var/lib/grafana
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins
provisioning = /etc/grafana/provisioning

[server]
protocol = http
http_addr =
http_port = 3000
domain = localhost
root_url = %(protocol)s://%(domain)s:%(http_port)s/

[database]
type = sqlite3
path = grafana.db

[session]
provider = file
provider_config = sessions
cookie_name = grafana_sess
cookie_secure = false
session_life_time = 86400

[security]
admin_user = admin
admin_password = admin
secret_key = SW2YcwTIb9zpOOhoPsMm

[users]
allow_sign_up = false
allow_org_create = false
auto_assign_org = true
auto_assign_org_role = Viewer

[auth.anonymous]
enabled = false

[log]
mode = console file
level = info

[alerting]
enabled = true
execute_alerts = true

[metrics]
enabled = true
interval_seconds = 10
```

### 2. Plugins e Extensões

#### Instalar Plugins

```bash
# Via Docker Compose
environment:
  - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource,grafana-worldmap-panel

# Via CLI
docker exec -it grafana grafana-cli plugins install grafana-clock-panel
docker exec -it grafana grafana-cli plugins install grafana-worldmap-panel
docker exec -it grafana grafana-cli plugins install grafana-piechart-panel

# Listar plugins instalados
docker exec -it grafana grafana-cli plugins ls
```

#### Plugins Recomendados

| Plugin | Descrição | Uso |
|--------|-----------|-----|
| **Clock Panel** | Relógio e data | Dashboards operacionais |
| **Worldmap Panel** | Mapas geográficos | Monitoramento global |
| **Pie Chart** | Gráficos de pizza | Distribuições |
| **Stat Panel** | Métricas simples | KPIs e estatísticas |
| **Table Panel** | Tabelas avançadas | Dados tabulares |

## 🧪 Testes e Validação

### 1. Verificar Instalação

```bash
# Verificar se Grafana está rodando
curl -f http://localhost:3000/api/health

# Resposta esperada:
# {"commit":"...","database":"ok","version":"..."}
```

### 2. Testar Data Source

```bash
# Testar conectividade com Prometheus
curl -f http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=up

# Via interface: Data Sources → Prometheus → Save & Test
```

### 3. Script de Validação

```bash
#!/bin/bash
# validate-grafana.sh

echo "🔍 Validando instalação do Grafana..."

# Verificar se container está rodando
if docker ps | grep -q grafana; then
    echo "✅ Container Grafana está rodando"
else
    echo "❌ Container Grafana não encontrado"
    exit 1
fi

# Verificar saúde da aplicação
if curl -sf http://localhost:3000/api/health > /dev/null; then
    echo "✅ Grafana está saudável"
else
    echo "❌ Grafana não está respondendo"
    exit 1
fi

# Verificar data sources
DS_COUNT=$(curl -s -u admin:admin123 http://localhost:3000/api/datasources | jq length)
if [ "$DS_COUNT" -gt 0 ]; then
    echo "✅ Data sources configurados: $DS_COUNT"
else
    echo "⚠️ Nenhum data source configurado"
fi

# Verificar dashboards
DB_COUNT=$(curl -s -u admin:admin123 http://localhost:3000/api/search | jq length)
echo "📊 Dashboards encontrados: $DB_COUNT"

echo "🎉 Validação concluída!"
```

## 🎯 Exercícios Práticos

### Exercício 1: Instalação Completa

**Objetivo**: Configurar ambiente completo com Docker Compose

**Passos**:
1. Criar `docker-compose.yml` com Prometheus, Node Exporter e Grafana
2. Configurar `prometheus.yml` para coletar métricas
3. Inicializar o ambiente
4. Acessar Grafana e configurar data source

**Validação**:
- [ ] Grafana acessível em http://localhost:3000
- [ ] Prometheus configurado como data source
- [ ] Métricas do Node Exporter visíveis

### Exercício 2: Primeiro Dashboard

**Objetivo**: Criar dashboard de monitoramento básico

**Requisitos**:
- Painel de CPU usage (time series)
- Painel de Memory usage (gauge)
- Painel de Disk usage (stat)
- Time range de 1 hora
- Refresh automático de 30s

**Entregáveis**:
- Dashboard salvo no Grafana
- JSON do dashboard exportado
- Screenshot dos painéis

### Exercício 3: Provisioning Automático

**Objetivo**: Automatizar configuração com provisioning

**Tarefas**:
1. Criar estrutura de provisioning
2. Configurar data source via YAML
3. Provisionar dashboard via JSON
4. Testar recriação do ambiente

**Validação**:
- [ ] Data source criado automaticamente
- [ ] Dashboard provisionado na inicialização
- [ ] Configuração persistente após restart

## 📚 Resumo do Módulo

### Conceitos Aprendidos

✅ **Instalação e Configuração**
- Docker e Docker Compose
- Configurações de segurança
- Variáveis de ambiente

✅ **Data Sources**
- Configuração do Prometheus
- Testes de conectividade
- Provisioning automático

✅ **Interface e Navegação**
- Primeiro acesso
- Criação de dashboards
- Gerenciamento de usuários

✅ **Automação**
- Provisioning de data sources
- Provisioning de dashboards
- Configuração como código

### Próximos Passos

No próximo módulo, você aprenderá:
- Configuração avançada de data sources
- Integração com InfluxDB, MySQL e outros
- Otimização de queries
- Configurações específicas por tipo de dados

## 🔗 Recursos Adicionais

### Documentação
- [Installation Guide](https://grafana.com/docs/grafana/latest/installation/)
- [Configuration](https://grafana.com/docs/grafana/latest/administration/configuration/)
- [Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)

### Docker Images
- [Grafana Official](https://hub.docker.com/r/grafana/grafana)
- [Prometheus](https://hub.docker.com/r/prom/prometheus)
- [Node Exporter](https://hub.docker.com/r/prom/node-exporter)

---

## 🚀 Navegação

**Anterior:** [📊 Módulo 01 - Introdução ao Grafana](01-introducao.md)  
**Próximo:** [🔌 Módulo 03 - Data Sources](03-data-sources.md)

---

*Este módulo faz parte da documentação educacional completa do Grafana. Continue sua jornada de aprendizado com os próximos módulos!*
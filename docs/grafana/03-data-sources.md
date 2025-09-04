# Módulo 03 - Data Sources (Fontes de Dados)

## 📋 Objetivos do Módulo

Ao final deste módulo, você será capaz de:

- ✅ Configurar diferentes tipos de data sources
- ✅ Integrar Prometheus, InfluxDB, MySQL e outros
- ✅ Otimizar queries para cada tipo de fonte
- ✅ Implementar autenticação e segurança
- ✅ Usar provisioning para automação
- ✅ Diagnosticar problemas de conectividade

## 🔌 Tipos de Data Sources

### Categorias Principais

```mermaid
graph TB
    subgraph "Time Series"
        PROM["Prometheus"]
        INFLUX["InfluxDB"]
        GRAPHITE["Graphite"]
        TEMPO["Tempo"]
    end
    
    subgraph "Logs"
        LOKI["Loki"]
        ELASTIC["Elasticsearch"]
        SPLUNK["Splunk"]
    end
    
    subgraph "SQL Databases"
        MYSQL["MySQL"]
        POSTGRES["PostgreSQL"]
        MSSQL["SQL Server"]
        SQLITE["SQLite"]
    end
    
    subgraph "Cloud Services"
        CLOUDWATCH["CloudWatch"]
        STACKDRIVER["Google Cloud"]
        AZURE["Azure Monitor"]
    end
    
    subgraph "NoSQL"
        MONGO["MongoDB"]
        REDIS["Redis"]
        CASSANDRA["Cassandra"]
    end
    
    style PROM fill:#e8f5e8
    style INFLUX fill:#e3f2fd
    style MYSQL fill:#fff3e0
```

## 📊 Prometheus Data Source

### 1. Configuração Básica

#### Via Interface Web

1. **Navegação**: Configuration → Data Sources → Add data source
2. **Tipo**: Prometheus
3. **Configurações**:

```yaml
Name: Prometheus
URL: http://prometheus:9090
Access: Server (default)
Scrape interval: 15s
Query timeout: 60s
HTTP Method: POST
```

#### Via Provisioning

```yaml
# provisioning/datasources/prometheus.yml
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
      incrementalQuerying: true
      incrementalQueryOverlapWindow: 10m
    secureJsonData:
      # Para autenticação básica
      # basicAuthPassword: 'password'
      # Para headers customizados
      # httpHeaderValue1: 'Bearer token_here'
```

### 2. Configurações Avançadas

#### Autenticação e Segurança

```yaml
# Com autenticação básica
datasources:
  - name: Prometheus-Secure
    type: prometheus
    url: https://prometheus.example.com
    basicAuth: true
    basicAuthUser: grafana
    secureJsonData:
      basicAuthPassword: 'secure_password'
    jsonData:
      tlsSkipVerify: false
      tlsAuth: true
      tlsCACert: |
        -----BEGIN CERTIFICATE-----
        MIIDXTCCAkWgAwIBAgIJAKL...
        -----END CERTIFICATE-----
```

#### Headers Customizados

```yaml
jsonData:
  httpHeaderName1: 'X-API-Key'
  httpHeaderName2: 'X-Tenant-ID'
secureJsonData:
  httpHeaderValue1: 'api_key_value'
  httpHeaderValue2: 'tenant_123'
```

### 3. Queries PromQL Otimizadas

#### Exemplos de Queries

```promql
# CPU Usage por instância
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Network I/O
rate(node_network_receive_bytes_total[5m]) * 8

# Disk I/O
rate(node_disk_read_bytes_total[5m])

# HTTP Request Rate
sum(rate(http_requests_total[5m])) by (method, status)

# Error Rate
sum(rate(http_requests_total{status=~"5.."}[5m])) / 
sum(rate(http_requests_total[5m])) * 100
```

## 📈 InfluxDB Data Source

### 1. Configuração InfluxDB 1.x

#### Docker Compose

```yaml
# docker-compose.yml
services:
  influxdb:
    image: influxdb:1.8
    container_name: influxdb
    ports:
      - "8086:8086"
    environment:
      - INFLUXDB_DB=metrics
      - INFLUXDB_USER=grafana
      - INFLUXDB_USER_PASSWORD=password
      - INFLUXDB_ADMIN_USER=admin
      - INFLUXDB_ADMIN_PASSWORD=admin123
    volumes:
      - influxdb-data:/var/lib/influxdb
    networks:
      - monitoring
```

#### Configuração no Grafana

```yaml
# provisioning/datasources/influxdb.yml
apiVersion: 1

datasources:
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    database: metrics
    user: grafana
    secureJsonData:
      password: 'password'
    jsonData:
      timeInterval: 10s
      httpMode: GET
```

### 2. Configuração InfluxDB 2.x

#### Docker Compose

```yaml
services:
  influxdb2:
    image: influxdb:2.7
    container_name: influxdb2
    ports:
      - "8086:8086"
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=admin
      - DOCKER_INFLUXDB_INIT_PASSWORD=admin123
      - DOCKER_INFLUXDB_INIT_ORG=myorg
      - DOCKER_INFLUXDB_INIT_BUCKET=metrics
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=my-super-secret-auth-token
    volumes:
      - influxdb2-data:/var/lib/influxdb2
```

#### Configuração no Grafana

```yaml
# InfluxDB 2.x com Flux
datasources:
  - name: InfluxDB-v2
    type: influxdb
    access: proxy
    url: http://influxdb2:8086
    jsonData:
      version: Flux
      organization: myorg
      defaultBucket: metrics
      tlsSkipVerify: true
    secureJsonData:
      token: 'my-super-secret-auth-token'
```

### 3. Queries InfluxQL vs Flux

#### InfluxQL (v1.x)

```sql
-- CPU Usage
SELECT mean("usage_idle") 
FROM "cpu" 
WHERE $timeFilter 
GROUP BY time($__interval), "host" 
FILL(null)

-- Memory Usage
SELECT mean("used_percent") 
FROM "mem" 
WHERE $timeFilter 
GROUP BY time($__interval), "host"

-- Disk I/O
SELECT derivative(mean("read_bytes"), 1s) 
FROM "diskio" 
WHERE $timeFilter 
GROUP BY time($__interval), "name"
```

#### Flux (v2.x)

```flux
// CPU Usage
from(bucket: "metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> filter(fn: (r) => r._field == "usage_idle")
  |> aggregateWindow(every: v.windowPeriod, fn: mean)

// Memory Usage
from(bucket: "metrics")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "mem")
  |> filter(fn: (r) => r._field == "used_percent")
  |> aggregateWindow(every: v.windowPeriod, fn: mean)
```

## 🗄️ SQL Data Sources

### 1. MySQL Configuration

#### Docker Compose

```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: mysql
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=rootpassword
      - MYSQL_DATABASE=monitoring
      - MYSQL_USER=grafana
      - MYSQL_PASSWORD=grafana123
    volumes:
      - mysql-data:/var/lib/mysql
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/init.sql
```

#### Configuração no Grafana

```yaml
# provisioning/datasources/mysql.yml
apiVersion: 1

datasources:
  - name: MySQL
    type: mysql
    url: mysql:3306
    database: monitoring
    user: grafana
    secureJsonData:
      password: 'grafana123'
    jsonData:
      maxOpenConns: 100
      maxIdleConns: 100
      maxLifetime: 14400
      connMaxLifetime: 14400
```

### 2. PostgreSQL Configuration

```yaml
# PostgreSQL
services:
  postgres:
    image: postgres:15
    container_name: postgres
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=monitoring
      - POSTGRES_USER=grafana
      - POSTGRES_PASSWORD=grafana123
    volumes:
      - postgres-data:/var/lib/postgresql/data
```

```yaml
# Grafana data source
datasources:
  - name: PostgreSQL
    type: postgres
    url: postgres:5432
    database: monitoring
    user: grafana
    secureJsonData:
      password: 'grafana123'
    jsonData:
      sslmode: disable
      maxOpenConns: 100
      maxIdleConns: 100
      connMaxLifetime: 14400
```

### 3. Queries SQL Otimizadas

#### Exemplos MySQL/PostgreSQL

```sql
-- Time series de métricas
SELECT 
  timestamp as time,
  server_name,
  cpu_usage as value
FROM server_metrics 
WHERE 
  timestamp BETWEEN $__timeFrom() AND $__timeTo()
  AND server_name IN ($server)
ORDER BY timestamp

-- Agregação por período
SELECT 
  $__timeGroup(timestamp, '5m') as time,
  AVG(cpu_usage) as "CPU Average",
  MAX(cpu_usage) as "CPU Max"
FROM server_metrics 
WHERE $__timeFilter(timestamp)
GROUP BY 1
ORDER BY 1

-- Top N servidores por uso
SELECT 
  server_name,
  AVG(cpu_usage) as avg_cpu
FROM server_metrics 
WHERE $__timeFilter(timestamp)
GROUP BY server_name
ORDER BY avg_cpu DESC
LIMIT 10
```

## 📝 Loki (Logs) Data Source

### 1. Configuração Loki

#### Docker Compose

```yaml
services:
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - loki-data:/loki
    networks:
      - monitoring

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - /var/log:/var/log:ro
      - ./promtail/config.yml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml
    depends_on:
      - loki
    networks:
      - monitoring
```

#### Configuração no Grafana

```yaml
# provisioning/datasources/loki.yml
apiVersion: 1

datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    jsonData:
      maxLines: 1000
      derivedFields:
        - datasourceUid: prometheus-uid
          matcherRegex: "traceID=(\\w+)"
          name: TraceID
          url: "$${__value.raw}"
```

### 2. LogQL Queries

```logql
# Logs básicos
{job="varlogs"}

# Filtrar por nível
{job="app"} |= "ERROR"

# Regex pattern
{job="nginx"} |~ ".*POST.*"

# Métricas de logs
sum(rate({job="app"}[5m])) by (level)

# Contagem de erros
sum(count_over_time({job="app"} |= "ERROR" [5m]))
```

## ☁️ Cloud Data Sources

### 1. AWS CloudWatch

```yaml
# provisioning/datasources/cloudwatch.yml
apiVersion: 1

datasources:
  - name: CloudWatch
    type: cloudwatch
    jsonData:
      authType: keys
      defaultRegion: us-east-1
    secureJsonData:
      accessKey: 'AKIAIOSFODNN7EXAMPLE'
      secretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
```

### 2. Google Cloud Monitoring

```yaml
datasources:
  - name: Google Cloud Monitoring
    type: stackdriver
    jsonData:
      authenticationType: gce
      defaultProject: my-project-id
    secureJsonData:
      privateKey: |
        -----BEGIN PRIVATE KEY-----
        MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
        -----END PRIVATE KEY-----
```

### 3. Azure Monitor

```yaml
datasources:
  - name: Azure Monitor
    type: grafana-azure-monitor-datasource
    jsonData:
      azureAuthType: msi
      subscriptionId: 12345678-1234-1234-1234-123456789abc
      tenantId: 87654321-4321-4321-4321-cba987654321
```

## 🔧 Configurações Avançadas

### 1. Connection Pooling

```yaml
# Para SQL data sources
jsonData:
  maxOpenConns: 100        # Máximo de conexões abertas
  maxIdleConns: 100        # Máximo de conexões idle
  connMaxLifetime: 14400   # Tempo de vida da conexão (segundos)
  maxIdleConnsAuto: true   # Auto-configurar idle connections
```

### 2. Query Caching

```yaml
# Cache de queries
jsonData:
  queryTimeout: 60s
  timeInterval: 15s
  incrementalQuerying: true
  incrementalQueryOverlapWindow: 10m
```

### 3. Rate Limiting

```yaml
# Limitação de taxa
jsonData:
  httpMethod: POST
  queryTimeout: 60s
  timeInterval: 15s
```

## 🧪 Testes e Validação

### 1. Script de Teste de Conectividade

```bash
#!/bin/bash
# test-datasources.sh

GRAFANA_URL="http://localhost:3000"
USER="admin"
PASS="admin123"

echo "🔍 Testando conectividade dos data sources..."

# Listar data sources
echo "📋 Data sources configurados:"
curl -s -u $USER:$PASS "$GRAFANA_URL/api/datasources" | jq -r '.[] | "\(.name) (\(.type))"'

# Testar cada data source
for ds_id in $(curl -s -u $USER:$PASS "$GRAFANA_URL/api/datasources" | jq -r '.[].id'); do
    ds_name=$(curl -s -u $USER:$PASS "$GRAFANA_URL/api/datasources/$ds_id" | jq -r '.name')
    echo "🧪 Testando $ds_name..."
    
    result=$(curl -s -u $USER:$PASS -X POST "$GRAFANA_URL/api/datasources/$ds_id/health")
    status=$(echo $result | jq -r '.status')
    
    if [ "$status" = "success" ]; then
        echo "✅ $ds_name: OK"
    else
        echo "❌ $ds_name: FALHA"
        echo "   Detalhes: $(echo $result | jq -r '.message')"
    fi
done
```

### 2. Validação de Queries

```python
#!/usr/bin/env python3
# validate-queries.py

import requests
import json
import sys

class GrafanaValidator:
    def __init__(self, url, username, password):
        self.url = url
        self.auth = (username, password)
        self.session = requests.Session()
        self.session.auth = self.auth
    
    def test_prometheus_query(self, query):
        """Testa query PromQL"""
        payload = {
            "queries": [{
                "refId": "A",
                "expr": query,
                "datasource": {"type": "prometheus", "uid": "prometheus"}
            }],
            "from": "now-1h",
            "to": "now"
        }
        
        response = self.session.post(
            f"{self.url}/api/ds/query",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        return response.status_code == 200, response.json()
    
    def test_sql_query(self, query, datasource_uid):
        """Testa query SQL"""
        payload = {
            "queries": [{
                "refId": "A",
                "rawSql": query,
                "datasource": {"uid": datasource_uid}
            }],
            "from": "now-1h",
            "to": "now"
        }
        
        response = self.session.post(
            f"{self.url}/api/ds/query",
            json=payload
        )
        
        return response.status_code == 200, response.json()

# Exemplo de uso
if __name__ == "__main__":
    validator = GrafanaValidator("http://localhost:3000", "admin", "admin123")
    
    # Testar queries Prometheus
    queries = [
        "up",
        "rate(http_requests_total[5m])",
        "node_cpu_seconds_total"
    ]
    
    for query in queries:
        success, result = validator.test_prometheus_query(query)
        print(f"Query '{query}': {'✅ OK' if success else '❌ FALHA'}")
        if not success:
            print(f"  Erro: {result}")
```

## 🎯 Exercícios Práticos

### Exercício 1: Multi-Data Source Setup

**Objetivo**: Configurar múltiplas fontes de dados

**Tarefas**:
1. Configurar Prometheus, InfluxDB e MySQL
2. Criar provisioning para todas as fontes
3. Testar conectividade
4. Criar queries de exemplo para cada tipo

**Validação**:
- [ ] Todas as fontes conectadas
- [ ] Queries funcionando
- [ ] Provisioning automático

### Exercício 2: Query Optimization

**Objetivo**: Otimizar performance de queries

**Cenários**:
1. Query PromQL lenta
2. Query SQL com muitos dados
3. Logs com alto volume

**Métricas**:
- Tempo de execução < 5s
- Uso de memória otimizado
- Cache efetivo

### Exercício 3: Security Configuration

**Objetivo**: Implementar segurança nas conexões

**Requisitos**:
1. HTTPS/TLS para todas as conexões
2. Autenticação básica ou token
3. Certificados customizados
4. Headers de segurança

**Entregáveis**:
- Configurações de segurança
- Certificados configurados
- Testes de conectividade segura

## 📚 Resumo do Módulo

### Conceitos Aprendidos

✅ **Tipos de Data Sources**
- Time series (Prometheus, InfluxDB)
- SQL databases (MySQL, PostgreSQL)
- Logs (Loki, Elasticsearch)
- Cloud services (AWS, GCP, Azure)

✅ **Configuração e Otimização**
- Provisioning automático
- Connection pooling
- Query caching
- Rate limiting

✅ **Segurança**
- Autenticação e autorização
- TLS/SSL
- Headers customizados
- Certificados

✅ **Troubleshooting**
- Testes de conectividade
- Validação de queries
- Monitoramento de performance

### Próximos Passos

No próximo módulo, você aprenderá:
- Criação e organização de dashboards
- Painéis e visualizações
- Variáveis e templates
- Compartilhamento e colaboração

## 🔗 Recursos Adicionais

### Documentação
- [Data Sources](https://grafana.com/docs/grafana/latest/datasources/)
- [Prometheus](https://grafana.com/docs/grafana/latest/datasources/prometheus/)
- [InfluxDB](https://grafana.com/docs/grafana/latest/datasources/influxdb/)
- [MySQL](https://grafana.com/docs/grafana/latest/datasources/mysql/)

### Queries
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Flux Language](https://docs.influxdata.com/flux/)
- [LogQL](https://grafana.com/docs/loki/latest/logql/)

---

## 🚀 Navegação

**Anterior:** [⚙️ Módulo 02 - Configuração Inicial](02-configuracao.md)  
**Próximo:** [📊 Módulo 04 - Dashboards](04-dashboards.md)

---

*Este módulo faz parte da documentação educacional completa do Grafana. Continue sua jornada de aprendizado com os próximos módulos!*
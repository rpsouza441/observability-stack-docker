# 🔍 MÓDULO 05: PROMQL BÁSICO

> **Objetivo:** Dominar os fundamentos da linguagem de consulta PromQL  
> **Duração:** 90 minutos  
> **Nível:** Intermediário

---

## 🎯 O QUE VOCÊ VAI APRENDER

Neste módulo você irá:
- ✅ Entender a sintaxe básica do PromQL
- ✅ Usar seletores e filtros de métricas
- ✅ Aplicar operadores matemáticos e lógicos
- ✅ Dominar funções básicas de agregação
- ✅ Trabalhar com ranges de tempo

---

## 📚 FUNDAMENTOS DO PROMQL

### **🎯 O que é PromQL?**

PromQL (Prometheus Query Language) é uma linguagem funcional para consultar dados de séries temporais no Prometheus.

**Características principais:**
- 📊 **Expressões:** Retornam dados escalares, vetores ou matrizes
- 🕐 **Time-aware:** Trabalha nativamente com dados temporais
- 🔢 **Matemática:** Suporte completo a operações matemáticas
- 📈 **Agregação:** Funções para sumarizar dados
- 🏷️ **Labels:** Filtragem e agrupamento por metadados

### **🏗️ Tipos de Dados**

```promql
# 1. SCALAR (Escalar) - Valor numérico simples
42
3.14
time()

# 2. INSTANT VECTOR - Conjunto de séries temporais em um momento
up
http_requests_total
node_cpu_seconds_total{mode="idle"}

# 3. RANGE VECTOR - Conjunto de séries temporais em um intervalo
up[5m]
http_requests_total[1h]
node_cpu_seconds_total{mode="idle"}[10m]

# 4. MATRIX - Resultado de funções que retornam múltiplas séries
rate(http_requests_total[5m])
```

---

## 🎯 SELETORES DE MÉTRICAS

### **📊 Seletor Básico**

```promql
# Selecionar métrica por nome
up
http_requests_total
node_memory_MemTotal_bytes

# Resultado:
up{instance="localhost:9090", job="prometheus"} 1
up{instance="node-exporter:9100", job="node-exporter"} 1
```

### **🏷️ Seletores com Labels**

```promql
# Igualdade exata
up{job="prometheus"}
http_requests_total{method="GET"}
node_cpu_seconds_total{mode="idle", cpu="0"}

# Desigualdade
up{job!="prometheus"}
http_requests_total{status!="200"}

# Regex match
up{job=~"prometheus|node.*"}
http_requests_total{endpoint=~"/api/.*"}
node_filesystem_size_bytes{fstype=~"ext[34]"}

# Regex não match
up{job!~"test.*"}
http_requests_total{path!~"/health|/metrics"}
```

### **🔍 Exemplos Práticos**

```promql
# Todas as métricas de CPU
{__name__=~".*cpu.*"}

# Métricas de um job específico
{job="node-exporter"}

# Métricas de produção apenas
{environment="production"}

# Múltiplos filtros
http_requests_total{method="GET", status=~"2..", job="web-server"}

# Excluir métricas de teste
{job!~".*test.*", environment!="development"}
```

---

## ⏰ RANGES DE TEMPO

### **📅 Sintaxe de Duração**

```promql
# Unidades de tempo disponíveis:
s  # segundos
m  # minutos  
h  # horas
d  # dias
w  # semanas
y  # anos

# Exemplos:
up[30s]     # Últimos 30 segundos
up[5m]      # Últimos 5 minutos
up[1h]      # Última 1 hora
up[7d]      # Últimos 7 dias
up[2w]      # Últimas 2 semanas
up[1y]      # Último 1 ano

# Combinações:
up[1h30m]   # 1 hora e 30 minutos
up[2d12h]   # 2 dias e 12 horas
```

### **🎯 Uso Prático**

```promql
# Dados dos últimos 5 minutos
http_requests_total[5m]

# CPU usage nos últimos 10 minutos
node_cpu_seconds_total{mode="idle"}[10m]

# Memória na última hora
node_memory_MemAvailable_bytes[1h]

# Tráfego de rede no último dia
node_network_receive_bytes_total[1d]
```

---

## 🔢 OPERADORES MATEMÁTICOS

### **➕ Operadores Aritméticos**

```promql
# Adição
node_memory_MemTotal_bytes + node_memory_MemFree_bytes

# Subtração
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# Multiplicação
node_cpu_seconds_total * 100

# Divisão
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes

# Módulo
time() % 3600  # Segundos na hora atual

# Potência
node_load1 ^ 2
```

### **📊 Exemplos Práticos**

```promql
# Percentual de uso de memória
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Percentual de uso de disco
(1 - (node_filesystem_free_bytes / node_filesystem_size_bytes)) * 100

# Conversão de bytes para GB
node_memory_MemTotal_bytes / 1024 / 1024 / 1024

# Taxa de crescimento
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100
```

### **🔗 Operadores de Comparação**

```promql
# Igualdade
node_load1 == 1.5

# Desigualdade
node_load1 != 0

# Maior que
node_cpu_seconds_total > 1000

# Maior ou igual
node_memory_MemAvailable_bytes >= 1073741824  # >= 1GB

# Menor que
node_load1 < 2.0

# Menor ou igual
node_filesystem_free_bytes <= 1073741824  # <= 1GB
```

### **🧮 Operadores Lógicos**

```promql
# AND lógico
node_load1 > 1.0 and node_load5 > 1.0

# OR lógico
node_load1 > 2.0 or node_load5 > 2.0

# UNLESS (exceto)
up unless up{job="test"}
```

---

## 📈 FUNÇÕES BÁSICAS

### **📊 Funções de Taxa**

```promql
# RATE - Taxa por segundo (para counters)
rate(http_requests_total[5m])
rate(node_network_receive_bytes_total[5m])

# IRATE - Taxa instantânea (últimos 2 pontos)
irate(http_requests_total[5m])

# INCREASE - Incremento total no período
increase(http_requests_total[1h])
increase(node_disk_reads_completed_total[5m])

# DELTA - Diferença para gauges
delta(node_memory_MemAvailable_bytes[5m])

# IDELTA - Diferença instantânea
idelta(node_memory_MemAvailable_bytes[5m])
```

### **🎯 Quando Usar Cada Função**

```promql
# ✅ RATE - Para counters, análise de tendências
rate(http_requests_total[5m])  # Requisições por segundo

# ✅ IRATE - Para counters, valores mais recentes
irate(http_requests_total[5m])  # Taxa atual mais precisa

# ✅ INCREASE - Para counters, total no período
increase(http_requests_total[1h])  # Total de requisições na hora

# ✅ DELTA - Para gauges, mudança no período
delta(node_memory_MemAvailable_bytes[5m])  # Mudança na memória
```

### **🔢 Funções Matemáticas**

```promql
# ABS - Valor absoluto
abs(delta(node_memory_MemAvailable_bytes[5m]))

# CEIL - Arredondar para cima
ceil(node_load1)

# FLOOR - Arredondar para baixo
floor(node_load1)

# ROUND - Arredondar
round(node_load1, 0.1)  # Arredondar para 1 casa decimal

# SQRT - Raiz quadrada
sqrt(node_load1)

# EXP - Exponencial
exp(node_load1)

# LN - Logaritmo natural
ln(node_memory_MemTotal_bytes)

# LOG2 - Logaritmo base 2
log2(node_memory_MemTotal_bytes)

# LOG10 - Logaritmo base 10
log10(node_memory_MemTotal_bytes)
```

### **⏰ Funções de Tempo**

```promql
# TIME - Timestamp atual
time()

# MINUTE - Minuto atual (0-59)
minute()

# HOUR - Hora atual (0-23)
hour()

# DAY_OF_MONTH - Dia do mês (1-31)
day_of_month()

# DAY_OF_WEEK - Dia da semana (0-6, domingo=0)
day_of_week()

# MONTH - Mês (1-12)
month()

# YEAR - Ano
year()

# Exemplos práticos:
# Filtrar apenas horário comercial (9h-17h)
up and on() (hour() >= 9 and hour() <= 17)

# Filtrar apenas dias úteis (segunda a sexta)
up and on() (day_of_week() >= 1 and day_of_week() <= 5)
```

---

## 📊 FUNÇÕES DE AGREGAÇÃO

### **🔢 Agregações Básicas**

```promql
# SUM - Soma
sum(up)
sum(http_requests_total)
sum(node_memory_MemTotal_bytes)

# COUNT - Contagem
count(up)
count(up == 1)  # Quantos targets estão UP
count(up == 0)  # Quantos targets estão DOWN

# AVG - Média
avg(node_load1)
avg(node_memory_MemAvailable_bytes)

# MIN - Mínimo
min(node_memory_MemAvailable_bytes)
min(node_load1)

# MAX - Máximo
max(node_load1)
max(node_memory_MemTotal_bytes)

# STDDEV - Desvio padrão
stddev(node_load1)

# STDVAR - Variância
stdvar(node_load1)
```

### **🏷️ Agregação com BY**

```promql
# Agrupar por job
sum by (job) (up)
avg by (job) (node_load1)
max by (job) (node_memory_MemTotal_bytes)

# Agrupar por múltiplos labels
sum by (job, instance) (rate(http_requests_total[5m]))
avg by (job, mode) (rate(node_cpu_seconds_total[5m]))

# Agrupar por instance
sum by (instance) (rate(node_network_receive_bytes_total[5m]))
max by (instance) (node_filesystem_size_bytes)
```

### **🚫 Agregação com WITHOUT**

```promql
# Excluir labels específicos da agregação
sum without (cpu) (rate(node_cpu_seconds_total[5m]))
avg without (device) (rate(node_network_receive_bytes_total[5m]))
max without (fstype, mountpoint) (node_filesystem_size_bytes)

# Comparação BY vs WITHOUT:
# BY: mantém apenas os labels especificados
# WITHOUT: remove os labels especificados, mantém o resto
```

### **🎯 Exemplos Práticos de Agregação**

```promql
# CPU usage médio por servidor
avg by (instance) (100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))

# Total de requisições por método HTTP
sum by (method) (rate(http_requests_total[5m]))

# Memória total do cluster
sum(node_memory_MemTotal_bytes)

# Número de servidores por job
count by (job) (up)

# Servidor com maior load
topk(1, node_load1)

# Top 5 servidores por uso de CPU
topk(5, 100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))
```

---

## 🔝 FUNÇÕES TOPK E BOTTOMK

### **📈 TOPK - Maiores Valores**

```promql
# Top 5 servidores por load
topk(5, node_load1)

# Top 10 endpoints por requisições
topk(10, rate(http_requests_total[5m]))

# Top 3 filesystems por uso
topk(3, (1 - (node_filesystem_free_bytes / node_filesystem_size_bytes)) * 100)

# Servidor com maior uso de memória
topk(1, (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100)
```

### **📉 BOTTOMK - Menores Valores**

```promql
# 3 servidores com menor load
bottomk(3, node_load1)

# Endpoints com menos requisições
bottomk(5, rate(http_requests_total[5m]))

# Filesystems com mais espaço livre
bottomk(3, (node_filesystem_free_bytes / node_filesystem_size_bytes) * 100)
```

### **🎯 Casos de Uso Práticos**

```promql
# Identificar gargalos de performance
topk(5, rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m]))

# Servidores com problemas de conectividade
bottomk(3, rate(node_network_receive_bytes_total[5m]))

# Aplicações com mais erros
topk(10, rate(http_requests_total{status=~"5.."}[5m]))

# Bancos de dados mais lentos
topk(5, mysql_global_status_slow_queries)
```

---

## 🔍 FUNÇÕES DE SELEÇÃO

### **📊 QUANTILE**

```promql
# Percentil 50 (mediana)
quantile(0.5, node_load1)

# Percentil 95
quantile(0.95, rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m]))

# Percentil 99
quantile(0.99, node_memory_MemAvailable_bytes)

# Múltiplos percentis
quantile(0.5, node_load1) # P50
quantile(0.9, node_load1) # P90
quantile(0.95, node_load1) # P95
quantile(0.99, node_load1) # P99
```

### **📈 HISTOGRAM_QUANTILE**

```promql
# Para métricas do tipo histogram
# Latência P95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Latência P50 por endpoint
histogram_quantile(0.5, sum by (endpoint, le) (rate(http_request_duration_seconds_bucket[5m])))

# Latência P99 por job
histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket[5m])))
```

---

## 🎯 EXEMPLOS PRÁTICOS COMPLETOS

### **🖥️ Monitoramento de Sistema**

```promql
# === CPU ===
# CPU usage percentual por servidor
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU usage médio do cluster
avg(100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))

# Servidores com CPU > 80%
(100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80

# === MEMÓRIA ===
# Uso de memória percentual
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Memória disponível em GB
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024

# Servidores com pouca memória (<10% livre)
(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 < 10

# === DISCO ===
# Uso de disco percentual
(1 - (node_filesystem_free_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100

# Espaço livre em GB
node_filesystem_free_bytes{fstype!="tmpfs"} / 1024 / 1024 / 1024

# Filesystems quase cheios (>90%)
(1 - (node_filesystem_free_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 90

# === REDE ===
# Tráfego de entrada em MB/s
rate(node_network_receive_bytes_total{device!="lo"}[5m]) / 1024 / 1024

# Tráfego de saída em MB/s
rate(node_network_transmit_bytes_total{device!="lo"}[5m]) / 1024 / 1024

# Total de tráfego por servidor
sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]) + rate(node_network_transmit_bytes_total{device!="lo"}[5m]))
```

### **🌐 Monitoramento de Aplicação**

```promql
# === REQUISIÇÕES HTTP ===
# Taxa de requisições por segundo
sum(rate(http_requests_total[5m]))

# Taxa de requisições por endpoint
sum by (endpoint) (rate(http_requests_total[5m]))

# Taxa de requisições por status code
sum by (status) (rate(http_requests_total[5m]))

# === LATÊNCIA ===
# Latência média
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# Latência P95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Latência por endpoint
histogram_quantile(0.95, sum by (endpoint, le) (rate(http_request_duration_seconds_bucket[5m])))

# === ERROS ===
# Taxa de erro geral
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100

# Taxa de erro por endpoint
sum by (endpoint) (rate(http_requests_total{status=~"5.."}[5m])) / sum by (endpoint) (rate(http_requests_total[5m])) * 100

# Número de erros por minuto
sum(rate(http_requests_total{status=~"5.."}[5m])) * 60

# === DISPONIBILIDADE ===
# Uptime percentual
avg(up) * 100

# Serviços indisponíveis
count(up == 0)

# SLA (99.9% uptime)
avg_over_time(up[30d]) * 100
```

---

## 🧪 EXERCÍCIOS PRÁTICOS

### **🎯 Exercício 1: Métricas Básicas**

```promql
# 1. Liste todos os jobs disponíveis
group by (job) (up)

# 2. Conte quantos targets estão UP
count(up == 1)

# 3. Encontre o servidor com maior load
topk(1, node_load1)

# 4. Calcule o uso médio de CPU do cluster
avg(100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))

# 5. Liste servidores com uso de disco > 80%
(1 - (node_filesystem_free_bytes / node_filesystem_size_bytes)) * 100 > 80
```

### **🎯 Exercício 2: Agregações**

```promql
# 1. Total de memória do cluster em GB
sum(node_memory_MemTotal_bytes) / 1024 / 1024 / 1024

# 2. Uso médio de memória por job
avg by (job) ((1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100)

# 3. Top 3 interfaces de rede por tráfego
topk(3, rate(node_network_receive_bytes_total[5m]))

# 4. Desvio padrão do load average
stddev(node_load1)

# 5. Percentil 95 do uso de CPU
quantile(0.95, 100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))
```

### **🎯 Exercício 3: Aplicações**

```promql
# 1. Taxa de requisições HTTP por segundo
sum(rate(http_requests_total[5m]))

# 2. Percentual de requisições com erro
sum(rate(http_requests_total{status=~"[45].."}[5m])) / sum(rate(http_requests_total[5m])) * 100

# 3. Latência média por endpoint
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# 4. Top 5 endpoints mais lentos
topk(5, rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m]))

# 5. Número de conexões ativas
sum(active_connections)
```

---

## 🎓 RESUMO DO MÓDULO

### **Conceitos Aprendidos:**
- ✅ **Sintaxe PromQL:** Seletores, ranges, operadores
- ✅ **Tipos de dados:** Scalar, instant vector, range vector, matrix
- ✅ **Funções básicas:** rate, increase, delta, funções matemáticas
- ✅ **Agregações:** sum, avg, max, min, count, topk, bottomk
- ✅ **Filtragem:** Labels, regex, comparações

### **Próximos Passos:**
1. 🔍 **[Módulo 06: PromQL Avançado](06-promql-avancado.md)** - Funções complexas
2. 🚨 **[Módulo 07: Regras de Alerta](07-regras-alerta.md)** - Alertas eficazes
3. 🛠️ **[Módulo 08: Troubleshooting](08-troubleshooting.md)** - Resolução de problemas

---

**📚 Módulo Anterior:** [04 - Coleta de Métricas](04-coleta-metricas.md)  
**📚 Próximo Módulo:** [06 - PromQL Avançado](06-promql-avancado.md)  
**🏠 Voltar ao:** [README Principal](README.md)

---

*Módulo criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*
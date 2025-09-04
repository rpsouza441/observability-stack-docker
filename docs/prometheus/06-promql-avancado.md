# 🚀 MÓDULO 06: PROMQL AVANÇADO

> **Objetivo:** Dominar técnicas avançadas de PromQL para análises complexas  
> **Duração:** 120 minutos  
> **Nível:** Avançado

---

## 🎯 O QUE VOCÊ VAI APRENDER

Neste módulo você irá:
- ✅ Usar funções avançadas de agregação temporal
- ✅ Implementar joins e operações entre métricas
- ✅ Dominar funções de predição e análise
- ✅ Criar queries complexas para troubleshooting
- ✅ Otimizar performance de queries

---

## ⏰ FUNÇÕES DE AGREGAÇÃO TEMPORAL

### **📊 Funções _over_time**

```promql
# AVG_OVER_TIME - Média no período
avg_over_time(node_load1[1h])
avg_over_time(http_request_duration_seconds[5m])

# MAX_OVER_TIME - Máximo no período
max_over_time(node_cpu_seconds_total[1h])
max_over_time(http_requests_total[5m])

# MIN_OVER_TIME - Mínimo no período
min_over_time(node_memory_MemAvailable_bytes[1h])
min_over_time(http_request_duration_seconds[5m])

# SUM_OVER_TIME - Soma no período
sum_over_time(increase(http_requests_total[1m])[1h:])

# COUNT_OVER_TIME - Contagem de pontos
count_over_time(up[1h])
count_over_time(node_load1[5m])

# STDDEV_OVER_TIME - Desvio padrão
stddev_over_time(node_load1[1h])
stddev_over_time(http_request_duration_seconds[5m])

# STDVAR_OVER_TIME - Variância
stdvar_over_time(node_load1[1h])

# QUANTILE_OVER_TIME - Percentil no período
quantile_over_time(0.95, http_request_duration_seconds[1h])
quantile_over_time(0.5, node_load1[1h])  # Mediana
```

### **🎯 Casos de Uso Práticos**

```promql
# === ANÁLISE DE PERFORMANCE ===
# Pico de CPU na última hora
max_over_time((100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))[1h:])

# Latência média na última hora
avg_over_time(histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[1h:])

# Variabilidade da latência (alta = instável)
stddev_over_time(histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[1h:])

# === ANÁLISE DE CAPACIDADE ===
# Uso máximo de memória no dia
max_over_time((1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))[1d:])

# Tráfego médio de rede na semana
avg_over_time(rate(node_network_receive_bytes_total[5m])[1w:])

# === ANÁLISE DE DISPONIBILIDADE ===
# Uptime médio na última semana
avg_over_time(up[1w]) * 100

# Número de falhas no último mês
count_over_time((up == 0)[1M:])

# Tempo total de downtime no dia (em minutos)
(count_over_time((up == 0)[1d:]) * 15) / 60  # Assumindo scrape_interval=15s
```

---

## 🔗 OPERAÇÕES ENTRE MÉTRICAS (JOINS)

### **🎯 Matching de Labels**

```promql
# === ON - Especifica labels para matching ===
# CPU usage com informações de memória
(
  100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100)
) 
and on(instance) 
(
  (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
)

# Requisições por segundo com latência
rate(http_requests_total[5m])
and on(instance, job)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# === IGNORING - Ignora labels específicos ===
# Comparar métricas ignorando labels irrelevantes
node_memory_MemTotal_bytes
and ignoring(cpu, mode)
node_cpu_seconds_total
```

### **🔄 Tipos de Join**

```promql
# === ONE-TO-ONE (padrão) ===
node_memory_MemTotal_bytes
and on(instance)
node_memory_MemAvailable_bytes

# === ONE-TO-MANY ===
# Informações de servidor com métricas de CPU por core
node_uname_info
and on(instance) group_left(nodename, release)
node_cpu_seconds_total

# === MANY-TO-ONE ===
# Métricas de aplicação com informações do servidor
http_requests_total
and on(instance) group_right(version, release)
node_uname_info

# === GROUP_LEFT/GROUP_RIGHT com labels ===
# Adicionar informações do servidor às métricas de aplicação
rate(http_requests_total[5m])
and on(instance) group_left(nodename, machine)
node_uname_info
```

### **🎯 Exemplos Práticos de Joins**

```promql
# === CORRELAÇÃO CPU vs MEMÓRIA ===
# Servidores com alta CPU E alta memória
(
  100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
)
and on(instance)
(
  (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
)

# === ENRIQUECIMENTO DE DADOS ===
# Adicionar informações do OS às métricas de performance
(
  100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
)
and on(instance) group_left(nodename, release, machine)
node_uname_info

# === ANÁLISE DE APLICAÇÃO ===
# Correlacionar erros HTTP com uso de recursos
rate(http_requests_total{status=~"5.."}[5m])
and on(instance) group_left
(
  100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 70
)

# === CAPACIDADE vs DEMANDA ===
# Comparar uso atual com capacidade total
(
  rate(node_network_receive_bytes_total[5m]) / 1024 / 1024  # MB/s atual
)
and on(instance, device) group_left
(
  node_network_speed_bytes / 1024 / 1024  # Capacidade em MB/s
)
```

---

## 🔮 FUNÇÕES DE PREDIÇÃO E ANÁLISE

### **📈 PREDICT_LINEAR**

```promql
# Predição de uso de disco em 4 horas
predict_linear(node_filesystem_free_bytes[1h], 4*3600)

# Predição de crescimento de memória
predict_linear(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes[2h], 3600)

# Quando o disco ficará cheio (em segundos)
(
  node_filesystem_free_bytes - 
  predict_linear(node_filesystem_free_bytes[1h], 3600)
) / 
(
  predict_linear(node_filesystem_free_bytes[1h], 3600) - 
  predict_linear(node_filesystem_free_bytes[1h], 0)
) * 3600

# Predição de requisições por hora
predict_linear(rate(http_requests_total[5m])[30m:], 3600) * 3600

# Crescimento esperado de conexões
predict_linear(mysql_global_status_threads_connected[1h], 2*3600)
```

### **📊 DERIV - Derivada**

```promql
# Taxa de mudança do uso de memória
deriv(node_memory_MemAvailable_bytes[5m])

# Aceleração do crescimento de requisições
deriv(rate(http_requests_total[5m])[10m:])

# Tendência de crescimento do load average
deriv(node_load1[10m])

# Velocidade de mudança do uso de disco
deriv((node_filesystem_size_bytes - node_filesystem_free_bytes)[5m])
```

### **🎯 Análises Preditivas Práticas**

```promql
# === ALERTAS PREDITIVOS ===
# Disco ficará cheio em menos de 4 horas
(
  predict_linear(node_filesystem_free_bytes[1h], 4*3600) < 0
) 
and 
(
  deriv(node_filesystem_free_bytes[1h]) < 0
)

# Memória se esgotará em 2 horas
(
  predict_linear(node_memory_MemAvailable_bytes[30m], 2*3600) < 
  node_memory_MemTotal_bytes * 0.05  # Menos de 5%
)
and
(
  deriv(node_memory_MemAvailable_bytes[30m]) < 0
)

# === PLANEJAMENTO DE CAPACIDADE ===
# Crescimento esperado de tráfego em 1 semana
predict_linear(rate(node_network_receive_bytes_total[1d])[7d:], 7*24*3600)

# Projeção de conexões de banco em 24h
predict_linear(mysql_global_status_threads_connected[2h], 24*3600)

# === DETECÇÃO DE ANOMALIAS ===
# Desvio da tendência normal (crescimento anômalo)
abs(
  rate(http_requests_total[5m]) - 
  predict_linear(rate(http_requests_total[5m])[1h:], 0)
) > 
stddev_over_time(rate(http_requests_total[5m])[1h:]) * 2
```

---

## 🔍 FUNÇÕES DE ANÁLISE TEMPORAL

### **⏪ OFFSET - Comparação Temporal**

```promql
# Comparar com 1 hora atrás
node_load1 - node_load1 offset 1h

# Comparar com mesmo horário ontem
rate(http_requests_total[5m]) - rate(http_requests_total[5m]) offset 1d

# Comparar com semana passada
node_memory_MemAvailable_bytes - node_memory_MemAvailable_bytes offset 1w

# Crescimento percentual em relação a ontem
(
  rate(http_requests_total[5m]) - 
  rate(http_requests_total[5m]) offset 1d
) / 
rate(http_requests_total[5m]) offset 1d * 100

# Variação de CPU em relação à hora anterior
(
  100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100)
) - 
(
  100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100) offset 1h
)
```

### **📅 Análises Sazonais**

```promql
# === COMPARAÇÕES DIÁRIAS ===
# Tráfego atual vs mesmo horário ontem
rate(http_requests_total[5m]) / rate(http_requests_total[5m]) offset 1d

# Diferença de load em relação a ontem
node_load1 - node_load1 offset 1d

# === COMPARAÇÕES SEMANAIS ===
# Performance atual vs semana passada
(
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
) / (
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) offset 1w
)

# === DETECÇÃO DE PADRÕES ===
# Identificar picos anômalos (>50% acima do normal)
(
  rate(http_requests_total[5m]) > 
  rate(http_requests_total[5m]) offset 1d * 1.5
)
and
(
  rate(http_requests_total[5m]) > 
  avg_over_time(rate(http_requests_total[5m])[1d:]) * 1.5
)
```

---

## 🧮 FUNÇÕES MATEMÁTICAS AVANÇADAS

### **📊 Funções Estatísticas**

```promql
# === CLAMP - Limitar valores ===
# Limitar CPU entre 0 e 100
clamp(
  100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100),
  0, 100
)

# Limitar latência máxima
clamp_max(
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])),
  10  # Máximo 10 segundos
)

# Limitar valor mínimo
clamp_min(node_load1, 0)

# === SORT - Ordenação ===
# Ordenar por valor (crescente)
sort(node_load1)

# Ordenar por valor (decrescente)
sort_desc(node_load1)

# === ABSENT - Detectar métricas ausentes ===
# Alertar se métrica não existe
absent(up{job="critical-service"})

# Alertar se não há requisições
absent(rate(http_requests_total[5m]))

# Verificar se target específico está ausente
absent(up{instance="critical-server:9100"})
```

### **🔢 Transformações Matemáticas**

```promql
# === SGML - Sinal ===
# Detectar tendência (positiva/negativa/zero)
sgn(deriv(node_memory_MemAvailable_bytes[5m]))

# === RESETS - Detectar resets de counter ===
# Quantos resets teve um counter
resets(http_requests_total[1h])

# === CHANGES - Detectar mudanças ===
# Quantas vezes o valor mudou
changes(up[1h])

# === HOLT_WINTERS - Suavização exponencial ===
# Predição com sazonalidade
holt_winters(rate(http_requests_total[5m])[1h:], 0.3, 0.3)

# Suavização de métricas ruidosas
holt_winters(node_load1[30m:], 0.5, 0.5)
```

---

## 🎯 QUERIES COMPLEXAS PARA TROUBLESHOOTING

### **🚨 Detecção de Anomalias**

```promql
# === ANOMALIAS DE PERFORMANCE ===
# CPU anormalmente alto (>3 desvios padrão)
(
  100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100)
) > (
  avg_over_time((100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))[1h:]) +
  3 * stddev_over_time((100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))[1h:])
)

# Latência anômala (P95 > média + 2*stddev)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) >
(
  avg_over_time(histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[1h:]) +
  2 * stddev_over_time(histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[1h:])
)

# === CORRELAÇÃO DE PROBLEMAS ===
# Servidores com problemas múltiplos
(
  # Alta CPU
  100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
)
and on(instance)
(
  # Alta memória
  (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
)
and on(instance)
(
  # Alto load
  node_load1 > 2
)

# === DETECÇÃO DE GARGALOS ===
# Endpoints com alta latência E alto volume
(
  histogram_quantile(0.95, sum by(endpoint, le) (rate(http_request_duration_seconds_bucket[5m]))) > 1
)
and on(endpoint)
(
  sum by(endpoint) (rate(http_requests_total[5m])) > 10
)
```

### **📊 Análise de Capacidade**

```promql
# === UTILIZAÇÃO DE RECURSOS ===
# Score de utilização geral do servidor (0-100)
(
  # CPU (peso 30%)
  (100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) * 0.3 +
  # Memória (peso 30%)
  ((1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100) * 0.3 +
  # Disco (peso 25%)
  ((1 - (node_filesystem_free_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100) * 0.25 +
  # Load (peso 15%)
  (node_load1 / on(instance) group_left count by(instance) (node_cpu_seconds_total{mode="idle"})) * 100 * 0.15
)

# === RANKING DE PERFORMANCE ===
# Top servidores por score de performance
topk(10,
  # Latência de disco (peso 40%)
  (rate(node_disk_io_time_seconds_total[5m]) * 100) * 0.4 +
  # CPU wait (peso 30%)
  (rate(node_cpu_seconds_total{mode="iowait"}[5m]) * 100) * 0.3 +
  # Load average (peso 30%)
  (node_load1 / on(instance) group_left count by(instance) (node_cpu_seconds_total{mode="idle"})) * 100 * 0.3
)

# === PREVISÃO DE SATURAÇÃO ===
# Recursos que atingirão 90% em 2 horas
(
  predict_linear(
    (1 - (node_filesystem_free_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100
    [1h], 2*3600
  ) > 90
)
and
(
  deriv(
    (1 - (node_filesystem_free_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100
    [1h]
  ) > 0
)
```

### **🔍 Análise de Padrões**

```promql
# === DETECÇÃO DE CICLOS ===
# Variação cíclica de CPU (detectar padrões)
stddev_over_time(
  100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100)
  [1h:]
) / 
avg_over_time(
  100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100)
  [1h:]
)

# === ANÁLISE DE TENDÊNCIAS ===
# Crescimento sustentado (3 pontos consecutivos crescendo)
(
  rate(http_requests_total[5m]) > rate(http_requests_total[5m]) offset 5m
)
and
(
  rate(http_requests_total[5m]) offset 5m > rate(http_requests_total[5m]) offset 10m
)
and
(
  rate(http_requests_total[5m]) offset 10m > rate(http_requests_total[5m]) offset 15m
)

# === DETECÇÃO DE OUTLIERS ===
# Servidores com comportamento atípico
abs(
  100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) -
  avg(100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))
) > 
2 * stddev(100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))
```

---

## ⚡ OTIMIZAÇÃO DE PERFORMANCE

### **🚀 Boas Práticas**

```promql
# ❌ EVITAR - Query muito ampla
{__name__=~".*"}

# ✅ PREFERIR - Query específica
node_cpu_seconds_total{mode="idle"}

# ❌ EVITAR - Regex complexa desnecessária
http_requests_total{endpoint=~".*api.*v1.*users.*"}

# ✅ PREFERIR - Labels específicos
http_requests_total{service="api", version="v1", resource="users"}

# ❌ EVITAR - Ranges muito longos sem necessidade
rate(http_requests_total[1d])

# ✅ PREFERIR - Range apropriado
rate(http_requests_total[5m])

# ❌ EVITAR - Múltiplas agregações desnecessárias
sum(avg(max(node_load1)))

# ✅ PREFERIR - Agregação direta
avg(node_load1)
```

### **📊 Técnicas de Otimização**

```promql
# === USAR RECORDING RULES ===
# Em vez de repetir esta query complexa:
histogram_quantile(0.95, 
  sum by(job, endpoint, le) (
    rate(http_request_duration_seconds_bucket[5m])
  )
)

# Criar recording rule:
# groups:
# - name: http_latency
#   rules:
#   - record: http:request_duration_seconds:p95
#     expr: histogram_quantile(0.95, sum by(job, endpoint, le) (rate(http_request_duration_seconds_bucket[5m])))

# Usar a recording rule:
http:request_duration_seconds:p95

# === FILTRAR CEDO ===
# ❌ Filtrar depois da agregação
sum(rate(http_requests_total[5m])) and on() (up{job="web"} == 1)

# ✅ Filtrar antes da agregação
sum(rate(http_requests_total{job="web"}[5m]))

# === USAR SUBQUERIES EFICIENTEMENTE ===
# ❌ Subquery desnecessária
avg_over_time(rate(http_requests_total[5m])[1h:])

# ✅ Função direta quando possível
avg_over_time(increase(http_requests_total[5m])[1h:]) / 300  # 5m = 300s
```

---

## 🧪 EXERCÍCIOS AVANÇADOS

### **🎯 Exercício 1: Análise Preditiva**

```promql
# 1. Prediga quando o disco /var ficará cheio
predict_linear(
  node_filesystem_free_bytes{mountpoint="/var"}[2h], 
  4*3600
) < 0

# 2. Detecte crescimento anômalo de memória
deriv(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes[1h]) >
2 * stddev_over_time(
  deriv(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes[1h])[1d:]
)

# 3. Preveja pico de tráfego baseado em tendência
predict_linear(rate(http_requests_total[5m])[1h:], 2*3600) >
max_over_time(rate(http_requests_total[5m])[1w:]) * 1.5
```

### **🎯 Exercício 2: Correlação de Métricas**

```promql
# 1. Encontre servidores com alta CPU correlacionada com alta latência
(
  100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 70
)
and on(instance) group_left
(
  avg by(instance) (histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))) > 1
)

# 2. Identifique aplicações com erros correlacionados com recursos
rate(http_requests_total{status=~"5.."}[5m])
and on(instance) group_left
(
  (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
)

# 3. Compare performance atual com semana passada
(
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
) / (
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) offset 1w
) > 1.3  # 30% pior que semana passada
```

### **🎯 Exercício 3: Detecção de Anomalias**

```promql
# 1. Detecte outliers de CPU (>2 desvios padrão)
abs(
  100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) -
  avg(100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))
) > 
2 * stddev(100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))

# 2. Identifique padrões anômalos de requisições
abs(
  rate(http_requests_total[5m]) - 
  avg_over_time(rate(http_requests_total[5m])[1h:])
) > 
3 * stddev_over_time(rate(http_requests_total[5m])[1h:])

# 3. Detecte mudanças bruscas de comportamento
abs(
  rate(http_requests_total[5m]) - 
  rate(http_requests_total[5m]) offset 15m
) > 
stddev_over_time(rate(http_requests_total[5m])[1h:]) * 2
```

---

## 🎓 RESUMO DO MÓDULO

### **Conceitos Avançados Aprendidos:**
- ✅ **Agregação temporal:** _over_time functions
- ✅ **Joins complexos:** on, ignoring, group_left/right
- ✅ **Predição:** predict_linear, deriv, holt_winters
- ✅ **Análise temporal:** offset, comparações sazonais
- ✅ **Detecção de anomalias:** outliers, padrões anômalos
- ✅ **Otimização:** performance, recording rules

### **Próximos Passos:**
1. 🚨 **[Módulo 07: Regras de Alerta](07-regras-alerta.md)** - Alertas inteligentes
2. 🛠️ **[Módulo 08: Troubleshooting](08-troubleshooting.md)** - Resolução de problemas
3. 📊 **[Módulo 09: Integração Grafana](09-integracao-grafana.md)** - Visualizações

---

**📚 Módulo Anterior:** [05 - PromQL Básico](05-promql-basico.md)  
**📚 Próximo Módulo:** [07 - Regras de Alerta](07-regras-alerta.md)  
**🏠 Voltar ao:** [README Principal](README.md)

---

*Módulo criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*
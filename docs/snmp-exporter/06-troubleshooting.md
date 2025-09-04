# 🔧 MÓDULO 06: TROUBLESHOOTING

> **Diagnóstico e resolução de problemas no monitoramento SNMP**

## 🎯 Objetivos do Módulo

Ao final deste módulo, você será capaz de:

- ✅ Diagnosticar problemas de conectividade SNMP
- ✅ Analisar logs do SNMP Exporter e Prometheus
- ✅ Resolver problemas de configuração
- ✅ Otimizar performance do monitoramento
- ✅ Implementar monitoramento proativo de problemas

---

## 🚨 Problemas Comuns e Soluções

### 1. Conectividade SNMP

#### Problema: "No Such Instance"
```bash
# Erro comum
SNMP Error: No Such Instance currently exists at this OID
```

**Causas Possíveis:**
- OID não existe no dispositivo
- Versão SNMP incorreta
- Community string inválida
- Dispositivo não suporta a MIB

**Diagnóstico:**
```bash
# Testar conectividade básica
snmpget -v2c -c public 192.168.1.10 1.3.6.1.2.1.1.1.0

# Verificar se OID existe
snmpwalk -v2c -c public 192.168.1.10 1.3.6.1.2.1.1

# Testar com diferentes versões
snmpget -v1 -c public 192.168.1.10 1.3.6.1.2.1.1.1.0
snmpget -v3 -u username -l noAuthNoPriv 192.168.1.10 1.3.6.1.2.1.1.1.0
```

**Soluções:**
```yaml
# Ajustar configuração no snmp.yml
modules:
  device_debug:
    walk:
      - 1.3.6.1.2.1.1.1.0  # Testar OID básico primeiro
    walk_params:
      timeout: 20s
      retries: 5
      max_repetitions: 10  # Reduzir para dispositivos lentos
```

#### Problema: Timeout
```
SNMP Error: Timeout
```

**Causas Possíveis:**
- Dispositivo sobrecarregado
- Rede congestionada
- Firewall bloqueando porta 161
- Configuração de timeout muito baixa

**Diagnóstico:**
```bash
# Testar conectividade de rede
ping 192.168.1.10

# Testar porta SNMP
nmap -sU -p 161 192.168.1.10

# Testar com timeout maior
snmpget -v2c -c public -t 10 192.168.1.10 1.3.6.1.2.1.1.1.0
```

**Soluções:**
```yaml
# Aumentar timeouts
modules:
  slow_device:
    walk:
      - 1.3.6.1.2.1.2.2.1.2
    walk_params:
      timeout: 30s
      retries: 3
      max_repetitions: 10
```

#### Problema: "Authentication Failure"
```
SNMP Error: Authentication failure
```

**Causas Possíveis:**
- Community string incorreta
- Credenciais SNMPv3 inválidas
- ACL no dispositivo bloqueando acesso

**Diagnóstico:**
```bash
# Testar diferentes communities
snmpget -v2c -c public 192.168.1.10 1.3.6.1.2.1.1.1.0
snmpget -v2c -c private 192.168.1.10 1.3.6.1.2.1.1.1.0
snmpget -v2c -c readonly 192.168.1.10 1.3.6.1.2.1.1.1.0

# Para SNMPv3
snmpget -v3 -u admin -l authPriv -a SHA -A password123 -x AES -X password123 192.168.1.10 1.3.6.1.2.1.1.1.0
```

**Soluções:**
```yaml
# Configurar autenticação correta
auths:
  public_v2:
    community: public
    version: 2
  
  secure_v3:
    username: admin
    security_level: authPriv
    password: password123
    auth_protocol: SHA
    priv_protocol: AES
    priv_password: password123
    version: 3
```

### 2. Problemas de Performance

#### Problema: Scrapes Lentos
```
Scrape took longer than expected
```

**Diagnóstico:**
```bash
# Testar tempo de resposta
time snmpwalk -v2c -c public 192.168.1.10 1.3.6.1.2.1.2.2.1.2

# Verificar número de interfaces
snmpwalk -v2c -c public 192.168.1.10 1.3.6.1.2.1.2.1.0
```

**Soluções:**
```yaml
# Otimizar configuração
modules:
  optimized_switch:
    walk:
      # Reduzir OIDs coletados
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
    
    walk_params:
      timeout: 10s
      retries: 2
      max_repetitions: 50  # Aumentar para dispositivos rápidos
    
    # Filtrar interfaces desnecessárias
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2
        drop_source_indexes: false
    
    overrides:
      ifOperStatus:
        type: gauge
```

#### Problema: Alto Uso de CPU no SNMP Exporter

**Diagnóstico:**
```bash
# Verificar uso de recursos
docker stats snmp-exporter

# Verificar logs
docker logs snmp-exporter
```

**Soluções:**
```yaml
# docker-compose.yml - Limitar recursos
services:
  snmp-exporter:
    image: prom/snmp-exporter:latest
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    environment:
      - GOMAXPROCS=2
```

### 3. Problemas de Configuração

#### Problema: Métricas Não Aparecem

**Diagnóstico:**
```bash
# Verificar se SNMP Exporter está coletando
curl "http://localhost:9116/snmp?target=192.168.1.10&module=if_mib"

# Verificar targets no Prometheus
curl "http://localhost:9090/api/v1/targets"

# Verificar métricas específicas
curl "http://localhost:9090/api/v1/query?query=up{job='snmp'}"
```

**Soluções:**
```yaml
# Verificar configuração do Prometheus
scrape_configs:
  - job_name: 'snmp'
    static_configs:
      - targets:
        - 192.168.1.10
    metrics_path: /snmp
    params:
      module: [if_mib]  # Verificar se módulo existe
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116  # Verificar endereço
```

#### Problema: Configuração YAML Inválida

**Diagnóstico:**
```bash
# Validar sintaxe YAML
yamllint snmp.yml

# Testar configuração do SNMP Exporter
docker run --rm -v $(pwd)/snmp.yml:/etc/snmp_exporter/snmp.yml prom/snmp-exporter --config.check

# Verificar logs de inicialização
docker logs snmp-exporter
```

**Exemplo de Erro Comum:**
```yaml
# INCORRETO - indentação errada
modules:
if_mib:
  walk:
    - 1.3.6.1.2.1.2.2.1.2

# CORRETO
modules:
  if_mib:
    walk:
      - 1.3.6.1.2.1.2.2.1.2
```

---

## 📊 Análise de Logs

### 1. Logs do SNMP Exporter

#### Configuração de Log Level
```bash
# Executar com debug
docker run -p 9116:9116 -v $(pwd)/snmp.yml:/etc/snmp_exporter/snmp.yml \
  prom/snmp-exporter --log.level=debug
```

#### Tipos de Logs

**Logs Normais:**
```
level=info ts=2024-01-15T10:30:00.000Z caller=main.go:123 msg="Starting snmp_exporter" version=0.21.0
level=info ts=2024-01-15T10:30:00.001Z caller=main.go:134 msg="Loaded config file" file=/etc/snmp_exporter/snmp.yml
level=info ts=2024-01-15T10:30:00.002Z caller=main.go:145 msg="Listening on address" address=:9116
```

**Logs de Erro:**
```
level=error ts=2024-01-15T10:30:15.123Z caller=collector.go:123 msg="Error scraping target" target=192.168.1.10 module=if_mib error="context deadline exceeded"
level=warn ts=2024-01-15T10:30:15.124Z caller=collector.go:145 msg="SNMP request failed" target=192.168.1.10 oid=1.3.6.1.2.1.2.2.1.2 error="No Such Instance"
```

**Logs de Debug:**
```
level=debug ts=2024-01-15T10:30:15.125Z caller=collector.go:167 msg="Walking OID" target=192.168.1.10 oid=1.3.6.1.2.1.2.2.1.2
level=debug ts=2024-01-15T10:30:15.126Z caller=collector.go:189 msg="Got SNMP response" target=192.168.1.10 oid=1.3.6.1.2.1.2.2.1.2.1 value="GigabitEthernet0/1"
```

### 2. Logs do Prometheus

#### Verificar Scrape Errors
```bash
# Verificar logs do Prometheus
docker logs prometheus | grep -i error

# Verificar targets com problema
curl "http://localhost:9090/api/v1/targets" | jq '.data.activeTargets[] | select(.health != "up")'
```

**Exemplo de Logs:**
```
level=warn ts=2024-01-15T10:30:20.000Z caller=scrape.go:1234 component="scrape manager" scrape_pool=snmp target=http://snmp-exporter:9116/snmp?module=if_mib&target=192.168.1.10 msg="append failed" err="context deadline exceeded"
```

### 3. Script de Análise de Logs

```bash
#!/bin/bash
# analyze_logs.sh

LOG_FILE=${1:-"/var/log/snmp_exporter.log"}
TIME_RANGE=${2:-"1h"}

echo "=== Análise de Logs SNMP Exporter ==="
echo "Arquivo: $LOG_FILE"
echo "Período: últimas $TIME_RANGE"
echo

# Contar tipos de log
echo "--- Resumo por Nível ---"
grep -o 'level=[a-z]*' $LOG_FILE | sort | uniq -c | sort -nr
echo

# Erros mais comuns
echo "--- Erros Mais Comuns ---"
grep 'level=error' $LOG_FILE | grep -o 'error="[^"]*"' | sort | uniq -c | sort -nr | head -10
echo

# Targets com problema
echo "--- Targets com Problema ---"
grep 'level=error\|level=warn' $LOG_FILE | grep -o 'target=[0-9.]*' | sort | uniq -c | sort -nr
echo

# Timeouts
echo "--- Timeouts ---"
grep 'timeout\|deadline exceeded' $LOG_FILE | wc -l
echo

# OIDs problemáticos
echo "--- OIDs com Erro ---"
grep 'No Such Instance\|No Such Object' $LOG_FILE | grep -o 'oid=[0-9.]*' | sort | uniq -c | sort -nr | head -10
echo

# Performance
echo "--- Scrapes Lentos (>10s) ---"
grep 'scrape_duration_seconds' $LOG_FILE | awk '$NF > 10 {print}' | wc -l
```

---

## 🔍 Ferramentas de Diagnóstico

### 1. Script de Teste de Conectividade

```bash
#!/bin/bash
# snmp_connectivity_test.sh

TARGET=$1
COMMUNITY=${2:-public}
MODULE=${3:-if_mib}

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <IP> [community] [module]"
    exit 1
fi

echo "=== Teste de Conectividade SNMP ==="
echo "Target: $TARGET"
echo "Community: $COMMUNITY"
echo "Module: $MODULE"
echo

# Teste 1: Ping
echo "1. Testando conectividade de rede..."
if ping -c 3 $TARGET >/dev/null 2>&1; then
    echo "   ✓ Ping OK"
else
    echo "   ✗ Ping FALHOU"
    exit 1
fi

# Teste 2: Porta SNMP
echo "2. Testando porta SNMP (161/UDP)..."
if timeout 5 bash -c "echo > /dev/udp/$TARGET/161" 2>/dev/null; then
    echo "   ✓ Porta 161 acessível"
else
    echo "   ⚠ Porta 161 pode estar bloqueada"
fi

# Teste 3: SNMP básico
echo "3. Testando SNMP básico..."
if timeout 10 snmpget -v2c -c $COMMUNITY $TARGET 1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
    echo "   ✓ SNMP v2c OK"
    
    # Obter informações do sistema
    SYS_DESCR=$(snmpget -v2c -c $COMMUNITY $TARGET 1.3.6.1.2.1.1.1.0 -Oqv 2>/dev/null)
    SYS_NAME=$(snmpget -v2c -c $COMMUNITY $TARGET 1.3.6.1.2.1.1.5.0 -Oqv 2>/dev/null)
    SYS_UPTIME=$(snmpget -v2c -c $COMMUNITY $TARGET 1.3.6.1.2.1.1.3.0 -Oqv 2>/dev/null)
    
    echo "   Sistema: $SYS_DESCR"
    echo "   Nome: $SYS_NAME"
    echo "   Uptime: $SYS_UPTIME"
else
    echo "   ✗ SNMP v2c FALHOU"
    
    # Testar v1
    if timeout 10 snmpget -v1 -c $COMMUNITY $TARGET 1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
        echo "   ✓ SNMP v1 OK"
    else
        echo "   ✗ SNMP v1 também falhou"
        exit 1
    fi
fi

# Teste 4: SNMP Exporter
echo "4. Testando SNMP Exporter..."
if curl -s "http://localhost:9116/snmp?target=$TARGET&module=$MODULE" >/dev/null; then
    echo "   ✓ SNMP Exporter OK"
    
    # Contar métricas
    METRICS_COUNT=$(curl -s "http://localhost:9116/snmp?target=$TARGET&module=$MODULE" | grep -c '^[a-zA-Z]')
    echo "   Métricas coletadas: $METRICS_COUNT"
else
    echo "   ✗ SNMP Exporter FALHOU"
fi

# Teste 5: Prometheus
echo "5. Testando integração com Prometheus..."
if curl -s "http://localhost:9090/api/v1/query?query=up{instance='$TARGET'}" | grep -q '"value"'; then
    echo "   ✓ Prometheus OK"
else
    echo "   ✗ Prometheus não está coletando dados"
fi

echo
echo "=== Teste Concluído ==="
```

### 2. Script de Validação de Configuração

```python
#!/usr/bin/env python3
# validate_snmp_config.py

import yaml
import sys
import requests
from pysnmp.hlapi import *

def validate_yaml_syntax(config_file):
    """Valida sintaxe YAML"""
    try:
        with open(config_file, 'r') as f:
            yaml.safe_load(f)
        print("✓ Sintaxe YAML válida")
        return True
    except yaml.YAMLError as e:
        print(f"✗ Erro de sintaxe YAML: {e}")
        return False

def validate_modules(config_file):
    """Valida estrutura dos módulos"""
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    
    if 'modules' not in config:
        print("✗ Seção 'modules' não encontrada")
        return False
    
    print(f"✓ Encontrados {len(config['modules'])} módulos")
    
    for module_name, module_config in config['modules'].items():
        print(f"  Validando módulo: {module_name}")
        
        # Verificar walk ou get
        if 'walk' not in module_config and 'get' not in module_config:
            print(f"    ✗ Módulo {module_name} deve ter 'walk' ou 'get'")
            continue
        
        # Verificar OIDs
        oids = module_config.get('walk', []) + module_config.get('get', [])
        for oid in oids:
            if not oid.replace('.', '').isdigit():
                print(f"    ⚠ OID suspeito: {oid}")
        
        print(f"    ✓ {len(oids)} OIDs configurados")
    
    return True

def test_snmp_exporter(target, module):
    """Testa SNMP Exporter"""
    try:
        url = f"http://localhost:9116/snmp?target={target}&module={module}"
        response = requests.get(url, timeout=30)
        
        if response.status_code == 200:
            metrics = [line for line in response.text.split('\n') if line and not line.startswith('#')]
            print(f"✓ SNMP Exporter OK - {len(metrics)} métricas")
            return True
        else:
            print(f"✗ SNMP Exporter erro: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Erro ao testar SNMP Exporter: {e}")
        return False

def test_snmp_connectivity(target, community):
    """Testa conectividade SNMP direta"""
    try:
        for (errorIndication, errorStatus, errorIndex, varBinds) in nextCmd(
            SnmpEngine(),
            CommunityData(community),
            UdpTransportTarget((target, 161)),
            ContextData(),
            ObjectType(ObjectIdentity('1.3.6.1.2.1.1.1.0')),
            lexicographicMode=False,
            maxRows=1):
            
            if errorIndication:
                print(f"✗ SNMP erro: {errorIndication}")
                return False
            elif errorStatus:
                print(f"✗ SNMP erro: {errorStatus.prettyPrint()}")
                return False
            else:
                print(f"✓ SNMP conectividade OK")
                return True
    except Exception as e:
        print(f"✗ Erro SNMP: {e}")
        return False

def main():
    if len(sys.argv) < 4:
        print("Uso: python3 validate_snmp_config.py <config.yml> <target_ip> <module>")
        sys.exit(1)
    
    config_file = sys.argv[1]
    target = sys.argv[2]
    module = sys.argv[3]
    
    print("=== Validação de Configuração SNMP ===")
    print(f"Config: {config_file}")
    print(f"Target: {target}")
    print(f"Module: {module}")
    print()
    
    # Validar YAML
    if not validate_yaml_syntax(config_file):
        sys.exit(1)
    
    # Validar módulos
    if not validate_modules(config_file):
        sys.exit(1)
    
    # Testar conectividade SNMP
    test_snmp_connectivity(target, 'public')
    
    # Testar SNMP Exporter
    test_snmp_exporter(target, module)
    
    print("\n=== Validação Concluída ===")

if __name__ == "__main__":
    main()
```

### 3. Dashboard de Monitoramento do SNMP Exporter

```json
{
  "dashboard": {
    "title": "SNMP Exporter Health",
    "panels": [
      {
        "title": "SNMP Exporter Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job='snmp-exporter'}",
            "legendFormat": "SNMP Exporter"
          }
        ]
      },
      {
        "title": "Scrape Duration",
        "type": "graph",
        "targets": [
          {
            "expr": "snmp_scrape_duration_seconds",
            "legendFormat": "{{instance}} - {{module}}"
          }
        ]
      },
      {
        "title": "SNMP Timeouts",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(snmp_request_errors_total{error='timeout'}[5m])",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "title": "Failed Targets",
        "type": "table",
        "targets": [
          {
            "expr": "up{job=~'snmp.*'} == 0",
            "format": "table"
          }
        ]
      }
    ]
  }
}
```

---

## 🚨 Alertas de Monitoramento

### 1. Alertas para Problemas de Conectividade

```yaml
# alerts.yml
groups:
  - name: snmp_exporter_health
    rules:
      # SNMP Exporter Down
      - alert: SNMPExporterDown
        expr: up{job="snmp-exporter"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "SNMP Exporter está down"
          description: "O SNMP Exporter não está respondendo há {{ $value }} minutos."
      
      # Target SNMP Down
      - alert: SNMPTargetDown
        expr: up{job=~"snmp.*"} == 0
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Target SNMP {{ $labels.instance }} está inacessível"
          description: "O dispositivo {{ $labels.instance }} não está respondendo via SNMP há {{ $value }} minutos."
      
      # Scrape Duration High
      - alert: SNMPScrapeDurationHigh
        expr: snmp_scrape_duration_seconds > 30
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Scrape SNMP lento para {{ $labels.instance }}"
          description: "O scrape do dispositivo {{ $labels.instance }} está levando {{ $value }}s para completar."
      
      # SNMP Request Errors
      - alert: SNMPRequestErrors
        expr: rate(snmp_request_errors_total[5m]) > 0.1
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "Erros SNMP em {{ $labels.instance }}"
          description: "Dispositivo {{ $labels.instance }} apresentando {{ $value }} erros SNMP por segundo."
      
      # SNMP Timeouts
      - alert: SNMPTimeouts
        expr: rate(snmp_request_errors_total{error="timeout"}[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Timeouts SNMP em {{ $labels.instance }}"
          description: "Dispositivo {{ $labels.instance }} apresentando {{ $value }} timeouts por segundo."
```

### 2. Alertas de Performance

```yaml
groups:
  - name: snmp_performance
    rules:
      # High Memory Usage
      - alert: SNMPExporterHighMemory
        expr: |
          (
            container_memory_usage_bytes{name="snmp-exporter"} / 
            container_spec_memory_limit_bytes{name="snmp-exporter"}
          ) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "SNMP Exporter usando muita memória"
          description: "SNMP Exporter está usando {{ $value }}% da memória disponível."
      
      # High CPU Usage
      - alert: SNMPExporterHighCPU
        expr: |
          rate(container_cpu_usage_seconds_total{name="snmp-exporter"}[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "SNMP Exporter usando muita CPU"
          description: "SNMP Exporter está usando {{ $value }}% de CPU."
      
      # Too Many Concurrent Scrapes
      - alert: SNMPTooManyConcurrentScrapes
        expr: snmp_concurrent_requests > 10
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "Muitas requisições SNMP concorrentes"
          description: "SNMP Exporter tem {{ $value }} requisições concorrentes ativas."
```

---

## 🔧 Otimização e Tuning

### 1. Configuração de Performance

```yaml
# snmp.yml - Configuração otimizada
modules:
  optimized_device:
    walk:
      # Apenas OIDs essenciais
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
    
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
    
    overrides:
      ifOperStatus:
        type: gauge
    
    walk_params:
      timeout: 10s
      retries: 2
      max_repetitions: 50  # Otimizado para dispositivos rápidos
      
  slow_device:
    walk:
      - 1.3.6.1.2.1.1.3.0
      - 1.3.6.1.2.1.2.2.1.8
    
    walk_params:
      timeout: 30s
      retries: 3
      max_repetitions: 10  # Reduzido para dispositivos lentos
```

### 2. Configuração do Prometheus

```yaml
# prometheus.yml - Configuração otimizada
global:
  scrape_interval: 60s
  evaluation_interval: 60s
  external_labels:
    monitor: 'snmp-monitor'

scrape_configs:
  # Dispositivos críticos - scrape frequente
  - job_name: 'snmp-critical'
    scrape_interval: 30s
    scrape_timeout: 25s
    static_configs:
      - targets: ['192.168.1.1', '192.168.1.10']
    metrics_path: /snmp
    params:
      module: [optimized_device]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
  
  # Dispositivos normais - scrape padrão
  - job_name: 'snmp-normal'
    scrape_interval: 60s
    scrape_timeout: 50s
    static_configs:
      - targets: ['192.168.1.11', '192.168.1.12']
    metrics_path: /snmp
    params:
      module: [optimized_device]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
  
  # Dispositivos lentos - scrape menos frequente
  - job_name: 'snmp-slow'
    scrape_interval: 120s
    scrape_timeout: 90s
    static_configs:
      - targets: ['192.168.1.20']
    metrics_path: /snmp
    params:
      module: [slow_device]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
```

### 3. Monitoramento de Resources

```yaml
# docker-compose.yml - Monitoramento de recursos
version: '3.8'

services:
  snmp-exporter:
    image: prom/snmp-exporter:latest
    container_name: snmp-exporter
    ports:
      - "9116:9116"
    volumes:
      - ./snmp.yml:/etc/snmp_exporter/snmp.yml:ro
    environment:
      - GOMAXPROCS=2
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9116/"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

---

## 📝 Exercícios Práticos

### Exercício 1: Diagnóstico de Conectividade
1. Execute o script de teste de conectividade
2. Identifique e resolva problemas encontrados
3. Valide a correção

### Exercício 2: Análise de Logs
1. Configure logs em modo debug
2. Analise logs de erro
3. Implemente correções baseadas nos logs

### Exercício 3: Otimização de Performance
1. Identifique scrapes lentos
2. Otimize configurações
3. Monitore melhorias de performance

---

## 📝 Resumo do Módulo

Neste módulo, você aprendeu:

- ✅ **Diagnóstico de problemas** de conectividade SNMP
- ✅ **Análise de logs** do SNMP Exporter e Prometheus
- ✅ **Resolução de problemas** de configuração
- ✅ **Ferramentas de diagnóstico** automatizadas
- ✅ **Alertas proativos** para monitoramento
- ✅ **Otimização de performance** do sistema
- ✅ **Monitoramento de recursos** do SNMP Exporter

### 🎯 Próximos Passos

Agora você está pronto para:

1. **Implementar um projeto completo** de monitoramento SNMP
2. **Integrar todas as funcionalidades** aprendidas
3. **Criar um ambiente de produção** robusto

---

## 🔗 Navegação

- ⬅️ **Anterior:** [Módulo 05 - Dispositivos de Rede](05-dispositivos-rede.md)
- ➡️ **Próximo:** [Módulo 07 - Projeto Final](07-projeto-final.md)

---

**📚 Módulo 06 de 07 - Troubleshooting**
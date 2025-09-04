# Documentação: snmp.yml

## Visão Geral

O arquivo `snmp.yml` configura o SNMP Exporter, definindo módulos para diferentes tipos de dispositivos de rede. Cada módulo especifica quais OIDs (Object Identifiers) coletar, como processar os dados e como mapear valores para métricas do Prometheus. Esta configuração é essencial para monitorar switches, roteadores, access points e outros dispositivos de rede via SNMP.

## Estrutura dos Módulos

### 1. Módulo Padrão - Interfaces de Rede (if_mib)

```yaml
if_mib:
  walk:
    - 1.3.6.1.2.1.2.2.1.2   # ifDescr
    - 1.3.6.1.2.1.2.2.1.3   # ifType
    - 1.3.6.1.2.1.2.2.1.5   # ifSpeed
    - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
    - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
```

**OIDs Principais:**
- **ifDescr (1.3.6.1.2.1.2.2.1.2)**: Descrição da interface
- **ifType (1.3.6.1.2.1.2.2.1.3)**: Tipo da interface (Ethernet, WiFi, etc.)
- **ifSpeed (1.3.6.1.2.1.2.2.1.5)**: Velocidade da interface em bps
- **ifAdminStatus (1.3.6.1.2.1.2.2.1.7)**: Status administrativo (up/down)
- **ifOperStatus (1.3.6.1.2.1.2.2.1.8)**: Status operacional (up/down)
- **ifInOctets (1.3.6.1.2.1.2.2.1.10)**: Bytes recebidos
- **ifOutOctets (1.3.6.1.2.1.2.2.1.16)**: Bytes enviados

**Contadores de Tráfego:**
```yaml
# Contadores básicos (32-bit)
- 1.3.6.1.2.1.2.2.1.10  # ifInOctets
- 1.3.6.1.2.1.2.2.1.11  # ifInUcastPkts
- 1.3.6.1.2.1.2.2.1.12  # ifInNUcastPkts
- 1.3.6.1.2.1.2.2.1.13  # ifInDiscards
- 1.3.6.1.2.1.2.2.1.14  # ifInErrors
- 1.3.6.1.2.1.2.2.1.16  # ifOutOctets
- 1.3.6.1.2.1.2.2.1.17  # ifOutUcastPkts
- 1.3.6.1.2.1.2.2.1.18  # ifOutNUcastPkts
- 1.3.6.1.2.1.2.2.1.19  # ifOutDiscards
- 1.3.6.1.2.1.2.2.1.20  # ifOutErrors

# Contadores de alta capacidade (64-bit) - RFC 3273
- 1.3.6.1.2.1.31.1.1.1.6   # ifHCInOctets
- 1.3.6.1.2.1.31.1.1.1.10  # ifHCOutOctets
- 1.3.6.1.2.1.31.1.1.1.15  # ifHighSpeed (Mbps)
```

### 2. Lookups e Mapeamentos

```yaml
lookups:
  - source_indexes: [ifIndex]
    lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
    drop_source_indexes: false
  - source_indexes: [ifIndex]
    lookup: 1.3.6.1.2.1.31.1.1.1.1  # ifName
    drop_source_indexes: false
```

**Função dos Lookups:**
- **source_indexes**: Índices usados como chave
- **lookup**: OID para buscar valor descritivo
- **drop_source_indexes**: Se deve manter índices originais

### 3. Overrides (Conversões de Tipo)

```yaml
overrides:
  ifType:
    type: EnumAsInfo
  ifAdminStatus:
    type: EnumAsStateSet
  ifOperStatus:
    type: EnumAsStateSet
```

**Tipos de Override:**
- **EnumAsInfo**: Converte enum para label informativo
- **EnumAsStateSet**: Converte enum para conjunto de estados (0/1)
- **DisplayString**: Trata como string de texto
- **Counter32/Counter64**: Contadores que podem dar wrap
- **Gauge32**: Valores instantâneos

## Módulos Específicos por Dispositivo

### 1. UniFi Access Points

```yaml
unifi_ap:
  walk:
    # System Information
    - 1.3.6.1.2.1.1.1.0     # sysDescr
    - 1.3.6.1.2.1.1.3.0     # sysUpTime
    - 1.3.6.1.2.1.1.5.0     # sysName
    
    # UniFi Specific OIDs
    - 1.3.6.1.4.1.41112.1.4.1.1.3   # unifiApSystemModel
    - 1.3.6.1.4.1.41112.1.4.1.1.4   # unifiApSystemVersion
    - 1.3.6.1.4.1.41112.1.4.5.1.2   # unifiRadioName
    - 1.3.6.1.4.1.41112.1.4.5.1.4   # unifiRadioChannel
    - 1.3.6.1.4.1.41112.1.4.5.1.7   # unifiRadioTxPower
    - 1.3.6.1.4.1.41112.1.4.5.1.14  # unifiRadioNumStations
```

**Métricas Específicas UniFi:**
- **unifiApSystemModel**: Modelo do Access Point
- **unifiRadioChannel**: Canal WiFi em uso
- **unifiRadioTxPower**: Potência de transmissão
- **unifiRadioNumStations**: Número de clientes conectados
- **unifiVapRxBytes/TxBytes**: Tráfego por VAP (Virtual Access Point)

### 2. pfSense Firewall

```yaml
pfsense:
  walk:
    # System Information
    - 1.3.6.1.2.1.1.1.0     # sysDescr
    - 1.3.6.1.2.1.1.3.0     # sysUpTime
    
    # CPU and Memory (UCD-SNMP-MIB)
    - 1.3.6.1.4.1.2021.11.9.0   # ssCpuIdle
    - 1.3.6.1.4.1.2021.11.10.0  # ssCpuSystem
    - 1.3.6.1.4.1.2021.11.11.0  # ssCpuUser
    - 1.3.6.1.4.1.2021.4.5.0    # memTotalReal
    - 1.3.6.1.4.1.2021.4.6.0    # memAvailReal
    
    # Disk Usage
    - 1.3.6.1.4.1.2021.9.1.2    # dskPath
    - 1.3.6.1.4.1.2021.9.1.6    # dskTotal
    - 1.3.6.1.4.1.2021.9.1.7    # dskAvail
    - 1.3.6.1.4.1.2021.9.1.9    # dskPercent
```

**Métricas pfSense:**
- **ssCpuIdle/System/User**: Uso de CPU por categoria
- **memTotalReal/AvailReal**: Memória total e disponível
- **dskPath/Total/Avail**: Informações de disco por partição
- **laLoad**: Load average (1, 5, 15 minutos)

### 3. Cisco Switches

```yaml
cisco_switch:
  walk:
    # CPU Utilization (CISCO-PROCESS-MIB)
    - 1.3.6.1.4.1.9.9.109.1.1.1.1.5   # cpmCPUTotal5min
    - 1.3.6.1.4.1.9.9.109.1.1.1.1.6   # cpmCPUTotal1min
    - 1.3.6.1.4.1.9.9.109.1.1.1.1.7   # cpmCPUTotal5sec
    
    # Memory Utilization (CISCO-MEMORY-POOL-MIB)
    - 1.3.6.1.4.1.9.9.48.1.1.1.2      # ciscoMemoryPoolName
    - 1.3.6.1.4.1.9.9.48.1.1.1.5      # ciscoMemoryPoolUsed
    - 1.3.6.1.4.1.9.9.48.1.1.1.6      # ciscoMemoryPoolFree
    
    # Temperature (CISCO-ENVMON-MIB)
    - 1.3.6.1.4.1.9.9.13.1.3.1.2      # ciscoEnvMonTemperatureDescr
    - 1.3.6.1.4.1.9.9.13.1.3.1.3      # ciscoEnvMonTemperatureValue
    - 1.3.6.1.4.1.9.9.13.1.3.1.6      # ciscoEnvMonTemperatureState
```

**Métricas Cisco:**
- **cpmCPUTotal**: Uso de CPU em diferentes intervalos
- **ciscoMemoryPool**: Uso de memória por pool
- **ciscoEnvMonTemperature**: Temperatura dos sensores
- **ciscoEnvMonFan/Supply**: Status de ventiladores e fontes

### 4. MikroTik RouterOS

```yaml
mikrotik:
  walk:
    # MikroTik Specific (MIKROTIK-MIB)
    - 1.3.6.1.4.1.14988.1.1.3.2.0   # mtxrHlCoreVoltage
    - 1.3.6.1.4.1.14988.1.1.3.6.0   # mtxrHlSensorTemperature
    - 1.3.6.1.4.1.14988.1.1.3.7.0   # mtxrHlCpuTemperature
    - 1.3.6.1.4.1.14988.1.1.3.10.0  # mtxrHlProcessorFrequency
    - 1.3.6.1.4.1.14988.1.1.3.11.0  # mtxrHlPowerConsumption
    - 1.3.6.1.4.1.14988.1.1.3.15.0  # mtxrHlFanSpeed1
```

**Métricas MikroTik:**
- **mtxrHlCoreVoltage**: Voltagem do processador
- **mtxrHlSensorTemperature**: Temperatura dos sensores
- **mtxrHlPowerConsumption**: Consumo de energia
- **mtxrHlFanSpeed**: Velocidade dos ventiladores

### 5. Windows Server (via SNMP)

```yaml
windows_server:
  walk:
    # Host Resources (HOST-RESOURCES-MIB)
    - 1.3.6.1.2.1.25.1.1.0      # hrSystemUptime
    - 1.3.6.1.2.1.25.1.6.0      # hrSystemProcesses
    
    # Storage Information
    - 1.3.6.1.2.1.25.2.3.1.2    # hrStorageDescr
    - 1.3.6.1.2.1.25.2.3.1.4    # hrStorageAllocationUnits
    - 1.3.6.1.2.1.25.2.3.1.5    # hrStorageSize
    - 1.3.6.1.2.1.25.2.3.1.6    # hrStorageUsed
    
    # Processor Information
    - 1.3.6.1.2.1.25.3.3.1.2    # hrProcessorLoad
```

**Métricas Windows:**
- **hrSystemUptime**: Tempo de atividade do sistema
- **hrStorageDescr/Size/Used**: Informações de armazenamento
- **hrProcessorLoad**: Carga do processador
- **hrSystemProcesses**: Número de processos

## Configuração no Prometheus

### 1. Job Básico SNMP

```yaml
- job_name: 'snmp-interfaces'
  static_configs:
    - targets:
        - 192.168.1.1    # Router
        - 192.168.1.10   # Switch
        - 192.168.1.20   # Access Point
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
```

### 2. Múltiplos Módulos

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
    - target_label: device_type
      replacement: 'unifi_ap'

# Cisco Switches
- job_name: 'snmp-cisco'
  static_configs:
    - targets: ['192.168.1.10', '192.168.1.11']
  metrics_path: /snmp
  params:
    module: [cisco_switch]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:9116
    - target_label: device_type
      replacement: 'cisco_switch'
```

## Autenticação SNMP

### 1. SNMP v2c (Community String)

```yaml
# No módulo SNMP
auth:
  community: public

# Ou community específica
auth:
  community: monitoring_readonly
```

### 2. SNMP v3 (Mais Seguro)

```yaml
auth:
  security_level: authPriv
  username: monitoring_user
  password: auth_password_here
  auth_protocol: SHA
  priv_protocol: AES
  priv_password: priv_password_here
  context_name: ""
```

**Níveis de Segurança:**
- **noAuthNoPriv**: Sem autenticação nem criptografia
- **authNoPriv**: Com autenticação, sem criptografia
- **authPriv**: Com autenticação e criptografia (recomendado)

**Protocolos de Autenticação:**
- **MD5**: Menos seguro, compatibilidade
- **SHA**: Mais seguro, recomendado
- **SHA224, SHA256, SHA384, SHA512**: Versões mais recentes

**Protocolos de Privacidade:**
- **DES**: Menos seguro, legado
- **AES**: Recomendado
- **AES192, AES256**: Versões mais seguras

## Troubleshooting

### 1. Teste Manual com snmpwalk

```bash
# Testar conectividade SNMP v2c
snmpwalk -v2c -c public 192.168.1.1 1.3.6.1.2.1.1.1.0

# Testar SNMP v3
snmpwalk -v3 -u monitoring_user -l authPriv -a SHA -A auth_pass -x AES -X priv_pass 192.168.1.1 1.3.6.1.2.1.1.1.0

# Testar OID específico
snmpwalk -v2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.2
```

### 2. Teste do SNMP Exporter

```bash
# Testar módulo específico
curl 'http://localhost:9116/snmp?target=192.168.1.1&module=if_mib'

# Verificar módulos disponíveis
curl 'http://localhost:9116/'

# Testar com debug
curl 'http://localhost:9116/snmp?target=192.168.1.1&module=if_mib&debug=true'
```

### 3. Validação da Configuração

```bash
# Verificar sintaxe do arquivo
yamllint snmp.yml

# Testar carregamento no SNMP Exporter
docker-compose restart snmp-exporter
docker-compose logs snmp-exporter
```

### 4. Problemas Comuns

**Timeout/Conectividade:**
```bash
# Verificar conectividade de rede
ping 192.168.1.1

# Verificar porta SNMP
nmap -sU -p 161 192.168.1.1

# Testar com timeout maior
snmpwalk -v2c -c public -t 10 192.168.1.1 1.3.6.1.2.1.1.1.0
```

**Community String Incorreta:**
```bash
# Erro comum: "Timeout: No Response from 192.168.1.1"
# Verificar community string correta
snmpwalk -v2c -c private 192.168.1.1 1.3.6.1.2.1.1.1.0
```

**OID Não Suportado:**
```bash
# Erro: "No Such Object available on this agent at this OID"
# Verificar MIB suportada pelo dispositivo
snmpwalk -v2c -c public 192.168.1.1 1.3.6.1.2.1.1
```

## Otimizações

### 1. Redução de OIDs

```yaml
# Módulo otimizado - apenas métricas essenciais
if_mib_minimal:
  walk:
    - 1.3.6.1.2.1.2.2.1.2   # ifDescr
    - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
    - 1.3.6.1.2.1.2.2.1.10  # ifInOctets
    - 1.3.6.1.2.1.2.2.1.16  # ifOutOctets
  lookups:
    - source_indexes: [ifIndex]
      lookup: 1.3.6.1.2.1.2.2.1.2
  overrides:
    ifOperStatus:
      type: EnumAsStateSet
```

### 2. Configuração de Timeout

```yaml
# No Prometheus job
scrape_configs:
  - job_name: 'snmp'
    scrape_interval: 60s  # Menos frequente para SNMP
    scrape_timeout: 30s   # Timeout maior
    static_configs:
      - targets: ['192.168.1.1']
```

### 3. Filtragem de Interfaces

```yaml
# Filtrar apenas interfaces ativas
metric_relabel_configs:
  - source_labels: [ifOperStatus]
    regex: '2'  # down
    action: drop
  - source_labels: [ifDescr]
    regex: 'lo|docker.*|veth.*'
    action: drop
```

## Métricas Importantes

### 1. Interfaces de Rede

```promql
# Taxa de transferência (bps)
rate(ifHCInOctets[5m]) * 8
rate(ifHCOutOctets[5m]) * 8

# Utilização da interface (%)
rate(ifHCInOctets[5m]) * 8 / ifHighSpeed / 1000000 * 100

# Erros por segundo
rate(ifInErrors[5m])
rate(ifOutErrors[5m])

# Descartes por segundo
rate(ifInDiscards[5m])
rate(ifOutDiscards[5m])
```

### 2. Sistema (pfSense/Linux)

```promql
# Uso de CPU (%)
100 - ssCpuIdle

# Uso de memória (%)
(memTotalReal - memAvailReal) / memTotalReal * 100

# Uso de disco (%)
dskPercent

# Load average
laLoad1
```

### 3. Temperatura e Hardware

```promql
# Temperatura Cisco
ciscoEnvMonTemperatureValue

# Temperatura MikroTik
mtxrHlCpuTemperature / 10  # Dividir por 10 para Celsius

# Consumo de energia MikroTik
mtxrHlPowerConsumption / 10  # Watts
```

## Alertas Recomendados

### 1. Interface Down

```yaml
- alert: SNMPInterfaceDown
  expr: ifOperStatus{ifAdminStatus="1"} == 2
  for: 1m
  labels:
    severity: warning
  annotations:
    summary: "Interface {{ $labels.ifDescr }} está down"
    description: "Interface {{ $labels.ifDescr }} no dispositivo {{ $labels.instance }} está operacionalmente down mas administrativamente up."
```

### 2. Alto Tráfego

```yaml
- alert: SNMPHighTraffic
  expr: rate(ifHCInOctets[5m]) * 8 / ifHighSpeed / 1000000 > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Alto tráfego na interface {{ $labels.ifDescr }}"
    description: "Interface {{ $labels.ifDescr }} no dispositivo {{ $labels.instance }} está com {{ $value | humanizePercentage }} de utilização."
```

### 3. Dispositivo Inacessível

```yaml
- alert: SNMPDeviceDown
  expr: up{job=~"snmp.*"} == 0
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Dispositivo SNMP {{ $labels.instance }} inacessível"
    description: "O dispositivo {{ $labels.instance }} não está respondendo às consultas SNMP há mais de 2 minutos."
```

## Melhores Práticas

### 1. Segurança

- **Use SNMP v3 sempre que possível**
- **Configure communities específicas por função**
- **Limite acesso SNMP por IP/rede**
- **Use credenciais fortes para SNMP v3**
- **Monitore tentativas de acesso não autorizado**

### 2. Performance

- **Colete apenas OIDs necessários**
- **Use intervalos apropriados (60s+ para SNMP)**
- **Configure timeouts adequados**
- **Monitore tempo de resposta dos dispositivos**
- **Use High Capacity counters quando disponível**

### 3. Manutenção

- **Documente OIDs customizados**
- **Mantenha backup das configurações**
- **Teste após atualizações de firmware**
- **Monitore logs do SNMP Exporter**
- **Valide configurações regularmente**

### 4. Organização

- **Agrupe dispositivos por tipo/função**
- **Use labels consistentes**
- **Documente módulos customizados**
- **Mantenha inventário de dispositivos**
- **Use naming conventions claras**

Este arquivo é fundamental para o monitoramento de infraestrutura de rede e deve ser mantido atualizado conforme novos dispositivos são adicionados ao ambiente.
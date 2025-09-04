# 📄 MÓDULO 03: ARQUIVO DE CONFIGURAÇÃO

> **Estrutura detalhada do arquivo snmp.yml e suas configurações**

## 🎯 Objetivos do Módulo

Ao final deste módulo, você será capaz de:

- ✅ Compreender a estrutura completa do arquivo snmp.yml
- ✅ Configurar diferentes tipos de autenticação SNMP
- ✅ Criar módulos personalizados para dispositivos específicos
- ✅ Usar lookups e overrides para customizar métricas
- ✅ Otimizar configurações para performance

---

## 📋 Estrutura Geral do snmp.yml

### Visão Geral

```yaml
# Estrutura principal do snmp.yml
auths:          # Configurações de autenticação
  auth_name:
    # Parâmetros de autenticação

modules:        # Módulos de coleta
  module_name:
    walk:         # OIDs para coletar
    get:          # OIDs específicos
    metrics:      # Definições de métricas
    lookups:      # Mapeamentos de índices
    overrides:    # Customizações de tipos
    walk_params:  # Parâmetros de walk
```

---

## 🔐 Seção AUTHS

### Configurações de Autenticação

A seção `auths` define diferentes perfis de autenticação para conectar aos dispositivos SNMP.

### SNMPv1

```yaml
auths:
  # SNMPv1 - Básico (não recomendado)
  public_v1:
    community: public
    version: 1
```

### SNMPv2c

```yaml
auths:
  # SNMPv2c - Mais comum
  public_v2:
    community: public
    version: 2
    
  # SNMPv2c com community personalizada
  private_v2:
    community: monitoring123
    version: 2
    
  # SNMPv2c somente leitura
  readonly_v2:
    community: readonly
    version: 2
```

### SNMPv3

```yaml
auths:
  # SNMPv3 - Sem autenticação
  noauth_v3:
    username: public
    security_level: noAuthNoPriv
    version: 3
    
  # SNMPv3 - Com autenticação
  auth_v3:
    username: monitoring
    security_level: authNoPriv
    password: mypassword
    auth_protocol: SHA    # MD5, SHA, SHA224, SHA256, SHA384, SHA512
    version: 3
    
  # SNMPv3 - Com autenticação e privacidade
  authpriv_v3:
    username: secure_user
    security_level: authPriv
    password: auth_password
    auth_protocol: SHA256
    priv_password: priv_password
    priv_protocol: AES    # DES, AES, AES192, AES256
    version: 3
    
  # SNMPv3 - Configuração completa
  enterprise_v3:
    username: enterprise_monitor
    security_level: authPriv
    password: "StrongAuth@2024"
    auth_protocol: SHA256
    priv_password: "StrongPriv@2024"
    priv_protocol: AES256
    context_name: "monitoring_context"
    version: 3
```

### Parâmetros de Autenticação

| Parâmetro | Descrição | Valores |
|-----------|-----------|----------|
| `version` | Versão SNMP | 1, 2, 3 |
| `community` | Community string (v1/v2c) | String |
| `username` | Nome do usuário (v3) | String |
| `security_level` | Nível de segurança (v3) | noAuthNoPriv, authNoPriv, authPriv |
| `password` | Senha de autenticação (v3) | String |
| `auth_protocol` | Protocolo de autenticação | MD5, SHA, SHA224, SHA256, SHA384, SHA512 |
| `priv_password` | Senha de privacidade (v3) | String |
| `priv_protocol` | Protocolo de privacidade | DES, AES, AES192, AES256 |
| `context_name` | Nome do contexto (v3) | String |

---

## 📦 Seção MODULES

### Estrutura de um Módulo

```yaml
modules:
  module_name:
    walk:           # Lista de OIDs para walk
      - 1.3.6.1.2.1.1.1.0
    get:            # Lista de OIDs específicos
      - 1.3.6.1.2.1.1.3.0
    metrics:        # Definições customizadas
      - name: custom_metric
        oid: 1.3.6.1.4.1.123.1.1
        type: gauge
    lookups:        # Mapeamentos de índices
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2
    overrides:      # Customizações de tipos
      ifOperStatus:
        type: gauge
    walk_params:    # Parâmetros de performance
      timeout: 10s
      retries: 3
```

### Walk vs Get

#### Walk (Recomendado)
```yaml
# Walk - Coleta toda a tabela/subtree
walk:
  - 1.3.6.1.2.1.2.2.1.2   # Todas as interfaces ifDescr
  - 1.3.6.1.2.1.2.2.1.10  # Todos os contadores ifInOctets
```

#### Get (Específico)
```yaml
# Get - Coleta OIDs específicos
get:
  - 1.3.6.1.2.1.1.1.0     # sysDescr.0
  - 1.3.6.1.2.1.1.3.0     # sysUpTime.0
  - 1.3.6.1.2.1.1.5.0     # sysName.0
```

---

## 🔍 Lookups

### Conceito

Lookups permitem mapear índices numéricos para nomes descritivos, tornando as métricas mais legíveis.

### Exemplo Básico

```yaml
lookups:
  # Mapear ifIndex para ifDescr
  - source_indexes: [ifIndex]
    lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
    drop_source_indexes: false
```

**Resultado:**
```prometheus
# Sem lookup
ifInOctets{ifIndex="1"} 1234567
ifInOctets{ifIndex="2"} 2345678

# Com lookup
ifInOctets{ifDescr="GigabitEthernet0/1",ifIndex="1"} 1234567
ifInOctets{ifDescr="GigabitEthernet0/2",ifIndex="2"} 2345678
```

### Lookups Avançados

```yaml
lookups:
  # Lookup múltiplo
  - source_indexes: [hrStorageIndex]
    lookup: 1.3.6.1.2.1.25.2.3.1.3  # hrStorageDescr
    drop_source_indexes: true
    
  # Lookup com regex
  - source_indexes: [ifIndex]
    lookup: 1.3.6.1.2.1.2.2.1.2
    drop_source_indexes: false
    regex_rewrites:
      - source_labels: [ifDescr]
        regex: 'GigabitEthernet(.*)'
        target_label: interface
        replacement: 'Gi${1}'
```

---

## ⚙️ Overrides

### Tipos de Métricas

```yaml
overrides:
  # Gauge - Valor instantâneo
  ifOperStatus:
    type: gauge
    
  # Counter - Valor incremental
  ifInOctets:
    type: counter
    
  # DisplayString - String
  sysDescr:
    type: DisplayString
    
  # Enum - Valores mapeados
  ifAdminStatus:
    type: gauge
    enum_values:
      1: up
      2: down
      3: testing
```

### Overrides Avançados

```yaml
overrides:
  # Scaling - Ajustar escala
  temperature:
    type: gauge
    scale: 0.1  # Dividir por 10
    
  # Regex - Modificar valores
  sysLocation:
    type: DisplayString
    regex_extracts:
      building:
        - regex: 'Building (\d+)'
          value: '${1}'
      
  # Ignore - Não coletar
  unwanted_metric:
    ignore: true
```

---

## 🚀 Walk Parameters

### Configurações de Performance

```yaml
walk_params:
  # Timeout por requisição
  timeout: 10s
  
  # Número de tentativas
  retries: 3
  
  # Máximo de repetições por PDU (SNMPv2c+)
  max_repetitions: 25
  
  # Usar GetBulk ao invés de GetNext
  use_unconnected_udp_socket: false
  
  # Tamanho máximo do PDU
  max_request_size: 65535
```

### Otimização por Tipo de Dispositivo

```yaml
# Para dispositivos lentos
slow_device:
  walk_params:
    timeout: 30s
    retries: 5
    max_repetitions: 10
    
# Para dispositivos rápidos
fast_device:
  walk_params:
    timeout: 5s
    retries: 2
    max_repetitions: 50
```

---

## 📊 Exemplos de Módulos Completos

### 1. Módulo para Interfaces de Rede

```yaml
modules:
  if_mib_complete:
    walk:
      # Informações básicas
      - 1.3.6.1.2.1.2.2.1.1   # ifIndex
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.3   # ifType
      - 1.3.6.1.2.1.2.2.1.5   # ifSpeed
      - 1.3.6.1.2.1.2.2.1.6   # ifPhysAddress
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      
      # Contadores de tráfego
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
      
      # High Capacity Counters (64-bit)
      - 1.3.6.1.2.1.31.1.1.1.6   # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10  # ifHCOutOctets
      - 1.3.6.1.2.1.31.1.1.1.15  # ifHighSpeed
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
        
    overrides:
      ifAdminStatus:
        type: gauge
        enum_values:
          1: up
          2: down
          3: testing
      ifOperStatus:
        type: gauge
        enum_values:
          1: up
          2: down
          3: testing
          4: unknown
          5: dormant
          6: notPresent
          7: lowerLayerDown
      ifType:
        type: gauge
      ifSpeed:
        type: gauge
      ifHighSpeed:
        type: gauge
        
    walk_params:
      timeout: 10s
      retries: 3
      max_repetitions: 25
```

### 2. Módulo para Sistema

```yaml
modules:
  system_complete:
    get:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.2.0     # sysObjectID
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.4.0     # sysContact
      - 1.3.6.1.2.1.1.5.0     # sysName
      - 1.3.6.1.2.1.1.6.0     # sysLocation
      - 1.3.6.1.2.1.1.7.0     # sysServices
      
    walk:
      # SNMP Statistics
      - 1.3.6.1.2.1.11        # snmp
      
    overrides:
      sysDescr:
        type: DisplayString
      sysContact:
        type: DisplayString
      sysName:
        type: DisplayString
      sysLocation:
        type: DisplayString
      sysUpTime:
        type: gauge
      sysServices:
        type: gauge
        
    walk_params:
      timeout: 5s
      retries: 2
```

### 3. Módulo para CPU e Memória

```yaml
modules:
  host_resources:
    walk:
      # CPU
      - 1.3.6.1.2.1.25.3.3.1.2   # hrProcessorLoad
      
      # Storage/Memory
      - 1.3.6.1.2.1.25.2.3.1.1   # hrStorageIndex
      - 1.3.6.1.2.1.25.2.3.1.2   # hrStorageType
      - 1.3.6.1.2.1.25.2.3.1.3   # hrStorageDescr
      - 1.3.6.1.2.1.25.2.3.1.4   # hrStorageAllocationUnits
      - 1.3.6.1.2.1.25.2.3.1.5   # hrStorageSize
      - 1.3.6.1.2.1.25.2.3.1.6   # hrStorageUsed
      
    lookups:
      - source_indexes: [hrStorageIndex]
        lookup: 1.3.6.1.2.1.25.2.3.1.3  # hrStorageDescr
        drop_source_indexes: false
        
    overrides:
      hrProcessorLoad:
        type: gauge
      hrStorageSize:
        type: gauge
      hrStorageUsed:
        type: gauge
      hrStorageAllocationUnits:
        type: gauge
      hrStorageDescr:
        type: DisplayString
        
    walk_params:
      timeout: 15s
      retries: 3
```

---

## 🎛️ Configurações Específicas por Fabricante

### Cisco

```yaml
modules:
  cisco_cpu:
    walk:
      - 1.3.6.1.4.1.9.9.109.1.1.1.1.7  # cpmCPUTotal5minRev
      - 1.3.6.1.4.1.9.2.1.56.0         # avgBusy5
      
  cisco_memory:
    walk:
      - 1.3.6.1.4.1.9.9.48.1.1.1.5     # ciscoMemoryPoolUsed
      - 1.3.6.1.4.1.9.9.48.1.1.1.6     # ciscoMemoryPoolFree
      
  cisco_temperature:
    walk:
      - 1.3.6.1.4.1.9.9.13.1.3.1.3     # ciscoEnvMonTemperatureValue
```

### HP/HPE

```yaml
modules:
  hp_cpu:
    walk:
      - 1.3.6.1.4.1.11.2.14.11.5.1.9.6.1.0  # hpSwitchCpuStat
      
  hp_memory:
    walk:
      - 1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.6  # hpLocalMemTotalBytes
      - 1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.7  # hpLocalMemFreeBytes
```

### Juniper

```yaml
modules:
  juniper_cpu:
    walk:
      - 1.3.6.1.4.1.2636.3.1.13.1.8    # jnxOperatingCPU
      
  juniper_memory:
    walk:
      - 1.3.6.1.4.1.2636.3.1.13.1.11   # jnxOperatingBuffer
```

---

## 🔧 Validação e Testes

### Validar Configuração

```bash
# Validar sintaxe YAML
yamllint snmp.yml

# Testar configuração com snmp_exporter
docker run --rm -v $(pwd)/snmp.yml:/etc/snmp_exporter/snmp.yml \
  prom/snmp-exporter --config.check
```

### Testar Módulos

```bash
# Testar módulo específico
curl "http://localhost:9116/snmp?target=192.168.1.10&module=if_mib_complete&auth=public_v2"

# Verificar métricas específicas
curl -s "http://localhost:9116/snmp?target=192.168.1.10&module=system_complete&auth=public_v2" \
  | grep sysName
```

### Debug de Configuração

```bash
# Logs detalhados
docker run --rm -v $(pwd)/snmp.yml:/etc/snmp_exporter/snmp.yml \
  prom/snmp-exporter --log.level=debug

# Testar OID específico
snmpget -v2c -c public 192.168.1.10 1.3.6.1.2.1.1.1.0
```

---

## 📝 Exercícios Práticos

### Exercício 1: Configuração Básica
1. Crie um módulo para coletar informações básicas do sistema
2. Configure autenticação SNMPv2c e SNMPv3
3. Teste a configuração com um dispositivo

### Exercício 2: Lookups e Overrides
1. Crie um módulo para interfaces com lookups
2. Configure overrides para tipos de dados
3. Valide as métricas geradas

### Exercício 3: Módulo Personalizado
1. Identifique OIDs específicos do seu dispositivo
2. Crie um módulo customizado
3. Otimize os walk_params para performance

---

## 📝 Resumo do Módulo

Neste módulo, você aprendeu:

- ✅ **Estrutura completa** do arquivo snmp.yml
- ✅ **Configurações de autenticação** para SNMPv1, v2c e v3
- ✅ **Criação de módulos** personalizados
- ✅ **Uso de lookups** para mapear índices
- ✅ **Configuração de overrides** para customizar métricas
- ✅ **Otimização de performance** com walk_params
- ✅ **Exemplos práticos** para diferentes fabricantes

### 🎯 Próximos Passos

Agora você está pronto para:

1. **Explorar MIBs e OIDs** em detalhes
2. **Descobrir dispositivos** automaticamente
3. **Usar ferramentas** de análise SNMP

---

## 🔗 Navegação

- ⬅️ **Anterior:** [Módulo 02 - Configuração Inicial](02-configuracao.md)
- ➡️ **Próximo:** [Módulo 04 - MIBs e OIDs](04-mibs-oids.md)

---

**📚 Módulo 03 de 07 - Arquivo de Configuração**
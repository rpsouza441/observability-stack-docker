# 🔍 MÓDULO 04: MIBs E OIDs

> **Trabalhando com MIBs, OIDs e descoberta automática de dispositivos**

## 🎯 Objetivos do Módulo

Ao final deste módulo, você será capaz de:

- ✅ Compreender conceitos de MIB (Management Information Base)
- ✅ Trabalhar com OIDs (Object Identifiers) eficientemente
- ✅ Descobrir dispositivos e suas capacidades automaticamente
- ✅ Usar ferramentas de análise SNMP
- ✅ Gerar configurações usando o SNMP Generator

---

## 📚 O que são MIBs?

### Conceito

**MIB (Management Information Base)** é uma base de dados hierárquica que define:

- 📊 **Objetos monitoráveis** em dispositivos SNMP
- 🏗️ **Estrutura hierárquica** dos dados
- 📝 **Descrições** e tipos de cada objeto
- 🔢 **OIDs únicos** para cada objeto

### Estrutura Hierárquica

```
iso(1)
└── org(3)
    └── dod(6)
        └── internet(1)
            ├── directory(1)
            ├── mgmt(2)
            │   └── mib-2(1)
            │       ├── system(1)
            │       ├── interfaces(2)
            │       ├── at(3)
            │       ├── ip(4)
            │       ├── icmp(5)
            │       ├── tcp(6)
            │       ├── udp(7)
            │       └── snmp(11)
            ├── experimental(3)
            └── private(4)
                └── enterprises(1)
                    ├── cisco(9)
                    ├── hp(11)
                    ├── juniper(2636)
                    └── ...
```

### Tipos de MIBs

#### 1. **MIBs Padrão (RFC)**
```yaml
MIB-II (RFC 1213):
  - system: 1.3.6.1.2.1.1
  - interfaces: 1.3.6.1.2.1.2
  - ip: 1.3.6.1.2.1.4
  - tcp: 1.3.6.1.2.1.6
  - udp: 1.3.6.1.2.1.7
  - snmp: 1.3.6.1.2.1.11

Host Resources MIB (RFC 2790):
  - hrSystem: 1.3.6.1.2.1.25.1
  - hrStorage: 1.3.6.1.2.1.25.2
  - hrDevice: 1.3.6.1.2.1.25.3
  - hrSWRun: 1.3.6.1.2.1.25.4
```

#### 2. **MIBs Proprietárias**
```yaml
Cisco:
  - Base: 1.3.6.1.4.1.9
  - CPU: 1.3.6.1.4.1.9.9.109
  - Memory: 1.3.6.1.4.1.9.9.48
  - Temperature: 1.3.6.1.4.1.9.9.13

HP/HPE:
  - Base: 1.3.6.1.4.1.11
  - Switch: 1.3.6.1.4.1.11.2.14.11.5

Juniper:
  - Base: 1.3.6.1.4.1.2636
  - Operating: 1.3.6.1.4.1.2636.3.1.13
```

---

## 🔢 Trabalhando com OIDs

### O que são OIDs?

**OID (Object Identifier)** é um identificador único para cada objeto na MIB.

### Formatos de OID

```bash
# Formato numérico
1.3.6.1.2.1.1.1.0

# Formato textual
iso.org.dod.internet.mgmt.mib-2.system.sysDescr.0

# Formato misto
.1.3.6.1.2.1.1.1.0
system.sysDescr.0
```

### OIDs Essenciais

#### System Group (1.3.6.1.2.1.1)
```yaml
sysDescr.0:     1.3.6.1.2.1.1.1.0    # Descrição do sistema
sysObjectID.0:  1.3.6.1.2.1.1.2.0    # Identificador do objeto
sysUpTime.0:    1.3.6.1.2.1.1.3.0    # Tempo de atividade
sysContact.0:   1.3.6.1.2.1.1.4.0    # Contato
sysName.0:      1.3.6.1.2.1.1.5.0    # Nome do sistema
sysLocation.0:  1.3.6.1.2.1.1.6.0    # Localização
sysServices.0:  1.3.6.1.2.1.1.7.0    # Serviços
```

#### Interfaces Group (1.3.6.1.2.1.2)
```yaml
ifNumber.0:     1.3.6.1.2.1.2.1.0    # Número de interfaces

# Interface Table (1.3.6.1.2.1.2.2.1)
ifIndex:        1.3.6.1.2.1.2.2.1.1  # Índice da interface
ifDescr:        1.3.6.1.2.1.2.2.1.2  # Descrição
ifType:         1.3.6.1.2.1.2.2.1.3  # Tipo
ifMtu:          1.3.6.1.2.1.2.2.1.4  # MTU
ifSpeed:        1.3.6.1.2.1.2.2.1.5  # Velocidade
ifPhysAddress:  1.3.6.1.2.1.2.2.1.6  # Endereço físico
ifAdminStatus:  1.3.6.1.2.1.2.2.1.7  # Status administrativo
ifOperStatus:   1.3.6.1.2.1.2.2.1.8  # Status operacional
ifInOctets:     1.3.6.1.2.1.2.2.1.10 # Bytes recebidos
ifOutOctets:    1.3.6.1.2.1.2.2.1.16 # Bytes enviados
```

#### SNMP Group (1.3.6.1.2.1.11)
```yaml
snmpInPkts:     1.3.6.1.2.1.11.1.0   # Pacotes recebidos
snmpOutPkts:    1.3.6.1.2.1.11.2.0   # Pacotes enviados
snmpInBadVersions: 1.3.6.1.2.1.11.3.0 # Versões inválidas
snmpInBadCommunityNames: 1.3.6.1.2.1.11.4.0 # Communities inválidas
```

---

## 🔍 Descoberta de Dispositivos

### 1. Descoberta Básica com snmpwalk

```bash
# Descobrir informações básicas do sistema
snmpwalk -v2c -c public 192.168.1.10 1.3.6.1.2.1.1

# Descobrir interfaces
snmpwalk -v2c -c public 192.168.1.10 1.3.6.1.2.1.2.2.1.2

# Descobrir OID do fabricante
snmpget -v2c -c public 192.168.1.10 1.3.6.1.2.1.1.2.0
```

### 2. Script de Descoberta Automática

```bash
#!/bin/bash
# discover_device.sh

DEVICE=$1
COMMUNITY=${2:-public}

echo "=== Descobrindo dispositivo: $DEVICE ==="

# Informações básicas
echo "\n--- System Information ---"
snmpget -v2c -c $COMMUNITY $DEVICE \
  1.3.6.1.2.1.1.1.0 \
  1.3.6.1.2.1.1.2.0 \
  1.3.6.1.2.1.1.5.0 \
  1.3.6.1.2.1.1.6.0

# Interfaces
echo "\n--- Interfaces ---"
snmpwalk -v2c -c $COMMUNITY $DEVICE 1.3.6.1.2.1.2.2.1.2 | head -10

# Identificar fabricante pelo sysObjectID
OBJECT_ID=$(snmpget -v2c -c $COMMUNITY $DEVICE 1.3.6.1.2.1.1.2.0 -Oqv)
echo "\n--- Vendor Detection ---"
case $OBJECT_ID in
  *".9."*) echo "Cisco device detected" ;;
  *".11."*) echo "HP device detected" ;;
  *".2636."*) echo "Juniper device detected" ;;
  *) echo "Unknown vendor: $OBJECT_ID" ;;
esac
```

### 3. Descoberta com Python

```python
#!/usr/bin/env python3
# snmp_discovery.py

from pysnmp.hlapi import *
import sys

def discover_device(target, community='public'):
    """Descobre informações básicas de um dispositivo SNMP"""
    
    # OIDs para descoberta
    oids = {
        'sysDescr': '1.3.6.1.2.1.1.1.0',
        'sysObjectID': '1.3.6.1.2.1.1.2.0',
        'sysName': '1.3.6.1.2.1.1.5.0',
        'sysLocation': '1.3.6.1.2.1.1.6.0',
        'sysUpTime': '1.3.6.1.2.1.1.3.0'
    }
    
    print(f"Descobrindo dispositivo: {target}")
    print("=" * 50)
    
    for name, oid in oids.items():
        for (errorIndication, errorStatus, errorIndex, varBinds) in nextCmd(
            SnmpEngine(),
            CommunityData(community),
            UdpTransportTarget((target, 161)),
            ContextData(),
            ObjectType(ObjectIdentity(oid)),
            lexicographicMode=False):
            
            if errorIndication:
                print(f"{name}: Error - {errorIndication}")
                break
            elif errorStatus:
                print(f"{name}: Error - {errorStatus.prettyPrint()}")
                break
            else:
                for varBind in varBinds:
                    print(f"{name}: {varBind[1]}")
                break
    
    # Descobrir interfaces
    print("\nInterfaces:")
    print("-" * 30)
    
    for (errorIndication, errorStatus, errorIndex, varBinds) in nextCmd(
        SnmpEngine(),
        CommunityData(community),
        UdpTransportTarget((target, 161)),
        ContextData(),
        ObjectType(ObjectIdentity('1.3.6.1.2.1.2.2.1.2')),
        lexicographicMode=False,
        maxRows=10):
        
        if errorIndication:
            break
        elif errorStatus:
            break
        else:
            for varBind in varBinds:
                index = str(varBind[0]).split('.')[-1]
                print(f"Interface {index}: {varBind[1]}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 snmp_discovery.py <IP> [community]")
        sys.exit(1)
    
    target = sys.argv[1]
    community = sys.argv[2] if len(sys.argv) > 2 else 'public'
    
    discover_device(target, community)
```

---

## 🛠️ Ferramentas de Análise SNMP

### 1. Net-SNMP Tools

```bash
# Instalação no Ubuntu/Debian
sudo apt-get install snmp snmp-mibs-downloader

# Instalação no CentOS/RHEL
sudo yum install net-snmp-utils

# Comandos básicos
snmpget     # Obter valor específico
snmpwalk    # Percorrer árvore MIB
snmpbulkget # Obter múltiplos valores (v2c+)
snmptable   # Exibir tabelas formatadas
snmptranslate # Traduzir OIDs
```

#### Exemplos Práticos

```bash
# Obter descrição do sistema
snmpget -v2c -c public 192.168.1.10 sysDescr.0

# Listar todas as interfaces
snmptable -v2c -c public 192.168.1.10 ifTable

# Traduzir OID para nome
snmptranslate 1.3.6.1.2.1.1.1.0

# Traduzir nome para OID
snmptranslate -On sysDescr.0

# Walk com saída limpa
snmpwalk -v2c -c public 192.168.1.10 1.3.6.1.2.1.2.2.1.2 -Oqv
```

### 2. MIB Browser Online

#### OID Repository
- **Site:** http://oid-info.com/
- **Funcionalidade:** Busca e navegação de OIDs
- **Uso:** Identificar OIDs desconhecidos

#### MIB Depot
- **Site:** http://www.mibdepot.com/
- **Funcionalidade:** Biblioteca de MIBs
- **Uso:** Download de MIBs proprietárias

### 3. SNMP Generator

#### Instalação

```bash
# Via Docker
docker pull prom/snmp-generator

# Via Go
go install github.com/prometheus/snmp_exporter/generator@latest
```

#### Uso Básico

```bash
# Gerar configuração a partir de MIBs
docker run --rm -v $(pwd):/opt prom/snmp-generator generate

# Gerar para MIB específica
echo 'modules:
  if_mib:
    walk:
      - ifTable' > generator.yml
      
docker run --rm -v $(pwd):/opt prom/snmp-generator generate
```

#### Configuração do Generator

```yaml
# generator.yml
modules:
  # Módulo para interfaces
  if_mib:
    walk:
      - ifTable
      - ifXTable
    lookups:
      - source_indexes: [ifIndex]
        lookup: ifDescr
        
  # Módulo para sistema
  system:
    walk:
      - sysDescr
      - sysObjectID
      - sysUpTime
      - sysContact
      - sysName
      - sysLocation
      
  # Módulo customizado para Cisco
  cisco_cpu:
    walk:
      - 1.3.6.1.4.1.9.9.109.1.1.1.1.7  # cpmCPUTotal5minRev
    lookups:
      - source_indexes: [cpmCPUTotalIndex]
        lookup: 1.3.6.1.4.1.9.9.109.1.1.1.1.2  # cpmCPUTotalPhysicalIndex
```

---

## 🔍 Análise de MIBs Específicas

### 1. Interface MIB (RFC 2863)

```yaml
# Tabela de Interfaces (ifTable)
ifTable: 1.3.6.1.2.1.2.2
  ifIndex: .1        # Índice da interface
  ifDescr: .2        # Descrição (ex: "GigabitEthernet0/1")
  ifType: .3         # Tipo (6=ethernetCsmacd, 24=softwareLoopback)
  ifMtu: .4          # Maximum Transmission Unit
  ifSpeed: .5        # Velocidade em bits/sec
  ifPhysAddress: .6  # Endereço MAC
  ifAdminStatus: .7  # Status administrativo (1=up, 2=down, 3=testing)
  ifOperStatus: .8   # Status operacional (1=up, 2=down, 3=testing, 4=unknown, 5=dormant, 6=notPresent, 7=lowerLayerDown)
  ifLastChange: .9   # Última mudança
  ifInOctets: .10    # Bytes recebidos
  ifInUcastPkts: .11 # Pacotes unicast recebidos
  ifInNUcastPkts: .12 # Pacotes não-unicast recebidos
  ifInDiscards: .13  # Pacotes descartados na entrada
  ifInErrors: .14    # Erros na entrada
  ifInUnknownProtos: .15 # Protocolos desconhecidos
  ifOutOctets: .16   # Bytes enviados
  ifOutUcastPkts: .17 # Pacotes unicast enviados
  ifOutNUcastPkts: .18 # Pacotes não-unicast enviados
  ifOutDiscards: .19 # Pacotes descartados na saída
  ifOutErrors: .20   # Erros na saída
  ifOutQLen: .21     # Tamanho da fila de saída
  ifSpecific: .22    # Referência específica

# Tabela Estendida (ifXTable) - RFC 2863
ifXTable: 1.3.6.1.2.1.31.1.1
  ifName: .1         # Nome da interface
  ifInMulticastPkts: .2 # Pacotes multicast recebidos
  ifInBroadcastPkts: .3 # Pacotes broadcast recebidos
  ifOutMulticastPkts: .4 # Pacotes multicast enviados
  ifOutBroadcastPkts: .5 # Pacotes broadcast enviados
  ifHCInOctets: .6   # Contador de 64 bits - bytes recebidos
  ifHCInUcastPkts: .7 # Contador de 64 bits - pacotes unicast recebidos
  ifHCInMulticastPkts: .8 # Contador de 64 bits - pacotes multicast recebidos
  ifHCInBroadcastPkts: .9 # Contador de 64 bits - pacotes broadcast recebidos
  ifHCOutOctets: .10 # Contador de 64 bits - bytes enviados
  ifHCOutUcastPkts: .11 # Contador de 64 bits - pacotes unicast enviados
  ifHCOutMulticastPkts: .12 # Contador de 64 bits - pacotes multicast enviados
  ifHCOutBroadcastPkts: .13 # Contador de 64 bits - pacotes broadcast enviados
  ifLinkUpDownTrapEnable: .14 # Habilitar traps de link up/down
  ifHighSpeed: .15   # Velocidade em Mbps
  ifPromiscuousMode: .16 # Modo promíscuo
  ifConnectorPresent: .17 # Conector presente
  ifAlias: .18       # Alias da interface
  ifCounterDiscontinuityTime: .19 # Tempo de descontinuidade dos contadores
```

### 2. Host Resources MIB (RFC 2790)

```yaml
# Sistema (hrSystem)
hrSystem: 1.3.6.1.2.1.25.1
  hrSystemUptime: .1.0      # Uptime do sistema
  hrSystemDate: .2.0        # Data do sistema
  hrSystemInitialLoadDevice: .3.0 # Dispositivo de boot
  hrSystemInitialLoadParameters: .4.0 # Parâmetros de boot
  hrSystemNumUsers: .5.0    # Número de usuários
  hrSystemProcesses: .6.0   # Número de processos
  hrSystemMaxProcesses: .7.0 # Máximo de processos

# Armazenamento (hrStorage)
hrStorageTable: 1.3.6.1.2.1.25.2.3
  hrStorageIndex: .1        # Índice
  hrStorageType: .2         # Tipo de armazenamento
  hrStorageDescr: .3        # Descrição
  hrStorageAllocationUnits: .4 # Unidade de alocação
  hrStorageSize: .5         # Tamanho total
  hrStorageUsed: .6         # Espaço usado
  hrStorageAllocationFailures: .7 # Falhas de alocação

# Dispositivos (hrDevice)
hrDeviceTable: 1.3.6.1.2.1.25.3.2
  hrDeviceIndex: .1         # Índice
  hrDeviceType: .2          # Tipo de dispositivo
  hrDeviceDescr: .3         # Descrição
  hrDeviceID: .4            # ID do dispositivo
  hrDeviceStatus: .5        # Status (1=unknown, 2=running, 3=warning, 4=testing, 5=down)
  hrDeviceErrors: .6        # Número de erros

# Processadores (hrProcessor)
hrProcessorTable: 1.3.6.1.2.1.25.3.3
  hrProcessorFrwID: .1      # ID do firmware
  hrProcessorLoad: .2       # Carga do processador (0-100%)
```

### 3. MIBs Proprietárias Cisco

```yaml
# CPU (CISCO-PROCESS-MIB)
cpmCPUTotalTable: 1.3.6.1.4.1.9.9.109.1.1.1
  cpmCPUTotalIndex: .1      # Índice
  cpmCPUTotalPhysicalIndex: .2 # Índice físico
  cpmCPUTotal5sec: .3       # CPU 5 segundos
  cpmCPUTotal1min: .4       # CPU 1 minuto
  cpmCPUTotal5min: .5       # CPU 5 minutos
  cpmCPUTotal5secRev: .6    # CPU 5 segundos (revisado)
  cpmCPUTotal1minRev: .7    # CPU 1 minuto (revisado)
  cpmCPUTotal5minRev: .8    # CPU 5 minutos (revisado)

# Memória (CISCO-MEMORY-POOL-MIB)
ciscoMemoryPoolTable: 1.3.6.1.4.1.9.9.48.1.1
  ciscoMemoryPoolType: .1   # Tipo de pool
  ciscoMemoryPoolName: .2   # Nome do pool
  ciscoMemoryPoolAlternate: .3 # Pool alternativo
  ciscoMemoryPoolValid: .4  # Pool válido
  ciscoMemoryPoolUsed: .5   # Memória usada
  ciscoMemoryPoolFree: .6   # Memória livre
  ciscoMemoryPoolLargestFree: .7 # Maior bloco livre

# Temperatura (CISCO-ENVMON-MIB)
ciscoEnvMonTemperatureTable: 1.3.6.1.4.1.9.9.13.1.3
  ciscoEnvMonTemperatureDescr: .2 # Descrição
  ciscoEnvMonTemperatureValue: .3 # Valor da temperatura
  ciscoEnvMonTemperatureThreshold: .4 # Limite
  ciscoEnvMonTemperatureLastShutdown: .5 # Último shutdown
  ciscoEnvMonTemperatureState: .6 # Estado (1=normal, 2=warning, 3=critical, 4=shutdown, 5=notPresent, 6=notFunctioning)
```

---

## 📊 Criando Módulos Baseados em Descoberta

### 1. Workflow de Descoberta

```bash
#!/bin/bash
# create_module.sh

DEVICE=$1
COMMUNITY=${2:-public}
MODULE_NAME=${3:-custom_device}

echo "Criando módulo para: $DEVICE"

# 1. Descobrir fabricante
OBJECT_ID=$(snmpget -v2c -c $COMMUNITY $DEVICE 1.3.6.1.2.1.1.2.0 -Oqv)
echo "sysObjectID: $OBJECT_ID"

# 2. Descobrir interfaces
echo "\nInterfaces disponíveis:"
snmpwalk -v2c -c $COMMUNITY $DEVICE 1.3.6.1.2.1.2.2.1.2 -Oqv

# 3. Testar OIDs específicos do fabricante
if [[ $OBJECT_ID == *".9."* ]]; then
    echo "\nTestando OIDs Cisco..."
    # Testar CPU
    snmpwalk -v2c -c $COMMUNITY $DEVICE 1.3.6.1.4.1.9.9.109.1.1.1.1.7 -Oqv 2>/dev/null && echo "CPU OID disponível"
    # Testar Memória
    snmpwalk -v2c -c $COMMUNITY $DEVICE 1.3.6.1.4.1.9.9.48.1.1.1.5 -Oqv 2>/dev/null && echo "Memory OID disponível"
fi

# 4. Gerar configuração básica
cat > ${MODULE_NAME}.yml << EOF
modules:
  ${MODULE_NAME}:
    walk:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      
      # Interface Information
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.2.2.1.10  # ifInOctets
      - 1.3.6.1.2.1.2.2.1.16  # ifOutOctets
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
        
    overrides:
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
        
    walk_params:
      timeout: 10s
      retries: 3
EOF

echo "\nConfiguração gerada em: ${MODULE_NAME}.yml"
```

### 2. Validação Automática

```python
#!/usr/bin/env python3
# validate_oids.py

from pysnmp.hlapi import *
import yaml
import sys

def validate_oids(target, community, config_file):
    """Valida OIDs em um arquivo de configuração"""
    
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    
    for module_name, module_config in config['modules'].items():
        print(f"Validando módulo: {module_name}")
        
        # Validar walk OIDs
        if 'walk' in module_config:
            for oid in module_config['walk']:
                result = test_oid(target, community, oid)
                status = "✓" if result else "✗"
                print(f"  {status} {oid}")
        
        # Validar get OIDs
        if 'get' in module_config:
            for oid in module_config['get']:
                result = test_oid(target, community, oid)
                status = "✓" if result else "✗"
                print(f"  {status} {oid}")

def test_oid(target, community, oid):
    """Testa se um OID está disponível"""
    try:
        for (errorIndication, errorStatus, errorIndex, varBinds) in nextCmd(
            SnmpEngine(),
            CommunityData(community),
            UdpTransportTarget((target, 161)),
            ContextData(),
            ObjectType(ObjectIdentity(oid)),
            lexicographicMode=False,
            maxRows=1):
            
            if errorIndication or errorStatus:
                return False
            return True
    except:
        return False

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Uso: python3 validate_oids.py <IP> <community> <config.yml>")
        sys.exit(1)
    
    validate_oids(sys.argv[1], sys.argv[2], sys.argv[3])
```

---

## 📝 Exercícios Práticos

### Exercício 1: Descoberta Básica
1. Use snmpwalk para descobrir informações de um dispositivo
2. Identifique o fabricante pelo sysObjectID
3. Liste todas as interfaces disponíveis

### Exercício 2: Análise de MIB
1. Baixe a MIB do seu dispositivo
2. Identifique OIDs específicos do fabricante
3. Teste os OIDs com snmpget/snmpwalk

### Exercício 3: Criação de Módulo
1. Crie um módulo personalizado baseado na descoberta
2. Valide todos os OIDs
3. Teste o módulo com o SNMP Exporter

---

## 📝 Resumo do Módulo

Neste módulo, você aprendeu:

- ✅ **Conceitos de MIB** e estrutura hierárquica
- ✅ **Trabalho com OIDs** e formatos
- ✅ **Descoberta automática** de dispositivos
- ✅ **Ferramentas de análise** SNMP
- ✅ **SNMP Generator** para criar configurações
- ✅ **MIBs específicas** por fabricante
- ✅ **Validação de configurações**

### 🎯 Próximos Passos

Agora você está pronto para:

1. **Configurar dispositivos específicos** de rede
2. **Criar módulos otimizados** por fabricante
3. **Implementar monitoramento** de switches e roteadores

---

## 🔗 Navegação

- ⬅️ **Anterior:** [Módulo 03 - Arquivo de Configuração](03-arquivo-config.md)
- ➡️ **Próximo:** [Módulo 05 - Dispositivos de Rede](05-dispositivos-rede.md)

---

**📚 Módulo 04 de 07 - MIBs e OIDs**
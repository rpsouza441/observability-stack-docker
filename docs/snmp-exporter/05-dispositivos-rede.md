# 🌐 MÓDULO 05: DISPOSITIVOS DE REDE

> **Monitoramento especializado de switches, roteadores e equipamentos de rede**

## 🎯 Objetivos do Módulo

Ao final deste módulo, você será capaz de:

- ✅ Configurar monitoramento para switches e roteadores
- ✅ Implementar configurações específicas por fabricante
- ✅ Monitorar métricas avançadas de rede
- ✅ Configurar alertas para dispositivos de rede
- ✅ Otimizar performance do monitoramento SNMP

---

## 🔧 Switches - Configuração Básica

### 1. Módulo Genérico para Switches

```yaml
# snmp.yml - Módulo básico para switches
modules:
  switch_basic:
    walk:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      - 1.3.6.1.2.1.1.6.0     # sysLocation
      
      # Interface Statistics
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.3   # ifType
      - 1.3.6.1.2.1.2.2.1.5   # ifSpeed
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.2.2.1.10  # ifInOctets
      - 1.3.6.1.2.1.2.2.1.11  # ifInUcastPkts
      - 1.3.6.1.2.1.2.2.1.13  # ifInDiscards
      - 1.3.6.1.2.1.2.2.1.14  # ifInErrors
      - 1.3.6.1.2.1.2.2.1.16  # ifOutOctets
      - 1.3.6.1.2.1.2.2.1.17  # ifOutUcastPkts
      - 1.3.6.1.2.1.2.2.1.19  # ifOutDiscards
      - 1.3.6.1.2.1.2.2.1.20  # ifOutErrors
      
      # High Capacity Counters (64-bit)
      - 1.3.6.1.2.1.31.1.1.1.1  # ifName
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
      - 1.3.6.1.2.1.31.1.1.1.15 # ifHighSpeed
      - 1.3.6.1.2.1.31.1.1.1.18 # ifAlias
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.31.1.1.1.1  # ifName
        drop_source_indexes: false
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.31.1.1.1.18  # ifAlias
        drop_source_indexes: false
        
    overrides:
      ifType:
        type: gauge
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
      ifHighSpeed:
        type: gauge
        
    walk_params:
      timeout: 10s
      retries: 3
      max_repetitions: 25
```

### 2. Configuração Prometheus para Switches

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'snmp-switches'
    static_configs:
      - targets:
        - 192.168.1.10  # Switch Core
        - 192.168.1.11  # Switch Access 1
        - 192.168.1.12  # Switch Access 2
    metrics_path: /snmp
    params:
      module: [switch_basic]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
      # Adicionar labels customizados
      - source_labels: [instance]
        target_label: device_type
        replacement: switch
      - source_labels: [instance]
        regex: '192\.168\.1\.10'
        target_label: device_role
        replacement: core
      - source_labels: [instance]
        regex: '192\.168\.1\.(11|12)'
        target_label: device_role
        replacement: access
```

---

## 🔀 Roteadores - Configuração Avançada

### 1. Módulo para Roteadores

```yaml
# snmp.yml - Módulo para roteadores
modules:
  router_advanced:
    walk:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      
      # Interface Information
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
      
      # IP Statistics
      - 1.3.6.1.2.1.4.3.0     # ipInReceives
      - 1.3.6.1.2.1.4.4.0     # ipInHdrErrors
      - 1.3.6.1.2.1.4.5.0     # ipInAddrErrors
      - 1.3.6.1.2.1.4.6.0     # ipForwDatagrams
      - 1.3.6.1.2.1.4.8.0     # ipInDiscards
      - 1.3.6.1.2.1.4.9.0     # ipInDelivers
      - 1.3.6.1.2.1.4.10.0    # ipOutRequests
      - 1.3.6.1.2.1.4.11.0    # ipOutDiscards
      - 1.3.6.1.2.1.4.12.0    # ipOutNoRoutes
      
      # TCP Statistics
      - 1.3.6.1.2.1.6.5.0     # tcpActiveOpens
      - 1.3.6.1.2.1.6.6.0     # tcpPassiveOpens
      - 1.3.6.1.2.1.6.7.0     # tcpAttemptFails
      - 1.3.6.1.2.1.6.8.0     # tcpEstabResets
      - 1.3.6.1.2.1.6.9.0     # tcpCurrEstab
      - 1.3.6.1.2.1.6.10.0    # tcpInSegs
      - 1.3.6.1.2.1.6.11.0    # tcpOutSegs
      - 1.3.6.1.2.1.6.12.0    # tcpRetransSegs
      
      # UDP Statistics
      - 1.3.6.1.2.1.7.1.0     # udpInDatagrams
      - 1.3.6.1.2.1.7.2.0     # udpNoPorts
      - 1.3.6.1.2.1.7.3.0     # udpInErrors
      - 1.3.6.1.2.1.7.4.0     # udpOutDatagrams
      
      # ICMP Statistics
      - 1.3.6.1.2.1.5.1.0     # icmpInMsgs
      - 1.3.6.1.2.1.5.2.0     # icmpInErrors
      - 1.3.6.1.2.1.5.14.0    # icmpOutMsgs
      - 1.3.6.1.2.1.5.15.0    # icmpOutErrors
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
        
    overrides:
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
      tcpCurrEstab:
        type: gauge
        
    walk_params:
      timeout: 15s
      retries: 3
      max_repetitions: 25
```

---

## 🏢 Configurações por Fabricante

### 1. Cisco - Switches e Roteadores

```yaml
# snmp.yml - Módulo específico Cisco
modules:
  cisco_advanced:
    walk:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      
      # Interface Information
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
      
      # Cisco CPU (CISCO-PROCESS-MIB)
      - 1.3.6.1.4.1.9.9.109.1.1.1.1.7  # cpmCPUTotal5minRev
      - 1.3.6.1.4.1.9.9.109.1.1.1.1.8  # cpmCPUTotal1minRev
      
      # Cisco Memory (CISCO-MEMORY-POOL-MIB)
      - 1.3.6.1.4.1.9.9.48.1.1.1.2   # ciscoMemoryPoolName
      - 1.3.6.1.4.1.9.9.48.1.1.1.5   # ciscoMemoryPoolUsed
      - 1.3.6.1.4.1.9.9.48.1.1.1.6   # ciscoMemoryPoolFree
      
      # Cisco Temperature (CISCO-ENVMON-MIB)
      - 1.3.6.1.4.1.9.9.13.1.3.1.2   # ciscoEnvMonTemperatureDescr
      - 1.3.6.1.4.1.9.9.13.1.3.1.3   # ciscoEnvMonTemperatureValue
      - 1.3.6.1.4.1.9.9.13.1.3.1.6   # ciscoEnvMonTemperatureState
      
      # Cisco Power Supply (CISCO-ENVMON-MIB)
      - 1.3.6.1.4.1.9.9.13.1.5.1.2   # ciscoEnvMonSupplyDescr
      - 1.3.6.1.4.1.9.9.13.1.5.1.3   # ciscoEnvMonSupplyState
      
      # Cisco Fan (CISCO-ENVMON-MIB)
      - 1.3.6.1.4.1.9.9.13.1.4.1.2   # ciscoEnvMonFanDescr
      - 1.3.6.1.4.1.9.9.13.1.4.1.3   # ciscoEnvMonFanState
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
      - source_indexes: [cpmCPUTotalIndex]
        lookup: 1.3.6.1.4.1.9.9.109.1.1.1.1.2  # cpmCPUTotalPhysicalIndex
        drop_source_indexes: false
      - source_indexes: [ciscoMemoryPoolType]
        lookup: 1.3.6.1.4.1.9.9.48.1.1.1.2  # ciscoMemoryPoolName
        drop_source_indexes: false
      - source_indexes: [ciscoEnvMonTemperatureStatusIndex]
        lookup: 1.3.6.1.4.1.9.9.13.1.3.1.2  # ciscoEnvMonTemperatureDescr
        drop_source_indexes: false
        
    overrides:
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
      cpmCPUTotal5minRev:
        type: gauge
        scale: 0.01  # Converter para porcentagem
      cpmCPUTotal1minRev:
        type: gauge
        scale: 0.01
      ciscoEnvMonTemperatureValue:
        type: gauge
      ciscoEnvMonTemperatureState:
        type: gauge
      ciscoEnvMonSupplyState:
        type: gauge
      ciscoEnvMonFanState:
        type: gauge
        
    walk_params:
      timeout: 20s
      retries: 3
      max_repetitions: 25
```

### 2. HP/HPE - ProCurve/Aruba

```yaml
# snmp.yml - Módulo específico HP/HPE
modules:
  hp_procurve:
    walk:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      
      # Interface Information
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
      
      # HP CPU (HP-ICF-CHASSIS-MIB)
      - 1.3.6.1.4.1.11.2.14.11.5.1.9.6.1.0  # hpicfSensorDescr
      - 1.3.6.1.4.1.11.2.14.11.5.1.9.6.1.0  # hpicfSensorObjectId
      
      # HP Memory
      - 1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.7  # hpLocalMemTotalBytes
      - 1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.6  # hpLocalMemFreeBytes
      
      # HP Temperature
      - 1.3.6.1.4.1.11.2.14.11.1.2.6.1.7.1.3.1  # hpicfSensorDescr
      - 1.3.6.1.4.1.11.2.14.11.1.2.6.1.7.1.4.1  # hpicfSensorValue
      - 1.3.6.1.4.1.11.2.14.11.1.2.6.1.7.1.9.1  # hpicfSensorStatus
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
        
    overrides:
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
      hpicfSensorValue:
        type: gauge
      hpicfSensorStatus:
        type: gauge
        
    walk_params:
      timeout: 15s
      retries: 3
      max_repetitions: 25
```

### 3. Juniper - EX/QFX Series

```yaml
# snmp.yml - Módulo específico Juniper
modules:
  juniper_ex:
    walk:
      # System Information
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.5.0     # sysName
      
      # Interface Information
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.31.1.1.1.6  # ifHCInOctets
      - 1.3.6.1.2.1.31.1.1.1.10 # ifHCOutOctets
      
      # Juniper Operating (JUNIPER-MIB)
      - 1.3.6.1.4.1.2636.3.1.13.1.5   # jnxOperatingDescr
      - 1.3.6.1.4.1.2636.3.1.13.1.6   # jnxOperatingState
      - 1.3.6.1.4.1.2636.3.1.13.1.7   # jnxOperatingTemp
      - 1.3.6.1.4.1.2636.3.1.13.1.8   # jnxOperatingCPU
      - 1.3.6.1.4.1.2636.3.1.13.1.11  # jnxOperatingMemory
      
      # Juniper Chassis (JUNIPER-CHASSIS-DEFINES-MIB)
      - 1.3.6.1.4.1.2636.3.1.15.1.5   # jnxFruName
      - 1.3.6.1.4.1.2636.3.1.15.1.6   # jnxFruType
      - 1.3.6.1.4.1.2636.3.1.15.1.8   # jnxFruState
      
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
      - source_indexes: [jnxOperatingContentsIndex, jnxOperatingL1Index, jnxOperatingL2Index, jnxOperatingL3Index]
        lookup: 1.3.6.1.4.1.2636.3.1.13.1.5  # jnxOperatingDescr
        drop_source_indexes: false
        
    overrides:
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
      jnxOperatingState:
        type: gauge
      jnxOperatingTemp:
        type: gauge
      jnxOperatingCPU:
        type: gauge
      jnxOperatingMemory:
        type: gauge
      jnxFruState:
        type: gauge
        
    walk_params:
      timeout: 20s
      retries: 3
      max_repetitions: 25
```

---

## 📊 Métricas Avançadas de Rede

### 1. Qualidade de Serviço (QoS)

```yaml
# snmp.yml - Módulo QoS
modules:
  qos_monitoring:
    walk:
      # Interface QoS Statistics
      - 1.3.6.1.2.1.16.1.1.1.2   # dot1dTpFdbAddress
      - 1.3.6.1.2.1.16.1.1.1.3   # dot1dTpFdbPort
      - 1.3.6.1.2.1.16.1.1.1.4   # dot1dTpFdbStatus
      
      # RMON Statistics
      - 1.3.6.1.2.1.16.1.1.1.1   # dot1dTpFdbIndex
      - 1.3.6.1.2.1.16.2.1.1.3   # dot1dTpPortInFrames
      - 1.3.6.1.2.1.16.2.1.1.4   # dot1dTpPortOutFrames
      - 1.3.6.1.2.1.16.2.1.1.5   # dot1dTpPortInDiscards
      
    lookups:
      - source_indexes: [dot1dTpFdbIndex]
        lookup: 1.3.6.1.2.1.16.1.1.1.2  # dot1dTpFdbAddress
        drop_source_indexes: false
        
    overrides:
      dot1dTpFdbStatus:
        type: gauge
        
    walk_params:
      timeout: 15s
      retries: 3
```

### 2. VLAN Monitoring

```yaml
# snmp.yml - Módulo VLAN
modules:
  vlan_monitoring:
    walk:
      # VLAN Information (Q-BRIDGE-MIB)
      - 1.3.6.1.2.1.17.7.1.2.2.1.2   # dot1qVlanStaticName
      - 1.3.6.1.2.1.17.7.1.2.2.1.3   # dot1qVlanStaticEgressPorts
      - 1.3.6.1.2.1.17.7.1.2.2.1.4   # dot1qVlanForbiddenEgressPorts
      - 1.3.6.1.2.1.17.7.1.2.2.1.5   # dot1qVlanStaticUntaggedPorts
      - 1.3.6.1.2.1.17.7.1.2.2.1.6   # dot1qVlanStaticRowStatus
      
      # Port VLAN Information
      - 1.3.6.1.2.1.17.7.1.4.2.1.2   # dot1qPvid
      - 1.3.6.1.2.1.17.7.1.4.2.1.3   # dot1qPortAcceptableFrameTypes
      - 1.3.6.1.2.1.17.7.1.4.2.1.4   # dot1qPortIngressFiltering
      
    lookups:
      - source_indexes: [dot1qVlanIndex]
        lookup: 1.3.6.1.2.1.17.7.1.2.2.1.2  # dot1qVlanStaticName
        drop_source_indexes: false
        
    overrides:
      dot1qVlanStaticRowStatus:
        type: gauge
      dot1qPvid:
        type: gauge
      dot1qPortAcceptableFrameTypes:
        type: gauge
      dot1qPortIngressFiltering:
        type: gauge
        
    walk_params:
      timeout: 15s
      retries: 3
```

### 3. Spanning Tree Protocol (STP)

```yaml
# snmp.yml - Módulo STP
modules:
  stp_monitoring:
    walk:
      # STP Bridge Information
      - 1.3.6.1.2.1.17.2.1.0     # dot1dStpProtocolSpecification
      - 1.3.6.1.2.1.17.2.2.0     # dot1dStpPriority
      - 1.3.6.1.2.1.17.2.3.0     # dot1dStpTimeSinceTopologyChange
      - 1.3.6.1.2.1.17.2.4.0     # dot1dStpTopChanges
      - 1.3.6.1.2.1.17.2.5.0     # dot1dStpDesignatedRoot
      - 1.3.6.1.2.1.17.2.6.0     # dot1dStpRootCost
      - 1.3.6.1.2.1.17.2.7.0     # dot1dStpRootPort
      
      # STP Port Information
      - 1.3.6.1.2.1.17.2.15.1.2  # dot1dStpPortPriority
      - 1.3.6.1.2.1.17.2.15.1.3  # dot1dStpPortState
      - 1.3.6.1.2.1.17.2.15.1.4  # dot1dStpPortEnable
      - 1.3.6.1.2.1.17.2.15.1.5  # dot1dStpPortPathCost
      - 1.3.6.1.2.1.17.2.15.1.6  # dot1dStpPortDesignatedRoot
      - 1.3.6.1.2.1.17.2.15.1.7  # dot1dStpPortDesignatedCost
      - 1.3.6.1.2.1.17.2.15.1.8  # dot1dStpPortDesignatedBridge
      - 1.3.6.1.2.1.17.2.15.1.9  # dot1dStpPortDesignatedPort
      
    overrides:
      dot1dStpProtocolSpecification:
        type: gauge
      dot1dStpPriority:
        type: gauge
      dot1dStpTopChanges:
        type: counter
      dot1dStpRootCost:
        type: gauge
      dot1dStpRootPort:
        type: gauge
      dot1dStpPortPriority:
        type: gauge
      dot1dStpPortState:
        type: gauge
      dot1dStpPortEnable:
        type: gauge
      dot1dStpPortPathCost:
        type: gauge
        
    walk_params:
      timeout: 15s
      retries: 3
```

---

## 🚨 Alertas para Dispositivos de Rede

### 1. Alertas Básicos

```yaml
# alerts.yml - Alertas para dispositivos de rede
groups:
  - name: network_devices
    rules:
      # Device Down
      - alert: NetworkDeviceDown
        expr: up{job="snmp-switches"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Dispositivo de rede {{ $labels.instance }} está inacessível"
          description: "O dispositivo {{ $labels.instance }} não está respondendo há {{ $value }} minutos."
      
      # Interface Down
      - alert: InterfaceDown
        expr: ifOperStatus{job="snmp-switches"} == 2 and ifAdminStatus{job="snmp-switches"} == 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Interface {{ $labels.ifDescr }} no dispositivo {{ $labels.instance }} está down"
          description: "A interface {{ $labels.ifDescr }} está administrativamente up mas operacionalmente down há {{ $value }} minutos."
      
      # High Interface Utilization
      - alert: HighInterfaceUtilization
        expr: |
          (
            rate(ifHCInOctets{job="snmp-switches"}[5m]) * 8 / 
            (ifHighSpeed{job="snmp-switches"} * 1000000)
          ) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Alta utilização na interface {{ $labels.ifDescr }}"
          description: "A interface {{ $labels.ifDescr }} no dispositivo {{ $labels.instance }} está com {{ $value }}% de utilização."
      
      # Interface Errors
      - alert: InterfaceErrors
        expr: rate(ifInErrors{job="snmp-switches"}[5m]) > 10
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "Erros na interface {{ $labels.ifDescr }}"
          description: "A interface {{ $labels.ifDescr }} no dispositivo {{ $labels.instance }} está apresentando {{ $value }} erros por segundo."
```

### 2. Alertas Específicos por Fabricante

```yaml
# alerts.yml - Alertas específicos Cisco
groups:
  - name: cisco_devices
    rules:
      # High CPU
      - alert: CiscoCPUHigh
        expr: cpmCPUTotal5minRev{job="snmp-cisco"} > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "CPU alta no dispositivo Cisco {{ $labels.instance }}"
          description: "CPU está em {{ $value }}% nos últimos 5 minutos."
      
      # High Memory
      - alert: CiscoMemoryHigh
        expr: |
          (
            ciscoMemoryPoolUsed{job="snmp-cisco"} / 
            (ciscoMemoryPoolUsed{job="snmp-cisco"} + ciscoMemoryPoolFree{job="snmp-cisco"})
          ) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Memória alta no dispositivo Cisco {{ $labels.instance }}"
          description: "Memória {{ $labels.ciscoMemoryPoolName }} está em {{ $value }}% de utilização."
      
      # Temperature Alert
      - alert: CiscoTemperatureHigh
        expr: ciscoEnvMonTemperatureValue{job="snmp-cisco"} > 70
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "Temperatura alta no dispositivo Cisco {{ $labels.instance }}"
          description: "Sensor {{ $labels.ciscoEnvMonTemperatureDescr }} está em {{ $value }}°C."
      
      # Power Supply Alert
      - alert: CiscoPowerSupplyFailure
        expr: ciscoEnvMonSupplyState{job="snmp-cisco"} != 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Falha na fonte de alimentação do dispositivo Cisco {{ $labels.instance }}"
          description: "Fonte {{ $labels.ciscoEnvMonSupplyDescr }} está em estado {{ $value }}."
      
      # Fan Alert
      - alert: CiscoFanFailure
        expr: ciscoEnvMonFanState{job="snmp-cisco"} != 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Falha no ventilador do dispositivo Cisco {{ $labels.instance }}"
          description: "Ventilador {{ $labels.ciscoEnvMonFanDescr }} está em estado {{ $value }}."
```

---

## ⚡ Otimização de Performance

### 1. Configuração de Walk Parameters

```yaml
# Configurações otimizadas por tipo de dispositivo
modules:
  # Para switches de acesso (menos críticos)
  switch_access:
    walk_params:
      timeout: 10s
      retries: 2
      max_repetitions: 25
      
  # Para switches core (mais críticos)
  switch_core:
    walk_params:
      timeout: 15s
      retries: 3
      max_repetitions: 50
      
  # Para roteadores (mais complexos)
  router_advanced:
    walk_params:
      timeout: 20s
      retries: 3
      max_repetitions: 25
```

### 2. Configuração de Scrape Intervals

```yaml
# prometheus.yml - Intervalos otimizados
scrape_configs:
  # Switches críticos - monitoramento frequente
  - job_name: 'snmp-switches-core'
    scrape_interval: 30s
    static_configs:
      - targets: ['192.168.1.10']
    metrics_path: /snmp
    params:
      module: [switch_core]
      
  # Switches de acesso - monitoramento menos frequente
  - job_name: 'snmp-switches-access'
    scrape_interval: 60s
    static_configs:
      - targets: ['192.168.1.11', '192.168.1.12']
    metrics_path: /snmp
    params:
      module: [switch_access]
      
  # Roteadores - monitoramento balanceado
  - job_name: 'snmp-routers'
    scrape_interval: 45s
    static_configs:
      - targets: ['192.168.1.1', '192.168.1.2']
    metrics_path: /snmp
    params:
      module: [router_advanced]
```

### 3. Filtragem de Métricas

```yaml
# prometheus.yml - Filtragem de métricas
scrape_configs:
  - job_name: 'snmp-switches'
    static_configs:
      - targets: ['192.168.1.10']
    metrics_path: /snmp
    params:
      module: [switch_basic]
    metric_relabel_configs:
      # Manter apenas interfaces ativas
      - source_labels: [ifOperStatus]
        regex: '2'  # down
        action: drop
      # Ignorar interfaces loopback
      - source_labels: [ifDescr]
        regex: '.*[Ll]oopback.*'
        action: drop
      # Ignorar interfaces de gerenciamento
      - source_labels: [ifDescr]
        regex: '.*[Mm]gmt.*'
        action: drop
```

---

## 🔧 Configuração de Ambiente Completo

### 1. Docker Compose para Monitoramento de Rede

```yaml
# docker-compose.yml
version: '3.8'

services:
  snmp-exporter:
    image: prom/snmp-exporter:latest
    container_name: snmp-exporter
    ports:
      - "9116:9116"
    volumes:
      - ./snmp.yml:/etc/snmp_exporter/snmp.yml:ro
    command:
      - '--config.file=/etc/snmp_exporter/snmp.yml'
      - '--log.level=info'
    restart: unless-stopped
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./alerts.yml:/etc/prometheus/alerts.yml:ro
      - prometheus_data:/prometheus
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

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    restart: unless-stopped
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    restart: unless-stopped
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
```

### 2. Script de Descoberta Automática

```bash
#!/bin/bash
# network_discovery.sh

NETWORK=${1:-"192.168.1.0/24"}
COMMUNITY=${2:-"public"}
OUTPUT_FILE="discovered_devices.yml"

echo "Descobrindo dispositivos na rede: $NETWORK"
echo "Community: $COMMUNITY"
echo

# Limpar arquivo de saída
> $OUTPUT_FILE

echo "# Dispositivos descobertos automaticamente" >> $OUTPUT_FILE
echo "# Gerado em: $(date)" >> $OUTPUT_FILE
echo >> $OUTPUT_FILE

# Descobrir dispositivos ativos
echo "Escaneando rede..."
nmap -sn $NETWORK | grep "Nmap scan report" | awk '{print $5}' > temp_ips.txt

echo "scrape_configs:" >> $OUTPUT_FILE

# Arrays para diferentes tipos de dispositivos
declare -a switches=()
declare -a routers=()
declare -a cisco_devices=()
declare -a hp_devices=()
declare -a juniper_devices=()

while read -r ip; do
    echo "Testando $ip..."
    
    # Testar conectividade SNMP
    if timeout 5 snmpget -v2c -c $COMMUNITY $ip 1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
        echo "  ✓ SNMP ativo"
        
        # Obter informações do dispositivo
        SYS_DESCR=$(snmpget -v2c -c $COMMUNITY $ip 1.3.6.1.2.1.1.1.0 -Oqv 2>/dev/null)
        SYS_OBJECT_ID=$(snmpget -v2c -c $COMMUNITY $ip 1.3.6.1.2.1.1.2.0 -Oqv 2>/dev/null)
        
        echo "  Descrição: $SYS_DESCR"
        echo "  Object ID: $SYS_OBJECT_ID"
        
        # Classificar dispositivo
        if [[ $SYS_OBJECT_ID == *".9."* ]]; then
            echo "  Tipo: Cisco"
            cisco_devices+=("$ip")
        elif [[ $SYS_OBJECT_ID == *".11."* ]]; then
            echo "  Tipo: HP"
            hp_devices+=("$ip")
        elif [[ $SYS_OBJECT_ID == *".2636."* ]]; then
            echo "  Tipo: Juniper"
            juniper_devices+=("$ip")
        elif [[ $SYS_DESCR == *"switch"* ]] || [[ $SYS_DESCR == *"Switch"* ]]; then
            echo "  Tipo: Switch genérico"
            switches+=("$ip")
        elif [[ $SYS_DESCR == *"router"* ]] || [[ $SYS_DESCR == *"Router"* ]]; then
            echo "  Tipo: Router genérico"
            routers+=("$ip")
        else
            echo "  Tipo: Dispositivo genérico"
            switches+=("$ip")
        fi
        
        echo
    else
        echo "  ✗ SNMP inativo"
    fi
done < temp_ips.txt

# Gerar configuração para cada tipo
if [ ${#cisco_devices[@]} -gt 0 ]; then
    echo "  - job_name: 'snmp-cisco'" >> $OUTPUT_FILE
    echo "    static_configs:" >> $OUTPUT_FILE
    echo "      - targets:" >> $OUTPUT_FILE
    for device in "${cisco_devices[@]}"; do
        echo "        - $device" >> $OUTPUT_FILE
    done
    echo "    metrics_path: /snmp" >> $OUTPUT_FILE
    echo "    params:" >> $OUTPUT_FILE
    echo "      module: [cisco_advanced]" >> $OUTPUT_FILE
    echo >> $OUTPUT_FILE
fi

if [ ${#hp_devices[@]} -gt 0 ]; then
    echo "  - job_name: 'snmp-hp'" >> $OUTPUT_FILE
    echo "    static_configs:" >> $OUTPUT_FILE
    echo "      - targets:" >> $OUTPUT_FILE
    for device in "${hp_devices[@]}"; do
        echo "        - $device" >> $OUTPUT_FILE
    done
    echo "    metrics_path: /snmp" >> $OUTPUT_FILE
    echo "    params:" >> $OUTPUT_FILE
    echo "      module: [hp_procurve]" >> $OUTPUT_FILE
    echo >> $OUTPUT_FILE
fi

if [ ${#juniper_devices[@]} -gt 0 ]; then
    echo "  - job_name: 'snmp-juniper'" >> $OUTPUT_FILE
    echo "    static_configs:" >> $OUTPUT_FILE
    echo "      - targets:" >> $OUTPUT_FILE
    for device in "${juniper_devices[@]}"; do
        echo "        - $device" >> $OUTPUT_FILE
    done
    echo "    metrics_path: /snmp" >> $OUTPUT_FILE
    echo "    params:" >> $OUTPUT_FILE
    echo "      module: [juniper_ex]" >> $OUTPUT_FILE
    echo >> $OUTPUT_FILE
fi

if [ ${#switches[@]} -gt 0 ]; then
    echo "  - job_name: 'snmp-switches'" >> $OUTPUT_FILE
    echo "    static_configs:" >> $OUTPUT_FILE
    echo "      - targets:" >> $OUTPUT_FILE
    for device in "${switches[@]}"; do
        echo "        - $device" >> $OUTPUT_FILE
    done
    echo "    metrics_path: /snmp" >> $OUTPUT_FILE
    echo "    params:" >> $OUTPUT_FILE
    echo "      module: [switch_basic]" >> $OUTPUT_FILE
    echo >> $OUTPUT_FILE
fi

if [ ${#routers[@]} -gt 0 ]; then
    echo "  - job_name: 'snmp-routers'" >> $OUTPUT_FILE
    echo "    static_configs:" >> $OUTPUT_FILE
    echo "      - targets:" >> $OUTPUT_FILE
    for device in "${routers[@]}"; do
        echo "        - $device" >> $OUTPUT_FILE
    done
    echo "    metrics_path: /snmp" >> $OUTPUT_FILE
    echo "    params:" >> $OUTPUT_FILE
    echo "      module: [router_advanced]" >> $OUTPUT_FILE
    echo >> $OUTPUT_FILE
fi

# Limpar arquivos temporários
rm -f temp_ips.txt

echo "Descoberta concluída!"
echo "Configuração salva em: $OUTPUT_FILE"
echo
echo "Resumo:"
echo "  Cisco: ${#cisco_devices[@]} dispositivos"
echo "  HP: ${#hp_devices[@]} dispositivos"
echo "  Juniper: ${#juniper_devices[@]} dispositivos"
echo "  Switches: ${#switches[@]} dispositivos"
echo "  Routers: ${#routers[@]} dispositivos"
```

---

## 📝 Exercícios Práticos

### Exercício 1: Configuração Básica de Switch
1. Configure um módulo básico para switch
2. Teste a conectividade SNMP
3. Valide as métricas coletadas

### Exercício 2: Monitoramento Específico por Fabricante
1. Identifique o fabricante do seu dispositivo
2. Configure módulo específico (Cisco/HP/Juniper)
3. Implemente alertas customizados

### Exercício 3: Descoberta Automática
1. Execute o script de descoberta na sua rede
2. Analise os dispositivos encontrados
3. Ajuste as configurações conforme necessário

---

## 📝 Resumo do Módulo

Neste módulo, você aprendeu:

- ✅ **Configuração de switches** com métricas básicas e avançadas
- ✅ **Monitoramento de roteadores** com estatísticas de rede
- ✅ **Configurações específicas** por fabricante (Cisco, HP, Juniper)
- ✅ **Métricas avançadas** (QoS, VLAN, STP)
- ✅ **Alertas especializados** para dispositivos de rede
- ✅ **Otimização de performance** do monitoramento
- ✅ **Descoberta automática** de dispositivos

### 🎯 Próximos Passos

Agora você está pronto para:

1. **Diagnosticar problemas** de monitoramento SNMP
2. **Resolver issues** comuns de conectividade
3. **Implementar troubleshooting** avançado

---

## 🔗 Navegação

- ⬅️ **Anterior:** [Módulo 04 - MIBs e OIDs](04-mibs-oids.md)
- ➡️ **Próximo:** [Módulo 06 - Troubleshooting](06-troubleshooting.md)

---

**📚 Módulo 05 de 07 - Dispositivos de Rede**
# ⚙️ MÓDULO 02: CONFIGURAÇÃO INICIAL

> **Instalação e configuração do SNMP Exporter com Docker**

## 🎯 Objetivos do Módulo

Ao final deste módulo, você será capaz de:

- ✅ Instalar o SNMP Exporter usando Docker
- ✅ Configurar integração com Prometheus
- ✅ Realizar testes básicos de conectividade SNMP
- ✅ Navegar pela interface web do SNMP Exporter
- ✅ Diagnosticar problemas de configuração

---

## 📋 Pré-requisitos

### Ferramentas Necessárias
```bash
# Verificar instalações
docker --version          # Docker 20.10+
docker-compose --version  # Docker Compose 1.29+
```

### Conhecimentos
- Conceitos básicos de Docker
- Familiaridade com YAML
- Conhecimento básico de redes

### Ambiente de Teste
- Dispositivo SNMP disponível (switch, roteador, ou simulador)
- Conectividade de rede
- Portas liberadas: 9116 (SNMP Exporter), 9090 (Prometheus)

---

## 🚀 Instalação com Docker Compose

### 1. **Estrutura de Diretórios**

Crie a estrutura básica:

```bash
mkdir snmp-monitoring
cd snmp-monitoring

# Estrutura de diretórios
snmp-monitoring/
├── docker-compose.yml
├── prometheus/
│   └── prometheus.yml
├── snmp-exporter/
│   └── snmp.yml
└── data/
    ├── prometheus/
    └── snmp-exporter/
```

### 2. **Docker Compose Configuration**

Crie o arquivo `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # SNMP Exporter
  snmp-exporter:
    image: prom/snmp-exporter:latest
    container_name: snmp-exporter
    ports:
      - "9116:9116"
    volumes:
      - ./snmp-exporter/snmp.yml:/etc/snmp_exporter/snmp.yml:ro
    command:
      - '--config.file=/etc/snmp_exporter/snmp.yml'
      - '--log.level=info'
    restart: unless-stopped
    networks:
      - monitoring

  # Prometheus
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./data/prometheus:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    networks:
      - monitoring
    depends_on:
      - snmp-exporter

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus-data:
  snmp-data:
```

### 3. **Configuração Básica do SNMP Exporter**

Crie `snmp-exporter/snmp.yml`:

```yaml
# Configuração básica do SNMP Exporter
auths:
  # SNMPv2c community
  public_v2:
    community: public
    security_level: noAuthNoPriv
    auth_protocol: MD5
    priv_protocol: DES
    version: 2

  # SNMPv3 exemplo
  secure_v3:
    username: monitoring
    security_level: authPriv
    password: mypassword
    auth_protocol: SHA
    priv_protocol: AES
    priv_password: myprivpassword
    version: 3

modules:
  # Módulo básico para interfaces de rede
  if_mib:
    walk:
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.3   # ifType
      - 1.3.6.1.2.1.2.2.1.7   # ifAdminStatus
      - 1.3.6.1.2.1.2.2.1.8   # ifOperStatus
      - 1.3.6.1.2.1.2.2.1.10  # ifInOctets
      - 1.3.6.1.2.1.2.2.1.16  # ifOutOctets
      - 1.3.6.1.2.1.2.2.1.14  # ifInErrors
      - 1.3.6.1.2.1.2.2.1.20  # ifOutErrors
    lookups:
      - source_indexes: [ifIndex]
        lookup: 1.3.6.1.2.1.2.2.1.2  # ifDescr
        drop_source_indexes: false
    overrides:
      ifAdminStatus:
        type: gauge
      ifOperStatus:
        type: gauge
      ifType:
        type: gauge

  # Módulo para informações do sistema
  system:
    walk:
      - 1.3.6.1.2.1.1.1.0     # sysDescr
      - 1.3.6.1.2.1.1.2.0     # sysObjectID
      - 1.3.6.1.2.1.1.3.0     # sysUpTime
      - 1.3.6.1.2.1.1.4.0     # sysContact
      - 1.3.6.1.2.1.1.5.0     # sysName
      - 1.3.6.1.2.1.1.6.0     # sysLocation

  # Módulo para CPU e memória (genérico)
  host_resources:
    walk:
      - 1.3.6.1.2.1.25.3.3.1.2  # hrProcessorLoad
      - 1.3.6.1.2.1.25.2.3.1.6  # hrStorageUsed
      - 1.3.6.1.2.1.25.2.3.1.5  # hrStorageSize
```

### 4. **Configuração do Prometheus**

Crie `prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # SNMP Exporter self-monitoring
  - job_name: 'snmp-exporter'
    static_configs:
      - targets: ['snmp-exporter:9116']

  # SNMP targets - Switches
  - job_name: 'snmp-switches'
    static_configs:
      - targets:
        - 192.168.1.10  # Switch IP
        - 192.168.1.11  # Switch IP
    metrics_path: /snmp
    params:
      module: [if_mib]  # Usar módulo if_mib
      auth: [public_v2] # Usar auth public_v2
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116

  # SNMP targets - Sistema
  - job_name: 'snmp-system'
    static_configs:
      - targets:
        - 192.168.1.10
    metrics_path: /snmp
    params:
      module: [system]
      auth: [public_v2]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
```

---

## 🏃‍♂️ Executando o Ambiente

### 1. **Iniciar os Serviços**

```bash
# Subir os containers
docker-compose up -d

# Verificar status
docker-compose ps

# Verificar logs
docker-compose logs -f snmp-exporter
docker-compose logs -f prometheus
```

### 2. **Verificar Conectividade**

```bash
# Testar SNMP Exporter
curl http://localhost:9116/

# Testar Prometheus
curl http://localhost:9090/

# Testar consulta SNMP específica
curl "http://localhost:9116/snmp?target=192.168.1.10&module=system&auth=public_v2"
```

---

## 🌐 Interface Web do SNMP Exporter

### Acessando a Interface

Abra o navegador em: `http://localhost:9116`

### Funcionalidades Principais

#### 1. **Página Inicial**
```
SNMP Exporter
├── Configuration
├── Targets
├── Metrics
└── Debug
```

#### 2. **Testando Targets**

Na página inicial, você pode testar targets:

```
Target: 192.168.1.10
Module: if_mib
Auth: public_v2

[Submit Query]
```

#### 3. **Visualizando Métricas**

Exemplo de métricas retornadas:

```prometheus
# HELP snmp_up Was the last scrape of SNMP successful.
# TYPE snmp_up gauge
snmp_up 1

# HELP snmp_duration_seconds Time taken to execute SNMP scrape
# TYPE snmp_duration_seconds gauge
snmp_duration_seconds 0.123

# HELP ifInOctets Interface input octets
# TYPE ifInOctets counter
ifInOctets{ifDescr="GigabitEthernet0/1",ifIndex="1"} 1234567890
```

---

## 🔍 Primeiros Testes

### 1. **Teste de Conectividade SNMP**

```bash
# Usando snmpwalk (se disponível)
snmpwalk -v2c -c public 192.168.1.10 1.3.6.1.2.1.1.1.0

# Usando Docker
docker run --rm -it --network host \
  alpine/net-snmp \
  snmpwalk -v2c -c public 192.168.1.10 1.3.6.1.2.1.1.1.0
```

### 2. **Teste via SNMP Exporter**

```bash
# Teste básico do sistema
curl -s "http://localhost:9116/snmp?target=192.168.1.10&module=system&auth=public_v2" \
  | grep -E "snmp_up|sysName|sysDescr"

# Teste de interfaces
curl -s "http://localhost:9116/snmp?target=192.168.1.10&module=if_mib&auth=public_v2" \
  | grep -E "ifDescr|ifOperStatus"
```

### 3. **Verificar no Prometheus**

Acesse `http://localhost:9090` e execute consultas:

```promql
# Verificar targets SNMP
up{job=~"snmp.*"}

# Verificar interfaces ativas
ifOperStatus == 1

# Tráfego de rede
rate(ifInOctets[5m]) * 8
```

---

## 🛠️ Configurações Avançadas

### 1. **Configuração de Timeout**

```yaml
# Em snmp.yml
modules:
  if_mib:
    walk:
      - 1.3.6.1.2.1.2.2.1.2
    walk_params:
      timeout: 10s
      retries: 3
      max_repetitions: 25
```

### 2. **Configuração de Auth Personalizada**

```yaml
# Para cada dispositivo específico
auths:
  cisco_v3:
    username: cisco_user
    security_level: authPriv
    password: cisco_pass
    auth_protocol: SHA
    priv_protocol: AES
    priv_password: cisco_priv
    version: 3
```

### 3. **Configuração de Logging**

```yaml
# Em docker-compose.yml
command:
  - '--config.file=/etc/snmp_exporter/snmp.yml'
  - '--log.level=debug'  # debug, info, warn, error
  - '--log.format=json'  # json ou logfmt
```

---

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. **SNMP Timeout**
```bash
# Sintomas
snmp_up 0
snmp_duration_seconds > 10

# Soluções
- Verificar conectividade de rede
- Aumentar timeout na configuração
- Verificar community string
- Testar com snmpwalk manual
```

#### 2. **Configuração Inválida**
```bash
# Verificar logs
docker-compose logs snmp-exporter

# Validar configuração
docker exec snmp-exporter \
  /bin/snmp_exporter --config.check
```

#### 3. **Métricas Não Aparecem**
```bash
# Verificar targets no Prometheus
http://localhost:9090/targets

# Verificar configuração do relabel
# Verificar se o módulo está correto
# Verificar se o auth está correto
```

### Comandos de Debug

```bash
# Logs detalhados
docker-compose logs -f --tail=100 snmp-exporter

# Teste manual de SNMP
docker run --rm -it --network host alpine/net-snmp \
  snmpget -v2c -c public 192.168.1.10 1.3.6.1.2.1.1.1.0

# Verificar conectividade
ping 192.168.1.10
telnet 192.168.1.10 161
```

---

## 📊 Métricas Básicas

### Métricas do SNMP Exporter

```prometheus
# Status da coleta
snmp_up                    # 1 = sucesso, 0 = falha
snmp_duration_seconds      # Tempo de coleta
snmp_packets_sent          # Pacotes SNMP enviados
snmp_packets_received      # Pacotes SNMP recebidos
```

### Métricas de Sistema

```prometheus
# Informações do sistema
sysUpTime                  # Uptime do dispositivo
sysName                    # Nome do sistema
sysDescr                   # Descrição do sistema
sysLocation                # Localização
sysContact                 # Contato
```

### Métricas de Interface

```prometheus
# Status das interfaces
ifOperStatus               # Status operacional (1=up, 2=down)
ifAdminStatus              # Status administrativo
ifInOctets                 # Bytes recebidos
ifOutOctets                # Bytes enviados
ifInErrors                 # Erros de entrada
ifOutErrors                # Erros de saída
```

---

## 📝 Exercícios Práticos

### Exercício 1: Configuração Básica
1. Configure o ambiente Docker Compose
2. Teste conectividade com um dispositivo
3. Verifique métricas no Prometheus

### Exercício 2: Múltiplos Dispositivos
1. Adicione 3 dispositivos diferentes
2. Configure módulos específicos para cada um
3. Crie dashboards básicos

### Exercício 3: Troubleshooting
1. Simule um problema de conectividade
2. Analise logs e métricas
3. Implemente solução

---

## 📝 Resumo do Módulo

Neste módulo, você aprendeu:

- ✅ **Instalação** do SNMP Exporter com Docker Compose
- ✅ **Configuração básica** de módulos e autenticação
- ✅ **Integração** com Prometheus
- ✅ **Testes de conectividade** e validação
- ✅ **Interface web** e funcionalidades
- ✅ **Troubleshooting** de problemas comuns

### 🎯 Próximos Passos

Agora você está pronto para:

1. **Aprofundar** na estrutura do arquivo de configuração
2. **Explorar** módulos avançados
3. **Personalizar** configurações para seus dispositivos

---

## 🔗 Navegação

- ⬅️ **Anterior:** [Módulo 01 - Introdução ao SNMP](01-introducao.md)
- ➡️ **Próximo:** [Módulo 03 - Arquivo de Configuração](03-arquivo-config.md)

---

**📚 Módulo 02 de 07 - Configuração Inicial**
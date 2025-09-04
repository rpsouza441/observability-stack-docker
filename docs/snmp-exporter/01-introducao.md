# 📡 MÓDULO 01: INTRODUÇÃO AO SNMP

> **Fundamentos do protocolo SNMP e arquitetura do SNMP Exporter**

## 🎯 Objetivos do Módulo

Ao final deste módulo, você será capaz de:

- ✅ Compreender os conceitos fundamentais do protocolo SNMP
- ✅ Distinguir entre as versões do SNMP (v1, v2c, v3)
- ✅ Entender a arquitetura do SNMP Exporter
- ✅ Identificar casos de uso para monitoramento SNMP
- ✅ Conhecer os benefícios e limitações do SNMP

---

## 📚 O que é SNMP?

**SNMP (Simple Network Management Protocol)** é um protocolo de gerenciamento de rede que permite monitorar e gerenciar dispositivos de rede como:

- 🔌 **Switches e Roteadores**
- 🔥 **Firewalls**
- 🖨️ **Impressoras de Rede**
- 🌡️ **Sensores Ambientais**
- ⚡ **UPS e PDUs**
- 📡 **Access Points WiFi**

### 🏗️ Arquitetura SNMP

```
┌─────────────────┐    SNMP Requests     ┌─────────────────┐
│                 │ ──────────────────► │                 │
│  SNMP Manager   │                     │  SNMP Agent     │
│  (Monitoring)   │ ◄────────────────── │  (Device)       │
│                 │    SNMP Responses   │                 │
└─────────────────┘                     └─────────────────┘
```

#### Componentes Principais:

1. **SNMP Manager** (Cliente)
   - Solicita informações dos dispositivos
   - Processa e armazena dados coletados
   - Exemplo: Prometheus + SNMP Exporter

2. **SNMP Agent** (Servidor)
   - Roda no dispositivo monitorado
   - Responde às solicitações do manager
   - Mantém a MIB (Management Information Base)

3. **MIB (Management Information Base)**
   - Base de dados hierárquica
   - Define objetos monitoráveis
   - Cada objeto tem um OID único

---

## 🔢 Versões do SNMP

### SNMPv1 (1988)
```yaml
Características:
  - Primeira versão do protocolo
  - Autenticação por community string
  - Sem criptografia
  - Limitações de segurança
  
Uso Atual:
  - Ainda usado em dispositivos legados
  - Não recomendado para novos deployments
```

### SNMPv2c (1993)
```yaml
Características:
  - Melhorias de performance
  - Novos tipos de dados
  - Bulk operations (GetBulk)
  - Ainda usa community strings
  
Uso Atual:
  - Versão mais comum em produção
  - Boa compatibilidade
  - Fácil configuração
```

### SNMPv3 (1998)
```yaml
Características:
  - Autenticação robusta (MD5, SHA)
  - Criptografia (DES, AES)
  - Controle de acesso baseado em usuário
  - Maior complexidade de configuração
  
Uso Atual:
  - Recomendado para ambientes seguros
  - Crescente adoção
  - Padrão para compliance
```

---

## 🏛️ Arquitetura do SNMP Exporter

### Como Funciona?

```
┌─────────────┐    HTTP GET     ┌─────────────┐    SNMP     ┌─────────────┐
│             │ ──────────────► │             │ ──────────► │             │
│ Prometheus  │                 │ SNMP        │             │ Network     │
│             │ ◄────────────── │ Exporter    │ ◄────────── │ Device      │
│             │   Metrics       │             │  Response   │             │
└─────────────┘                 └─────────────┘             └─────────────┘
```

### Fluxo de Operação:

1. **Prometheus** faz requisição HTTP para SNMP Exporter
2. **SNMP Exporter** traduz a requisição para SNMP
3. **Dispositivo** responde com dados SNMP
4. **SNMP Exporter** converte dados para formato Prometheus
5. **Prometheus** coleta e armazena as métricas

### Componentes do SNMP Exporter:

#### 1. **Configuração (snmp.yml)**
```yaml
# Define módulos para diferentes tipos de dispositivos
modules:
  if_mib:
    walk:
      - 1.3.6.1.2.1.2.2.1.2   # ifDescr
      - 1.3.6.1.2.1.2.2.1.10  # ifInOctets
```

#### 2. **Módulos**
- Conjuntos de OIDs para coletar
- Configurações específicas por tipo de dispositivo
- Reutilizáveis entre diferentes targets

#### 3. **Generator**
- Ferramenta para criar configurações
- Converte MIBs em configuração YAML
- Simplifica criação de módulos customizados

---

## 🎯 Casos de Uso

### 1. **Monitoramento de Infraestrutura de Rede**
```yaml
Métricas Coletadas:
  - Utilização de interfaces
  - Status de portas
  - Erros de transmissão
  - Temperatura de equipamentos
  - Uso de CPU e memória
```

### 2. **Monitoramento de Data Center**
```yaml
Dispositivos Monitorados:
  - Core switches
  - Distribution switches
  - Access switches
  - Firewalls
  - Load balancers
```

### 3. **Monitoramento de Filiais**
```yaml
Cenários:
  - Conectividade WAN
  - Performance de links
  - Status de equipamentos remotos
  - Monitoramento de UPS
```

### 4. **Compliance e Auditoria**
```yaml
Requisitos:
  - Histórico de disponibilidade
  - Relatórios de performance
  - Alertas de falhas
  - Documentação de incidentes
```

---

## ✅ Vantagens do SNMP

### 🚀 **Performance**
- Protocolo leve e eficiente
- Baixo overhead de rede
- Suporte a bulk operations (v2c+)

### 🔧 **Compatibilidade**
- Suportado por praticamente todos os dispositivos de rede
- Padrão da indústria há décadas
- Ampla base de conhecimento

### 📊 **Riqueza de Dados**
- Acesso a métricas detalhadas
- Informações de configuração
- Status operacional em tempo real

### 🔄 **Padronização**
- MIBs padronizadas (RFC)
- OIDs consistentes entre fabricantes
- Ferramentas universais

---

## ⚠️ Limitações do SNMP

### 🔒 **Segurança (v1/v2c)**
```yaml
Problemas:
  - Community strings em texto claro
  - Sem autenticação robusta
  - Vulnerável a ataques de rede
  
Solução:
  - Usar SNMPv3 quando possível
  - Restringir acesso por ACLs
  - Monitorar em redes seguras
```

### 📈 **Escalabilidade**
```yaml
Desafios:
  - Muitos dispositivos = muitas conexões
  - Timeouts em redes lentas
  - Overhead de polling
  
Solução:
  - Configurar intervalos apropriados
  - Usar bulk operations
  - Implementar circuit breakers
```

### 🔧 **Complexidade de Configuração**
```yaml
Dificuldades:
  - MIBs específicas por fabricante
  - OIDs complexos
  - Configuração manual
  
Solução:
  - Usar SNMP Generator
  - Documentar configurações
  - Criar templates reutilizáveis
```

---

## 🛠️ SNMP vs Outras Tecnologias

### SNMP vs REST APIs
```yaml
SNMP:
  ✅ Universalmente suportado
  ✅ Padronizado
  ✅ Eficiente para polling
  ❌ Limitações de segurança
  ❌ Complexidade de OIDs

REST APIs:
  ✅ Segurança moderna
  ✅ Dados estruturados (JSON)
  ✅ Flexibilidade
  ❌ Não universal
  ❌ Overhead HTTP
```

### SNMP vs Streaming Telemetry
```yaml
SNMP:
  ✅ Pull model (controle do collector)
  ✅ Compatibilidade legacy
  ❌ Polling overhead
  ❌ Latência de dados

Streaming:
  ✅ Push model (tempo real)
  ✅ Eficiência de rede
  ❌ Complexidade de implementação
  ❌ Suporte limitado
```

---

## 🎯 Quando Usar SNMP?

### ✅ **Cenários Ideais**
- Monitoramento de dispositivos de rede tradicionais
- Ambientes com equipamentos de múltiplos fabricantes
- Necessidade de métricas padronizadas
- Infraestrutura existente baseada em SNMP

### ❌ **Cenários Não Ideais**
- Aplicações modernas com APIs nativas
- Ambientes cloud-native
- Requisitos de segurança muito rigorosos (sem SNMPv3)
- Necessidade de dados em tempo real

---

## 📝 Resumo do Módulo

Neste módulo, você aprendeu:

- ✅ **Conceitos fundamentais** do protocolo SNMP
- ✅ **Diferenças entre versões** (v1, v2c, v3)
- ✅ **Arquitetura do SNMP Exporter** e seu papel no ecossistema Prometheus
- ✅ **Casos de uso práticos** para monitoramento SNMP
- ✅ **Vantagens e limitações** da tecnologia
- ✅ **Comparações** com outras tecnologias de monitoramento

### 🎯 Próximos Passos

Agora que você compreende os fundamentos do SNMP, está pronto para:

1. **Configurar o ambiente** de desenvolvimento
2. **Instalar o SNMP Exporter**
3. **Realizar os primeiros testes** de conectividade

---

## 🔗 Navegação

- ⬅️ **Anterior:** [README - Visão Geral](README.md)
- ➡️ **Próximo:** [Módulo 02 - Configuração Inicial](02-configuracao.md)

---

**📚 Módulo 01 de 07 - Introdução ao SNMP**
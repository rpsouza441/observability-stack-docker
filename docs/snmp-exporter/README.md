# 📡 SNMP EXPORTER - GUIA EDUCACIONAL MODULAR

> **Documentação Educacional Completa para SNMP Exporter**  
> Aprenda a monitorar dispositivos de rede usando SNMP com Prometheus

## 📋 Visão Geral

Este guia educacional foi estruturado em módulos progressivos para ensinar o uso do SNMP Exporter com Prometheus, desde conceitos básicos até implementações avançadas em ambientes de produção.

## 🎯 Objetivos de Aprendizagem

Ao completar este guia, você será capaz de:

- ✅ Compreender os fundamentos do protocolo SNMP
- ✅ Configurar e usar o SNMP Exporter
- ✅ Monitorar dispositivos de rede (switches, roteadores, firewalls)
- ✅ Trabalhar com MIBs e OIDs
- ✅ Criar configurações personalizadas para diferentes dispositivos
- ✅ Resolver problemas comuns de monitoramento SNMP
- ✅ Implementar um sistema completo de monitoramento de rede

## 📚 Estrutura dos Módulos

### 🔰 **Módulo 01: [Introdução ao SNMP](01-introducao.md)**
- Conceitos fundamentais do protocolo SNMP
- Versões do SNMP (v1, v2c, v3)
- Arquitetura do SNMP Exporter
- Casos de uso e benefícios

### ⚙️ **Módulo 02: [Configuração Inicial](02-configuracao.md)**
- Instalação do SNMP Exporter
- Configuração básica com Docker
- Integração com Prometheus
- Primeiros testes de conectividade

### 📄 **Módulo 03: [Arquivo de Configuração](03-arquivo-config.md)**
- Estrutura do arquivo snmp.yml
- Módulos e métricas
- Configuração de autenticação
- Walkthrough de configurações

### 🔍 **Módulo 04: [MIBs e OIDs](04-mibs-oids.md)**
- Conceitos de MIB (Management Information Base)
- Trabalhando com OIDs (Object Identifiers)
- Descoberta automática de dispositivos
- Ferramentas de análise SNMP

### 🌐 **Módulo 05: [Dispositivos de Rede](05-dispositivos-rede.md)**
- Monitoramento de switches
- Monitoramento de roteadores
- Configurações específicas por fabricante
- Métricas de performance de rede

### 🔧 **Módulo 06: [Troubleshooting](06-troubleshooting.md)**
- Diagnóstico de problemas SNMP
- Ferramentas de debug
- Problemas comuns e soluções
- Otimização de performance

### 🚀 **Módulo 07: [Projeto Final](07-projeto-final.md)**
- Projeto prático completo
- Monitoramento de infraestrutura de rede
- Dashboards e alertas
- Implementação em produção

## 🎓 Trilhas de Aprendizado

### 🟢 **Iniciante** (4-6 horas)
```
Módulo 01 → Módulo 02 → Módulo 03 → Exercícios Básicos
```
**Ideal para:** Profissionais novos em SNMP e monitoramento de rede

### 🟡 **Intermediário** (6-8 horas)
```
Módulo 01 → Módulo 02 → Módulo 03 → Módulo 04 → Módulo 05 → Projeto Prático
```
**Ideal para:** Administradores de rede com experiência básica

### 🔴 **Avançado** (8-12 horas)
```
Todos os Módulos + Projeto Final + Customizações Avançadas
```
**Ideal para:** Engenheiros de monitoramento e DevOps

## 📋 Pré-requisitos

### Conhecimentos Básicos
- [ ] Conceitos básicos de redes (TCP/IP, switches, roteadores)
- [ ] Familiaridade com Docker e containers
- [ ] Conhecimento básico de Prometheus
- [ ] Experiência com linha de comando

### Ferramentas Necessárias
- [ ] Docker e Docker Compose
- [ ] Editor de texto (VS Code recomendado)
- [ ] Acesso a dispositivos de rede para testes
- [ ] Cliente SNMP (snmpwalk, snmpget)

## 🚀 Como Usar Este Guia

### 1. **Preparação**
```bash
# Clone o repositório
git clone <repository-url>
cd observability-stack-docker

# Verifique os pré-requisitos
docker --version
docker-compose --version
```

### 2. **Navegação**
- Siga os módulos em ordem sequencial
- Complete os exercícios práticos
- Teste os exemplos em seu ambiente

### 3. **Prática**
- Use os arquivos de exemplo em `examples/`
- Adapte as configurações para seu ambiente
- Documente suas customizações

## 📁 Estrutura de Arquivos

```
docs/snmp-exporter/
├── README.md                 # Este arquivo
├── 01-introducao.md         # Conceitos fundamentais
├── 02-configuracao.md       # Configuração inicial
├── 03-arquivo-config.md     # Estrutura do snmp.yml
├── 04-mibs-oids.md         # MIBs e OIDs
├── 05-dispositivos-rede.md  # Monitoramento de rede
├── 06-troubleshooting.md    # Resolução de problemas
└── 07-projeto-final.md      # Projeto prático
```

## 🔗 Links Úteis

### Documentação Oficial
- [SNMP Exporter GitHub](https://github.com/prometheus/snmp_exporter)
- [Prometheus SNMP Exporter Docs](https://prometheus.io/docs/instrumenting/exporters/)
- [SNMP Protocol RFC](https://tools.ietf.org/html/rfc1157)

### Ferramentas
- [MIB Browser Online](http://www.oidview.com/mibs/detail.html)
- [OID Repository](http://oid-info.com/)
- [SNMP Generator](https://github.com/prometheus/snmp_exporter/tree/main/generator)

### Recursos Adicionais
- [Net-SNMP Tools](http://www.net-snmp.org/)
- [SNMP Best Practices](https://www.cisco.com/c/en/us/support/docs/ip/simple-network-management-protocol-snmp/7244-snmp-best-practices.html)

---

## 📞 Suporte

Se encontrar problemas ou tiver dúvidas:

1. **Consulte o módulo de [Troubleshooting](06-troubleshooting.md)**
2. **Verifique os exemplos práticos**
3. **Revise a documentação oficial**

---

**Autor:** Equipe de Observabilidade  
**Versão:** 1.0  
**Última Atualização:** Janeiro 2024

---

### 🎯 Próximos Passos

**Pronto para começar?** 👉 [Módulo 01: Introdução ao SNMP](01-introducao.md)
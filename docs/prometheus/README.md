# 📊 PROMETHEUS - GUIA EDUCACIONAL MODULAR

> **Trilha de Aprendizado Completa do Prometheus**  
> **Objetivo:** Dominar o Prometheus do básico ao avançado através de módulos organizados

---

## 🎯 SOBRE ESTA TRILHA

Este guia foi dividido em **10 módulos educacionais** para facilitar o aprendizado progressivo do Prometheus. Cada módulo constrói sobre o conhecimento do anterior, proporcionando uma experiência de aprendizado estruturada e eficiente.

---

## 📚 ESTRUTURA MODULAR

### 🟢 **MÓDULOS FUNDAMENTAIS**

| Módulo | Arquivo | Descrição | Duração |
|--------|---------|-----------|----------|
| **01** | [**Introdução**](01-introducao.md) | O que é Prometheus, conceitos básicos e arquitetura | 30 min |
| **02** | [**Configuração Inicial**](02-configuracao.md) | Primeira execução, Docker Compose e interface web | 45 min |
| **03** | [**Arquivo de Configuração**](03-arquivo-config.md) | Entendendo o prometheus.yml em detalhes | 60 min |

### 🟡 **MÓDULOS PRÁTICOS**

| Módulo | Arquivo | Descrição | Duração |
|--------|---------|-----------|----------|
| **04** | [**Coleta de Métricas**](04-coleta-metricas.md) | Exporters, targets e scraping | 75 min |
| **05** | [**PromQL Básico**](05-promql-basico.md) | Linguagem de consulta - fundamentos | 90 min |
| **06** | [**PromQL Avançado**](06-promql-avancado.md) | Funções complexas, agregações e operadores | 90 min |
| **07** | [**Regras de Alerta**](07-regras-alerta.md) | Criando e gerenciando alertas eficazes | 75 min |

### 🔴 **MÓDULOS AVANÇADOS**

| Módulo | Arquivo | Descrição | Duração |
|--------|---------|-----------|----------|
| **08** | [**Troubleshooting**](08-troubleshooting.md) | Diagnóstico e resolução de problemas | 60 min |
| **09** | [**Configuração Avançada**](09-configuracao-avancada.md) | Service discovery, federação e otimização | 90 min |
| **10** | [**Projeto Final**](10-projeto-final.md) | Implementação completa de monitoramento | 120 min |

---

## 🎓 TRILHAS DE APRENDIZADO

### 👶 **INICIANTE** (4-6 horas)
```
01-introducao.md → 02-configuracao.md → 03-arquivo-config.md → 04-coleta-metricas.md
```
**Objetivo:** Entender conceitos básicos e fazer primeira configuração

### 🧑‍💻 **INTERMEDIÁRIO** (8-10 horas)
```
Módulos 01-04 → 05-promql-basico.md → 06-promql-avancado.md → 07-regras-alerta.md
```
**Objetivo:** Dominar PromQL e criar alertas eficazes

### 🚀 **AVANÇADO** (12-15 horas)
```
Todos os módulos → 08-troubleshooting.md → 09-configuracao-avancada.md → 10-projeto-final.md
```
**Objetivo:** Implementar soluções completas de monitoramento em produção

---

## 🎯 OBJETIVOS DE APRENDIZADO

Ao completar esta trilha, você será capaz de:

### 📊 **Fundamentos**
- ✅ Explicar como o Prometheus funciona
- ✅ Configurar coleta de métricas básica
- ✅ Navegar pela interface web
- ✅ Entender o modelo de dados do Prometheus

### 🔍 **PromQL e Consultas**
- ✅ Escrever queries PromQL eficientes
- ✅ Usar funções de agregação e matemáticas
- ✅ Criar dashboards informativos
- ✅ Otimizar consultas para performance

### 🚨 **Alertas e Monitoramento**
- ✅ Criar regras de alerta inteligentes
- ✅ Configurar diferentes níveis de severidade
- ✅ Implementar alertas para infraestrutura completa
- ✅ Evitar alert fatigue

### 🛠️ **Operação e Troubleshooting**
- ✅ Diagnosticar problemas de coleta
- ✅ Otimizar performance do Prometheus
- ✅ Implementar alta disponibilidade
- ✅ Gerenciar retenção de dados

---

## 🛠️ PRÉ-REQUISITOS

### **Conhecimentos Necessários:**
- 🐳 Docker e Docker Compose (básico)
- 🖥️ Linha de comando Linux/Windows
- 🌐 Conceitos básicos de redes (HTTP, portas)
- 📊 Noções básicas de monitoramento

### **Ferramentas Necessárias:**
- Docker Desktop ou Docker Engine
- Editor de texto (VS Code recomendado)
- Navegador web moderno
- Acesso à internet para downloads

---

## 📖 COMO USAR ESTE GUIA

### 🎯 **Aprendizado Linear**
1. Siga os módulos em ordem numérica
2. Complete os exercícios práticos de cada módulo
3. Teste os exemplos em seu ambiente
4. Faça anotações dos conceitos importantes

### 🔄 **Aprendizado por Tópicos**
1. Use o índice para encontrar tópicos específicos
2. Consulte os pré-requisitos de cada módulo
3. Revise conceitos fundamentais quando necessário

### 🧪 **Laboratório Prático**
1. Configure o ambiente usando o `docker-compose.yml`
2. Execute os exemplos em tempo real
3. Modifique configurações para experimentar
4. Documente suas descobertas

---

## 🔗 LINKS ÚTEIS

### **Documentação Oficial**
- [Prometheus Documentation](https://prometheus.io/docs/)
- [PromQL Documentation](https://prometheus.io/docs/prometheus/latest/querying/)
- [Configuration Reference](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

### **Recursos da Comunidade**
- [Awesome Prometheus](https://github.com/roaldnefs/awesome-prometheus)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Best Practices](https://prometheus.io/docs/practices/)

### **Ferramentas Relacionadas**
- [Grafana](https://grafana.com/) - Visualização de dados
- [Alertmanager](../alertmanager/README.md) - Gerenciamento de alertas
- [Node Exporter](https://github.com/prometheus/node_exporter) - Métricas de sistema

---

## 🤝 CONTRIBUIÇÕES

Este guia é um documento vivo! Contribuições são bem-vindas:

- 📝 Correções e melhorias no conteúdo
- 💡 Novos exemplos práticos
- 🐛 Correção de erros
- 📚 Recursos adicionais

---

## 🚀 COMEÇAR AGORA

**Pronto para começar?** 

👉 **[Módulo 01: Introdução ao Prometheus](01-introducao.md)**

---

*Guia criado pela comunidade DevOps*  
*Última atualização: Janeiro 2025*  
*Versão: 2.0 - Modular*
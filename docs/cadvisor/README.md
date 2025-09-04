# 📊 cAdvisor - Documentação Completa

> **Container Advisor (cAdvisor)** - Monitoramento e análise de recursos de containers em tempo real

## 🎯 Sobre Esta Documentação

Esta documentação oferece um guia completo e prático para implementar, configurar e otimizar o **cAdvisor** em ambientes de produção. Organizada de forma modular, permite tanto aprendizado progressivo quanto consulta rápida para profissionais experientes.

## 📚 Módulos de Aprendizado

### 🚀 Fundamentos
- **[Módulo 01: Introdução ao cAdvisor](01-introducao.md)**
  - Conceitos fundamentais
  - Arquitetura e componentes
  - Casos de uso e benefícios
  - Comparação com outras ferramentas

### ⚙️ Configuração e Deploy
- **[Módulo 02: Configuração e Deploy](02-configuracao-deploy.md)**
  - Instalação via Docker
  - Deploy em Kubernetes
  - Configurações avançadas
  - Parâmetros de inicialização

### 📈 Métricas e Coleta
- **[Módulo 03: Métricas e Coleta](03-metricas-coleta.md)**
  - Tipos de métricas disponíveis
  - Endpoints e APIs
  - Configuração de coleta
  - Integração com sistemas externos

### 🔗 Integração com Prometheus
- **[Módulo 04: Integração com Prometheus](04-integracao-prometheus.md)**
  - Configuração de scraping
  - Queries PromQL específicas
  - Dashboards no Grafana
  - Alertas baseados em métricas

### 🔧 Troubleshooting e Performance
- **[Módulo 05: Troubleshooting e Performance](05-troubleshooting-performance.md)**
  - Diagnóstico de problemas
  - Otimização de performance
  - Resolução de erros comuns
  - Monitoramento do próprio cAdvisor

### 🎯 Projeto Final
- **[Módulo 06: Projeto Final](06-projeto-final.md)**
  - Implementação completa
  - Monitoramento de containers em produção
  - Dashboards avançados
  - Alertas inteligentes

## 🛠️ Pré-requisitos

### Conhecimentos Necessários
- **Básico:** Docker, containers, conceitos de monitoramento
- **Intermediário:** Prometheus, Grafana, PromQL
- **Avançado:** Kubernetes, observabilidade

### Ferramentas Requeridas
- Docker / Docker Compose
- Prometheus (para integração)
- Grafana (para visualização)
- Kubernetes (opcional, para deploy em cluster)

## 🚀 Início Rápido

### 1. Deploy Básico com Docker
```bash
# Executar cAdvisor
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor:latest
```

### 2. Verificar Funcionamento
```bash
# Acessar interface web
echo "cAdvisor Web UI: http://localhost:8080"

# Verificar métricas
curl http://localhost:8080/metrics
```

### 3. Integração com Prometheus
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']
    scrape_interval: 15s
    metrics_path: /metrics
```

## 📊 Métricas Principais

### Container Resources
- **CPU:** `container_cpu_usage_seconds_total`
- **Memory:** `container_memory_usage_bytes`
- **Network:** `container_network_receive_bytes_total`
- **Filesystem:** `container_fs_usage_bytes`

### System Resources
- **Machine CPU:** `machine_cpu_cores`
- **Machine Memory:** `machine_memory_bytes`
- **Load Average:** `machine_load1`

## 🎯 Casos de Uso

### 1. Monitoramento de Desenvolvimento
- Análise de consumo de recursos
- Identificação de vazamentos de memória
- Otimização de containers

### 2. Produção e Observabilidade
- Alertas de recursos críticos
- Capacity planning
- Troubleshooting de performance

### 3. Kubernetes e Orquestração
- Métricas de pods e namespaces
- Horizontal Pod Autoscaling (HPA)
- Cluster resource management

## 🔗 Integrações

### Ferramentas de Monitoramento
- **Prometheus** - Coleta e armazenamento de métricas
- **Grafana** - Visualização e dashboards
- **AlertManager** - Gerenciamento de alertas

### Plataformas de Orquestração
- **Kubernetes** - Deploy nativo via DaemonSet
- **Docker Swarm** - Monitoramento de serviços
- **OpenShift** - Integração empresarial

### Ferramentas de APM
- **Jaeger** - Distributed tracing
- **New Relic** - Application monitoring
- **Datadog** - Observabilidade completa

## 📈 Roadmap de Aprendizado

### Iniciante (1-2 semanas)
1. Conceitos básicos de containers
2. Instalação e configuração inicial
3. Interface web e métricas básicas
4. Integração simples com Prometheus

### Intermediário (2-3 semanas)
5. Configurações avançadas
6. Queries PromQL específicas
7. Dashboards personalizados
8. Alertas e notificações

### Avançado (3-4 semanas)
9. Deploy em Kubernetes
10. Otimização de performance
11. Troubleshooting avançado
12. Projeto completo de monitoramento

## 🤝 Contribuição

Esta documentação é um projeto vivo! Contribuições são bem-vindas:

- **Issues:** Reporte problemas ou sugira melhorias
- **Pull Requests:** Contribua com correções ou novos conteúdos
- **Feedback:** Compartilhe sua experiência e sugestões

## 📚 Recursos Adicionais

### Documentação Oficial
- [cAdvisor GitHub](https://github.com/google/cadvisor)
- [cAdvisor Documentation](https://github.com/google/cadvisor/blob/master/docs/)
- [Prometheus Integration](https://prometheus.io/docs/guides/cadvisor/)

### Comunidade
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [Prometheus Community](https://prometheus.io/community/)
- [CNCF Slack](https://slack.cncf.io/)

### Cursos e Certificações
- Certified Kubernetes Administrator (CKA)
- Prometheus Certified Associate (PCA)
- Docker Certified Associate (DCA)

---

## 🎯 Próximos Passos

1. **[Comece pelo Módulo 01](01-introducao.md)** - Entenda os conceitos fundamentais
2. **Pratique com exemplos** - Cada módulo inclui exercícios práticos
3. **Implemente o projeto final** - Aplique todo o conhecimento adquirido
4. **Explore integrações** - Conecte com outras ferramentas do ecossistema

---

**Desenvolvido com ❤️ para a comunidade de DevOps e SRE**

*Última atualização: Janeiro 2025*
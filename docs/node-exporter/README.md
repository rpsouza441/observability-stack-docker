# Node Exporter - Documentação Modular

> **Guia completo e prático** para dominar o Node Exporter - coleta de métricas de sistema para Prometheus

## 📖 Sobre esta Documentação

Esta documentação oferece um **aprendizado estruturado e hands-on** do Node Exporter, desde conceitos básicos até implementações avançadas em produção. Cada módulo combina teoria sólida com exercícios práticos e exemplos reais.

## 🎯 Objetivos de Aprendizado

Ao completar esta documentação, você será capaz de:

✅ **Compreender** a arquitetura e funcionamento do Node Exporter  
✅ **Instalar e configurar** Node Exporter em diferentes ambientes  
✅ **Dominar** collectors e métricas de sistema  
✅ **Integrar** com Prometheus e service discovery  
✅ **Criar** dashboards e alertas profissionais  
✅ **Diagnosticar** problemas e otimizar performance  
✅ **Implementar** monitoramento completo de infraestrutura  

## 📚 Módulos de Aprendizado

### [📋 Módulo 01: Introdução ao Node Exporter](01-introducao.md)
**Fundamentos e conceitos essenciais**
- Arquitetura e componentes do Node Exporter
- Tipos de métricas de sistema coletadas
- Comparação com outras ferramentas de monitoramento
- Casos de uso e cenários práticos
- **Exercício:** Deploy básico e exploração de métricas

### [⚙️ Módulo 02: Instalação e Configuração](02-instalacao-configuracao.md)
**Deploy e configuração em diferentes ambientes**
- Instalação via binário, package manager e Docker
- Configuração como serviço systemd
- Configurações de segurança e performance
- Deployment em Kubernetes
- **Exercício:** Setup completo multi-ambiente

### [📊 Módulo 03: Collectors e Métricas](03-collectors-metricas.md)
**Domínio completo dos collectors disponíveis**
- Collectors padrão e opcionais
- Configuração e filtros de métricas
- Collectors customizados e textfile collector
- Otimização de coleta por ambiente
- **Exercício:** Configuração avançada de collectors

### [🔗 Módulo 04: Integração com Prometheus](04-integracao-prometheus.md)
**Integração completa com Prometheus**
- Configuração de scraping e service discovery
- PromQL queries essenciais para métricas de sistema
- Relabeling e metric relabeling
- Federation e high availability
- **Exercício:** Stack Prometheus + Node Exporter completa

### [📈 Módulo 05: Dashboards e Alertas](05-dashboards-alertas.md)
**Visualização e alertas profissionais**
- Dashboards Grafana para infraestrutura
- Alertas críticos para sistema e hardware
- SLIs/SLOs para infraestrutura
- Runbooks e automação de resposta
- **Exercício:** Sistema completo de alertas

### [🔧 Módulo 06: Troubleshooting e Otimização](06-troubleshooting-otimizacao.md)
**Diagnóstico e otimização avançada**
- Diagnóstico de problemas comuns
- Otimização de performance e recursos
- Monitoramento do próprio Node Exporter
- Tuning para ambientes de alta escala
- **Exercício:** Otimização para produção

### [🚀 Módulo 07: Projeto Final](07-projeto-final.md)
**Implementação completa de monitoramento de infraestrutura**
- Arquitetura de monitoramento multi-datacenter
- Automação completa de deploy e manutenção
- Integração com ferramentas de observabilidade
- Disaster recovery e backup
- **Exercício:** Projeto real de monitoramento

## 🛠️ Pré-requisitos

### Conhecimento Necessário
- **Linux básico**: comandos, processos, sistema de arquivos
- **Docker**: containers e docker-compose
- **Prometheus**: conceitos básicos de métricas
- **YAML/JSON**: configuração de arquivos

### Ferramentas Necessárias
- **Docker** e **Docker Compose**
- **Git** para versionamento
- **curl/wget** para testes de API
- **Editor de texto** (VS Code recomendado)
- **Navegador web** para interfaces

## ⚡ Quick Start

### Deploy Rápido com Docker

```bash
# Node Exporter standalone
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  -p 9100:9100 \
  -v "/proc:/host/proc:ro" \
  -v "/sys:/host/sys:ro" \
  -v "/:/rootfs:ro" \
  --pid="host" \
  --net="host" \
  prom/node-exporter:latest \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --collector.filesystem.mount-points-exclude='^/(sys|proc|dev|host|etc)($$|/)'

# Verificar métricas
curl http://localhost:9100/metrics | head -20
```

### Stack Completa (Node Exporter + Prometheus + Grafana)

```yaml
# docker-compose.yml
version: '3.8'

services:
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
      - '--collector.systemd'
      - '--collector.processes'
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
```

```bash
# Deploy da stack
docker-compose up -d

# Acessar serviços
echo "Node Exporter: http://localhost:9100"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000 (admin/admin123)"
```

## 📊 Métricas Principais

### Sistema Operacional
```promql
# CPU Usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk Usage
100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes)

# Load Average
node_load1
node_load5
node_load15
```

### Rede e I/O
```promql
# Network Traffic
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])

# Disk I/O
rate(node_disk_read_bytes_total[5m])
rate(node_disk_written_bytes_total[5m])

# Disk IOPS
rate(node_disk_reads_completed_total[5m])
rate(node_disk_writes_completed_total[5m])
```

## 🎯 Casos de Uso

### 🖥️ Monitoramento de Servidores
- **Métricas de sistema**: CPU, memória, disco, rede
- **Alertas proativos**: recursos críticos, falhas de hardware
- **Capacity planning**: análise de tendências e crescimento

### ☁️ Infraestrutura Cloud
- **Multi-cloud monitoring**: AWS, GCP, Azure
- **Auto-scaling metrics**: métricas para HPA/VPA
- **Cost optimization**: identificação de recursos subutilizados

### 🏢 Ambientes Corporativos
- **Compliance**: métricas para auditoria e SLA
- **ITSM integration**: integração com ServiceNow, JIRA
- **Executive dashboards**: KPIs de infraestrutura

## 🔗 Integrações

- **Prometheus**: Coleta e armazenamento de métricas
- **Grafana**: Visualização e dashboards
- **AlertManager**: Gerenciamento de alertas
- **Kubernetes**: Service discovery e deployment
- **Consul**: Service discovery dinâmico
- **Ansible**: Automação de deployment
- **Terraform**: Infrastructure as Code

## 🛣️ Roadmap de Aprendizado

### 📅 Semana 1: Fundamentos
- **Dia 1-2**: Módulo 01 (Introdução)
- **Dia 3-4**: Módulo 02 (Instalação)
- **Dia 5-7**: Módulo 03 (Collectors)

### 📅 Semana 2: Integração
- **Dia 1-3**: Módulo 04 (Prometheus)
- **Dia 4-5**: Módulo 05 (Dashboards)
- **Dia 6-7**: Módulo 06 (Troubleshooting)

### 📅 Semana 3: Projeto
- **Dia 1-7**: Módulo 07 (Projeto Final)

## 🤝 Contribuição

Contribuições são bem-vindas! Para contribuir:

1. **Fork** este repositório
2. **Crie** uma branch para sua feature
3. **Implemente** melhorias ou correções
4. **Teste** suas alterações
5. **Submeta** um Pull Request

### Tipos de Contribuição
- 📝 **Documentação**: melhorias, correções, exemplos
- 🐛 **Bug fixes**: correção de erros nos exemplos
- ✨ **Features**: novos módulos, exercícios, casos de uso
- 🎨 **UX**: melhorias na organização e navegação

## 📚 Recursos Adicionais

### Documentação Oficial
- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Node Exporter Dashboard](https://grafana.com/grafana/dashboards/1860)

### Comunidade
- [Prometheus Community](https://prometheus.io/community/)
- [CNCF Slack #prometheus](https://slack.cncf.io/)
- [Reddit r/PrometheusMonitoring](https://reddit.com/r/PrometheusMonitoring)

### Cursos e Certificações
- [Prometheus Certified Associate (PCA)](https://training.linuxfoundation.org/certification/prometheus-certified-associate/)
- [CNCF Training Courses](https://www.cncf.io/training/)

## 🚀 Próximos Passos

1. **[Comece pelo Módulo 01](01-introducao.md)** - Introdução ao Node Exporter
2. **Configure seu ambiente** de desenvolvimento
3. **Siga os exercícios práticos** de cada módulo
4. **Implemente o projeto final** para consolidar o aprendizado
5. **Explore integrações avançadas** com outras ferramentas

---

## 🧭 Navegação

🏠 **[Voltar ao README Principal](../README.md)**

➡️ **[Próximo: 01 - Introdução ao Node Exporter](01-introducao.md)**

---

> 💡 **Dica:** Esta documentação é **progressiva** - cada módulo constrói sobre o conhecimento anterior. Recomendamos seguir a ordem sugerida para máximo aproveitamento!
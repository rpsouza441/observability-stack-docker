# Grafana Provisioning - Estrutura Modular

Este diretório contém a configuração modular para provisionamento automático do Grafana, organizando datasources e dashboards de forma estruturada e escalável.

## 📁 Estrutura de Diretórios

```
provisioning/
├── datasources/           # Configurações de fontes de dados
│   ├── prometheus.yml     # Prometheus, Alertmanager, Thanos/VictoriaMetrics
│   └── logs-and-traces.yml # Loki, Jaeger, Tempo, APM, Cloud providers
├── dashboards/            # Configurações de dashboards
│   ├── dashboards.yml     # Configuração principal dos providers
│   ├── infrastructure/    # Dashboards de infraestrutura
│   │   └── node-exporter-overview.json
│   ├── applications/      # Dashboards de aplicações
│   │   └── docker-containers.json
│   ├── network/          # Dashboards de rede
│   │   └── snmp-switches.json
│   ├── database/         # Dashboards de banco de dados
│   ├── kubernetes/       # Dashboards do Kubernetes
│   ├── security/         # Dashboards de segurança
│   ├── business/         # Dashboards de negócio
│   ├── observability/    # Dashboards de observabilidade
│   ├── sre/             # Dashboards SRE
│   ├── development/      # Dashboards de desenvolvimento
│   ├── cloud/           # Dashboards de cloud providers
│   └── custom/          # Dashboards customizados
├── notifiers/           # Configurações de notificações (legacy)
└── plugins/             # Configurações de plugins
```

## 🔧 Datasources

### prometheus.yml
Configura as principais fontes de dados de métricas:
- **Prometheus Principal**: Servidor principal de métricas
- **Alertmanager**: Para visualização de alertas
- **Long-term Storage**: Thanos/VictoriaMetrics para retenção longa
- **Federated Prometheus**: Instâncias federadas

### logs-and-traces.yml
Configura fontes de dados para logs, traces e APM:
- **Logs**: Loki, Elasticsearch, FluentBit
- **Traces**: Jaeger, Tempo, Zipkin
- **APM**: Elastic APM
- **Profiling**: Pyroscope, Parca
- **Cloud**: CloudWatch, Azure Monitor, Google Cloud

## 📊 Dashboards

### Configuração Principal (dashboards.yml)
Define os providers de dashboards organizados por categoria:
- Configuração de pastas automáticas
- Estratégias de atualização
- Controle de versão
- Padrões de dashboard

### Categorias de Dashboards

#### 🏗️ Infrastructure
- **Node Exporter**: Monitoramento de sistemas (CPU, memória, disco, rede)
- **Hardware**: Sensores, temperatura, energia
- **Storage**: Sistemas de arquivos, I/O de disco

#### 🚀 Applications
- **Docker Containers**: Monitoramento via cAdvisor
- **Application Metrics**: Métricas customizadas de aplicações
- **Service Health**: Status e performance de serviços

#### 🌐 Network
- **SNMP Switches**: Monitoramento de switches via SNMP
- **Network Traffic**: Análise de tráfego de rede
- **Firewall**: Logs e métricas de firewall

#### 🗄️ Database
- **MySQL/PostgreSQL**: Performance e métricas de banco
- **MongoDB**: Métricas de NoSQL
- **Redis**: Cache e performance

#### ☸️ Kubernetes
- **Cluster Overview**: Visão geral do cluster
- **Pod Monitoring**: Monitoramento de pods
- **Resource Usage**: Uso de recursos K8s

#### 🔒 Security
- **Security Events**: Eventos de segurança
- **Access Logs**: Logs de acesso
- **Vulnerability Scanning**: Resultados de scans

#### 📈 Business Intelligence
- **KPIs**: Indicadores chave de performance
- **Revenue Metrics**: Métricas de receita
- **User Analytics**: Análise de usuários

#### 🔍 Observability
- **SLI/SLO**: Service Level Indicators/Objectives
- **Error Tracking**: Rastreamento de erros
- **Performance**: Métricas de performance

#### 🚨 SRE
- **Incident Response**: Dashboards para resposta a incidentes
- **Capacity Planning**: Planejamento de capacidade
- **Reliability**: Métricas de confiabilidade

#### 👨‍💻 Development
- **CI/CD Metrics**: Métricas de pipeline
- **Code Quality**: Qualidade de código
- **Deployment**: Métricas de deploy

#### ☁️ Cloud
- **AWS**: Métricas da AWS
- **Azure**: Métricas do Azure
- **GCP**: Métricas do Google Cloud

#### 🎨 Custom
- **Organization Specific**: Dashboards específicos da organização
- **Experimental**: Dashboards experimentais

## 🚀 Como Usar

### 1. Configuração Automática
O Grafana carregará automaticamente todas as configurações ao iniciar:

```yaml
# docker-compose.yml
volumes:
  - ./examples/grafana/provisioning:/etc/grafana/provisioning
```

### 2. Adicionando Novos Datasources
1. Edite os arquivos em `datasources/`
2. Reinicie o Grafana ou aguarde o reload automático

### 3. Adicionando Novos Dashboards
1. Coloque o arquivo JSON na pasta apropriada em `dashboards/`
2. O dashboard será carregado automaticamente
3. Use tags apropriadas para organização

### 4. Criando Novas Categorias
1. Crie um novo diretório em `dashboards/`
2. Adicione a configuração em `dashboards.yml`
3. Coloque os dashboards na nova pasta

## 📋 Padrões e Convenções

### Nomenclatura de Arquivos
- Use kebab-case: `node-exporter-overview.json`
- Seja descritivo: `docker-containers.json`
- Inclua a categoria: `snmp-switches.json`

### Tags de Dashboard
- Use tags consistentes: `infrastructure`, `docker`, `snmp`
- Inclua categoria principal
- Adicione tags específicas do contexto

### UIDs de Dashboard
- Use formato consistente: `node-exporter-overview`
- Evite conflitos de UID
- Mantenha relacionamento com filename

### Variáveis de Template
- Use nomes padronizados: `$instance`, `$job`, `$container`
- Implemente multi-select quando apropriado
- Configure refresh automático

## 🔧 Configurações Avançadas

### Update Strategies
- **file**: Atualiza do arquivo (recomendado para desenvolvimento)
- **snapshot**: Mantém versão atual (recomendado para produção)

### Folder Organization
- Pastas automáticas baseadas em diretórios
- Hierarquia clara e intuitiva
- Separação por domínio/equipe

### Performance
- Limite queries pesadas
- Use cache quando possível
- Otimize refresh intervals

### Security
- Configure datasource permissions
- Use service accounts
- Implemente RBAC quando necessário

## 🔍 Troubleshooting

### Dashboards não carregam
1. Verifique logs do Grafana
2. Valide JSON syntax
3. Confirme UIDs únicos
4. Verifique permissões de arquivo

### Datasources não conectam
1. Teste conectividade de rede
2. Valide credenciais
3. Confirme URLs corretas
4. Verifique configuração de proxy

### Performance Issues
1. Otimize queries Prometheus
2. Ajuste time ranges
3. Reduza refresh intervals
4. Use caching estratégico

## 📚 Referências

- [Grafana Provisioning Documentation](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Prometheus Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [SNMP Exporter Configuration](https://github.com/prometheus/snmp_exporter)

## 🤝 Contribuindo

1. Siga os padrões estabelecidos
2. Teste dashboards antes de commit
3. Documente mudanças significativas
4. Use pull requests para revisão
5. Mantenha compatibilidade com versões anteriores

---

**Nota**: Esta estrutura modular facilita a manutenção, escalabilidade e colaboração em ambientes de observabilidade complexos.
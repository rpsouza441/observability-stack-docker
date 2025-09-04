# Documentação: compose.yml

## Visão Geral

O arquivo `compose.yml` é o coração da stack de observabilidade, definindo todos os serviços necessários para um ambiente completo de monitoramento. Este arquivo orquestra Prometheus, Grafana, Alertmanager, Node Exporter, cAdvisor e SNMP Exporter em uma configuração otimizada para produção.

## Estrutura dos Serviços

### 1. Prometheus (Servidor de Métricas)

```yaml
prometheus:
  image: prom/prometheus:v2.45.0
  container_name: prometheus
  ports:
    - "${PROMETHEUS_PORT:-9090}:9090"
```

**Características:**
- **Imagem**: `prom/prometheus:v2.45.0` (versão estável)
- **Porta**: Configurável via `PROMETHEUS_PORT` (padrão: 9090)
- **Volumes**: Configuração e dados persistentes
- **Recursos**: Limitado a 1GB RAM, 1 CPU

**Configurações Importantes:**
- `--config.file=/etc/prometheus/prometheus.yml`: Arquivo de configuração principal
- `--storage.tsdb.path=/prometheus`: Diretório de dados
- `--storage.tsdb.retention.time=15d`: Retenção de 15 dias
- `--web.console.libraries=/etc/prometheus/console_libraries`
- `--web.console.templates=/etc/prometheus/consoles`
- `--web.enable-lifecycle`: Permite reload via API
- `--web.enable-admin-api`: Habilita API administrativa

### 2. Grafana (Visualização)

```yaml
grafana:
  image: grafana/grafana:10.0.3
  container_name: grafana
  ports:
    - "${GRAFANA_PORT:-3000}:3000"
```

**Características:**
- **Imagem**: `grafana/grafana:10.0.3` (versão LTS)
- **Porta**: Configurável via `GRAFANA_PORT` (padrão: 3000)
- **Volumes**: Dados, dashboards e provisionamento
- **Recursos**: Limitado a 512MB RAM, 0.5 CPU

**Variáveis de Ambiente:**
- `GF_SECURITY_ADMIN_PASSWORD`: Senha do admin (padrão: admin)
- `GF_USERS_ALLOW_SIGN_UP`: Desabilita registro público
- `GF_INSTALL_PLUGINS`: Plugins adicionais
- `GF_RENDERING_SERVER_URL`: URL do serviço de renderização

### 3. Alertmanager (Gerenciamento de Alertas)

```yaml
alertmanager:
  image: prom/alertmanager:v0.25.0
  container_name: alertmanager
  ports:
    - "${ALERTMANAGER_PORT:-9093}:9093"
```

**Características:**
- **Imagem**: `prom/alertmanager:v0.25.0`
- **Porta**: Configurável via `ALERTMANAGER_PORT` (padrão: 9093)
- **Volumes**: Configuração e dados de silenciamento
- **Recursos**: Limitado a 256MB RAM, 0.25 CPU

**Configurações:**
- `--config.file=/etc/alertmanager/alertmanager.yml`
- `--storage.path=/alertmanager`
- `--web.external-url=http://localhost:9093`

### 4. Node Exporter (Métricas do Sistema)

```yaml
node-exporter:
  image: prom/node-exporter:v1.6.1
  container_name: node-exporter
  ports:
    - "${NODE_EXPORTER_PORT:-9100}:9100"
```

**Características:**
- **Imagem**: `prom/node-exporter:v1.6.1`
- **Porta**: Configurável via `NODE_EXPORTER_PORT` (padrão: 9100)
- **Volumes**: Acesso ao sistema host (read-only)
- **Recursos**: Limitado a 128MB RAM, 0.1 CPU

**Coletores Habilitados:**
- `--collector.filesystem.mount-points-exclude`: Exclui pontos de montagem temporários
- `--collector.netdev.device-exclude`: Exclui interfaces virtuais
- `--collector.textfile.directory`: Diretório para métricas customizadas

### 5. cAdvisor (Métricas de Containers)

```yaml
cadvisor:
  image: gcr.io/cadvisor/cadvisor:v0.47.2
  container_name: cadvisor
  ports:
    - "${CADVISOR_PORT:-8080}:8080"
```

**Características:**
- **Imagem**: `gcr.io/cadvisor/cadvisor:v0.47.2`
- **Porta**: Configurável via `CADVISOR_PORT` (padrão: 8080)
- **Volumes**: Acesso ao Docker daemon e sistema
- **Recursos**: Limitado a 256MB RAM, 0.2 CPU

**Configurações:**
- `--housekeeping_interval=30s`: Intervalo de coleta
- `--docker_only=true`: Apenas containers Docker
- `--disable_metrics=percpu,sched,tcp,udp`: Desabilita métricas desnecessárias

### 6. SNMP Exporter (Métricas de Rede)

```yaml
snmp-exporter:
  image: prom/snmp-exporter:v0.21.0
  container_name: snmp-exporter
  ports:
    - "${SNMP_EXPORTER_PORT:-9116}:9116"
```

**Características:**
- **Imagem**: `prom/snmp-exporter:v0.21.0`
- **Porta**: Configurável via `SNMP_EXPORTER_PORT` (padrão: 9116)
- **Volumes**: Arquivo de configuração SNMP
- **Recursos**: Limitado a 128MB RAM, 0.1 CPU

## Rede e Conectividade

### Rede Personalizada

```yaml
networks:
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

**Benefícios:**
- Isolamento de rede para serviços de monitoramento
- Comunicação interna otimizada
- Controle de tráfego e segurança
- Resolução de nomes entre containers

## Volumes e Persistência

### Volumes Nomeados

```yaml
volumes:
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
  alertmanager_data:
    driver: local
```

**Características:**
- **Persistência**: Dados sobrevivem a reinicializações
- **Performance**: Volumes locais otimizados
- **Backup**: Facilita estratégias de backup
- **Migração**: Permite migração entre hosts

### Bind Mounts

- `./prometheus.yml`: Configuração do Prometheus
- `./alertmanager/`: Configurações do Alertmanager
- `./grafana/dashboards/`: Dashboards pré-configurados
- `./grafana/provisioning/`: Provisionamento automático
- `./snmp_exporter/`: Configuração SNMP

## Variáveis de Ambiente

### Portas dos Serviços

| Variável | Padrão | Descrição |
|----------|--------|----------|
| `PROMETHEUS_PORT` | 9090 | Porta do Prometheus |
| `GRAFANA_PORT` | 3000 | Porta do Grafana |
| `ALERTMANAGER_PORT` | 9093 | Porta do Alertmanager |
| `NODE_EXPORTER_PORT` | 9100 | Porta do Node Exporter |
| `CADVISOR_PORT` | 8080 | Porta do cAdvisor |
| `SNMP_EXPORTER_PORT` | 9116 | Porta do SNMP Exporter |

### Configurações do Grafana

| Variável | Padrão | Descrição |
|----------|--------|----------|
| `GF_SECURITY_ADMIN_PASSWORD` | admin | Senha do administrador |
| `GF_USERS_ALLOW_SIGN_UP` | false | Permite registro de usuários |
| `GF_INSTALL_PLUGINS` | - | Plugins adicionais |

## Recursos e Limites

### Configuração de Recursos

```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '1.0'
    reservations:
      memory: 512M
      cpus: '0.5'
```

**Distribuição de Recursos:**
- **Prometheus**: 1GB RAM, 1 CPU (maior consumo)
- **Grafana**: 512MB RAM, 0.5 CPU
- **Alertmanager**: 256MB RAM, 0.25 CPU
- **cAdvisor**: 256MB RAM, 0.2 CPU
- **Node Exporter**: 128MB RAM, 0.1 CPU
- **SNMP Exporter**: 128MB RAM, 0.1 CPU

## Políticas de Restart

```yaml
restart: unless-stopped
```

**Comportamento:**
- Reinicia automaticamente em caso de falha
- Não reinicia se parado manualmente
- Inicia automaticamente no boot do sistema
- Garante alta disponibilidade dos serviços

## Healthchecks

### Exemplo para Prometheus

```yaml
healthcheck:
  test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**Benefícios:**
- Detecção automática de falhas
- Restart inteligente de serviços
- Monitoramento de saúde dos containers
- Integração com orquestradores

## Segurança

### Considerações de Segurança

1. **Rede Isolada**: Serviços em rede dedicada
2. **Volumes Read-Only**: Configurações protegidas
3. **Usuários Não-Root**: Containers executam com usuários limitados
4. **Portas Controladas**: Exposição mínima necessária
5. **Secrets Management**: Uso de variáveis de ambiente

### Recomendações

- Configure firewall para limitar acesso às portas
- Use HTTPS com certificados válidos
- Implemente autenticação forte no Grafana
- Monitore logs de acesso regularmente
- Mantenha imagens atualizadas

## Troubleshooting

### Comandos Úteis

```bash
# Verificar status dos serviços
docker-compose ps

# Ver logs de um serviço específico
docker-compose logs prometheus

# Reiniciar um serviço
docker-compose restart grafana

# Verificar uso de recursos
docker stats

# Testar conectividade entre serviços
docker-compose exec prometheus wget -qO- http://grafana:3000/api/health
```

### Problemas Comuns

1. **Porta em Uso**: Verificar se portas estão disponíveis
2. **Permissões**: Verificar permissões de volumes
3. **Memória Insuficiente**: Ajustar limites de recursos
4. **Rede**: Verificar conectividade entre containers
5. **Configuração**: Validar arquivos de configuração

## Manutenção

### Atualizações

1. **Backup**: Sempre fazer backup antes de atualizar
2. **Teste**: Testar em ambiente de desenvolvimento
3. **Versionamento**: Usar tags específicas, não `latest`
4. **Rollback**: Manter versão anterior disponível
5. **Monitoramento**: Verificar métricas após atualização

### Backup

```bash
# Backup de volumes
docker run --rm -v prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus_data.tar.gz -C /data .

# Backup de configurações
tar czf config_backup.tar.gz prometheus.yml alertmanager/ grafana/ snmp_exporter/
```

## Performance

### Otimizações

1. **Recursos**: Ajustar limites conforme uso real
2. **Retenção**: Configurar retenção adequada no Prometheus
3. **Scrape Interval**: Balancear frequência vs. recursos
4. **Métricas**: Desabilitar coletores desnecessários
5. **Storage**: Usar SSD para volumes de dados

### Monitoramento

- Monitore uso de CPU e memória dos containers
- Verifique latência de queries no Prometheus
- Acompanhe crescimento dos volumes de dados
- Monitore conectividade de rede entre serviços
- Configure alertas para falhas de serviços

## Integração

### Serviços Externos

- **Reverse Proxy**: Nginx, Traefik, HAProxy
- **Service Discovery**: Consul, etcd
- **Log Aggregation**: ELK Stack, Loki
- **Tracing**: Jaeger, Zipkin
- **Notification**: Slack, PagerDuty, Email

### APIs

- **Prometheus**: `http://localhost:9090/api/v1/`
- **Grafana**: `http://localhost:3000/api/`
- **Alertmanager**: `http://localhost:9093/api/v1/`

Este arquivo é fundamental para o funcionamento da stack e deve ser mantido sob controle de versão com cuidado especial para mudanças que afetem a produção.
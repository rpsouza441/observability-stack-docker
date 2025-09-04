# Stack de Observabilidade com Docker

Stack completo de monitoramento e observabilidade usando Prometheus, Grafana, Alertmanager e exporters diversos, incluindo coleta SNMP para dispositivos de rede.

## 🚀 Componentes

- **Prometheus**: Servidor principal de métricas e alertas
- **Grafana**: Dashboards e visualização de dados
- **Alertmanager**: Gerenciamento e roteamento de alertas
- **Node Exporter**: Métricas do sistema operacional
- **cAdvisor**: Métricas de containers Docker
- **SNMP Exporter**: Coleta de métricas via SNMP (switches, APs, pfSense)
- **Windows Exporter**: Métricas específicas do Windows (opcional)

## 📋 Pré-requisitos

- Docker e Docker Compose instalados (ambiente Linux)
- Acesso SNMP configurado nos dispositivos de rede
- Portas disponíveis: 3000 (Grafana), 9090 (Prometheus), 9093 (Alertmanager), 9100 (Node Exporter), 8080 (cAdvisor), 9116 (SNMP Exporter)
- Arquivo `.env` configurado (copie do `.env.example`)

## 🛠️ Configuração Inicial

### 1. Configuração de Variáveis de Ambiente

```bash
# Copie o arquivo de exemplo
cp .env.example .env

# Edite as variáveis conforme seu ambiente
nano .env
```

**Variáveis importantes para configurar:**
- `GRAFANA_ADMIN_PASSWORD`: Senha do admin do Grafana
- `SMTP_*`: Configurações de email para alertas
- `ALERT_EMAIL_*`: Destinatários dos alertas
- `SNMP_*_IPS`: IPs dos dispositivos SNMP
- `TZ`: Timezone (ex: America/Sao_Paulo)

### 2. Configurar Targets SNMP

Edite o arquivo `prometheus.yml` e adicione os IPs dos seus dispositivos:

```yaml
# Switches
- job_name: 'snmp-switches'
  static_configs:
    - targets: ['192.168.1.10', '192.168.1.11']  # IPs dos switches

# APs Unifi
- job_name: 'snmp-unifi-aps'
  static_configs:
    - targets: ['192.168.1.20', '192.168.1.21']  # IPs dos APs

# pfSense
- job_name: 'snmp-pfsense'
  static_configs:
    - targets: ['192.168.1.1']  # IP do pfSense
```

### 3. Configurar Windows Exporter (quando necessário)

Para monitorar servidores Windows:
1. Instale o Windows Exporter nos servidores Windows
2. Configure os IPs na variável `WINDOWS_SERVERS_IPS` no arquivo `.env`
3. Ajuste o `prometheus.yml` para incluir os targets

### 4. Configurar Alertmanager

As configurações do Alertmanager usam variáveis de ambiente do arquivo `.env`:
- Configure as variáveis `SMTP_*` para notificações por email
- Configure `SLACK_*` para notificações no Slack (opcional)
- Defina os destinatários nas variáveis `ALERT_EMAIL_*`

### 4. Configurar SNMP nos Dispositivos

#### pfSense
1. Acesse **Services > SNMP**
2. Habilite SNMP
3. Configure community: `public` (ou altere no `snmp.yml`)
4. Adicione ACL para o IP do servidor Docker

#### Switches/APs Unifi
1. Configure SNMP community `public`
2. Habilite SNMP v2c
3. Permita acesso do IP do servidor Docker

## 🚀 Inicialização

```bash
# Certifique-se de que o arquivo .env está configurado
ls -la .env

# Iniciar todos os serviços
docker-compose up -d

# Verificar status
docker-compose ps

# Ver logs
docker-compose logs -f prometheus
docker-compose logs -f grafana

# Parar os serviços
docker-compose down

# Parar e remover volumes (CUIDADO: remove dados)
docker-compose down -v
```

## 🌐 Acesso aos Serviços

- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093
- **Node Exporter**: http://localhost:9100/metrics
- **cAdvisor**: http://localhost:8080
- **SNMP Exporter**: http://localhost:9116

## 📊 Dashboards Recomendados

Importe estes dashboards no Grafana:

- **Node Exporter Full**: ID 1860
- **Docker Container & Host Metrics**: ID 179
- **SNMP Interface Throughput**: ID 1124
- **pfSense**: ID 12023
- **UniFi Poller**: ID 11315

## 🚨 Alertas Configurados

### Infraestrutura
- Instância/serviço indisponível
- Alta utilização de CPU/memória/disco
- Load average alto
- Containers down

### Rede (SNMP)
- Dispositivos SNMP indisponíveis
- Interfaces down
- Alto tráfego de rede
- Muitos erros/descartes
- pfSense: Alto CPU, pouca memória, muitas conexões TCP
- UniFi: Muitos clientes conectados

## 🔧 Personalização

### Adicionar Novos Targets

1. Edite `prometheus.yml`
2. Adicione o novo job
3. Reinicie: `docker-compose restart prometheus`

### Modificar Alertas

1. Edite arquivos em `rules/`
2. Recarregue: `curl -X POST http://localhost:9090/-/reload`

### Configurar SNMP Personalizado

1. Edite `snmp_exporter/snmp.yml`
2. Adicione novos módulos conforme necessário
3. Reinicie: `docker-compose restart snmp_exporter`

## 📁 Estrutura de Arquivos

```
.
├── .env                        # Variáveis de ambiente (CRIAR a partir do .env.example)
├── .env.example               # Exemplo de configuração de variáveis
├── .gitignore                 # Arquivos ignorados pelo Git
├── compose.yml                # Docker Compose principal
├── prometheus.yml             # Configuração do Prometheus
├── README.md                  # Este arquivo
├── alertmanager/
│   └── alertmanager.yml      # Configuração do Alertmanager
├── rules/
│   ├── infrastructure_alerts.yml  # Alertas de infraestrutura
│   └── network_alerts.yml         # Alertas de rede
├── snmp_exporter/
│   └── snmp.yml              # Configuração SNMP
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/      # Datasources automáticos
│   │   └── dashboards/       # Provisionamento de dashboards
│   └── dashboards/           # Dashboards personalizados
├── prometheus_data/          # Dados do Prometheus (criado automaticamente)
├── grafana_data/            # Dados do Grafana (criado automaticamente)
└── alertmanager_data/       # Dados do Alertmanager (criado automaticamente)
```

## 🔍 Troubleshooting

### SNMP não funciona
1. Teste conectividade: `snmpwalk -v2c -c public <IP> 1.3.6.1.2.1.1.1.0`
2. Verifique firewall nos dispositivos
3. Confirme community string
4. Verifique logs: `docker-compose logs snmp_exporter`

### Alertas não chegam
1. Verifique configuração SMTP no Alertmanager
2. Teste conectividade de email
3. Verifique logs: `docker-compose logs alertmanager`

### Métricas não aparecem
1. Verifique targets no Prometheus: http://localhost:9090/targets
2. Confirme conectividade de rede
3. Verifique logs dos exporters

## 📈 Próximos Passos

1. **Configurar Variáveis de Ambiente**: Copie `.env.example` para `.env` e configure todas as variáveis
2. **Configurar dashboards personalizados** para seus dispositivos específicos
3. **Implementar alertas customizados** baseados nas suas necessidades
4. **Configurar backup** dos dados do Grafana e Prometheus
5. **Implementar autenticação** mais robusta (LDAP, OAuth)
6. **Adicionar mais exporters** conforme necessário (MySQL, PostgreSQL, etc.)
7. **Configurar retenção de dados** adequada para seu ambiente
8. **Versionamento**: Usar Git para versionar configurações (o .gitignore já está configurado)

## 🤝 Contribuição

Sinta-se à vontade para contribuir com melhorias, novos dashboards ou configurações adicionais!
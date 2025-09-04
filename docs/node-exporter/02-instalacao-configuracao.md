# Módulo 02: Instalação e Configuração

> **Deploy profissional** - Domine todas as formas de instalar e configurar o Node Exporter

## 📋 Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- ✅ **Instalar** Node Exporter via binário, Docker e package managers
- ✅ **Configurar** como serviço systemd para produção
- ✅ **Implementar** deployment em Kubernetes com DaemonSet
- ✅ **Aplicar** configurações de segurança e otimização
- ✅ **Gerenciar** collectors e configurações avançadas

## 🚀 Métodos de Instalação

### 📦 1. Instalação via Binário

#### Download e Instalação Manual

```bash
#!/bin/bash
# install-node-exporter-binary.sh

# Definir versão e arquitetura
VERSION="1.7.0"
ARCH="linux-amd64"
USER="node_exporter"
GROUP="node_exporter"

# Criar usuário do sistema
sudo useradd --no-create-home --shell /bin/false $USER

# Download do binário
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.${ARCH}.tar.gz

# Extrair e instalar
tar xvf node_exporter-${VERSION}.${ARCH}.tar.gz
sudo cp node_exporter-${VERSION}.${ARCH}/node_exporter /usr/local/bin/
sudo chown $USER:$GROUP /usr/local/bin/node_exporter
sudo chmod +x /usr/local/bin/node_exporter

# Criar diretórios necessários
sudo mkdir -p /etc/node_exporter
sudo mkdir -p /var/lib/node_exporter/textfile_collector
sudo chown -R $USER:$GROUP /var/lib/node_exporter

# Verificar instalação
/usr/local/bin/node_exporter --version

# Limpeza
rm -rf /tmp/node_exporter-${VERSION}.${ARCH}*

echo "Node Exporter instalado com sucesso!"
echo "Binário: /usr/local/bin/node_exporter"
echo "Usuário: $USER"
echo "Configuração: /etc/node_exporter"
echo "TextFile Collector: /var/lib/node_exporter/textfile_collector"
```

#### Verificação da Instalação

```bash
# Verificar versão
node_exporter --version

# Testar execução
node_exporter --help | head -20

# Verificar collectors disponíveis
node_exporter --help | grep -A 50 "Enabled by default"
```

### 🐳 2. Instalação via Docker

#### Docker Run Básico

```bash
# Execução simples para teste
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  -p 9100:9100 \
  prom/node-exporter:latest

# Verificar logs
docker logs node-exporter

# Testar endpoint
curl http://localhost:9100/metrics | head -10
```

#### Docker Run Completo (Produção)

```bash
#!/bin/bash
# run-node-exporter-docker.sh

# Parar container existente se houver
docker stop node-exporter 2>/dev/null || true
docker rm node-exporter 2>/dev/null || true

# Executar com configuração completa
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  --pid="host" \
  --net="host" \
  -p 9100:9100 \
  -v "/proc:/host/proc:ro" \
  -v "/sys:/host/sys:ro" \
  -v "/:/rootfs:ro" \
  -v "/var/lib/node_exporter/textfile_collector:/var/lib/node_exporter/textfile_collector:ro" \
  --security-opt no-new-privileges:true \
  --read-only \
  --tmpfs /tmp \
  prom/node-exporter:latest \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --path.rootfs=/rootfs \
  --collector.filesystem.mount-points-exclude='^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($$|/)' \
  --collector.systemd \
  --collector.processes \
  --collector.textfile.directory=/var/lib/node_exporter/textfile_collector \
  --web.listen-address=0.0.0.0:9100 \
  --web.telemetry-path=/metrics \
  --log.level=info

echo "Node Exporter iniciado com sucesso!"
echo "URL: http://localhost:9100"
echo "Métricas: http://localhost:9100/metrics"
echo "Logs: docker logs -f node-exporter"
```

#### Docker Compose

```yaml
# docker-compose.node-exporter.yml
version: '3.8'

services:
  node-exporter:
    image: prom/node-exporter:v1.7.0
    container_name: node-exporter
    restart: unless-stopped
    pid: host
    network_mode: host
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
      - ./textfile_collector:/var/lib/node_exporter/textfile_collector:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($$|/)'
      - '--collector.systemd'
      - '--collector.processes'
      - '--collector.textfile.directory=/var/lib/node_exporter/textfile_collector'
      - '--web.listen-address=0.0.0.0:9100'
      - '--web.telemetry-path=/metrics'
      - '--log.level=info'
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
    labels:
      - "prometheus.io/scrape=true"
      - "prometheus.io/port=9100"
      - "prometheus.io/path=/metrics"

  # Stack completo com Prometheus
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
    depends_on:
      - node-exporter

  grafana:
    image: grafana/grafana:10.2.0
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    depends_on:
      - prometheus

volumes:
  prometheus_data:
  grafana_data:

networks:
  default:
    name: monitoring
```

### 📋 3. Instalação via Package Manager

#### Ubuntu/Debian (APT)

```bash
#!/bin/bash
# install-node-exporter-apt.sh

# Atualizar repositórios
sudo apt update

# Instalar Node Exporter
sudo apt install -y prometheus-node-exporter

# Verificar status
sudo systemctl status prometheus-node-exporter

# Habilitar auto-start
sudo systemctl enable prometheus-node-exporter

# Verificar instalação
curl -s http://localhost:9100/metrics | head -5

echo "Node Exporter instalado via APT!"
echo "Serviço: prometheus-node-exporter"
echo "Configuração: /etc/default/prometheus-node-exporter"
echo "URL: http://localhost:9100"
```

#### CentOS/RHEL (YUM/DNF)

```bash
#!/bin/bash
# install-node-exporter-yum.sh

# Para CentOS 7
if [ -f /etc/centos-release ]; then
    sudo yum install -y epel-release
    sudo yum install -y golang-github-prometheus-node-exporter
fi

# Para CentOS 8+ / RHEL 8+
if command -v dnf &> /dev/null; then
    sudo dnf install -y epel-release
    sudo dnf install -y golang-github-prometheus-node-exporter
fi

# Iniciar serviço
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Verificar status
sudo systemctl status node_exporter

echo "Node Exporter instalado via YUM/DNF!"
```

## ⚙️ Configuração como Serviço Systemd

### Arquivo de Serviço

```ini
# /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecReload=/bin/kill -HUP $$MAINPID
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.processes \
    --collector.textfile.directory=/var/lib/node_exporter/textfile_collector \
    --web.listen-address=0.0.0.0:9100 \
    --web.telemetry-path=/metrics \
    --log.level=info \
    --log.format=logfmt

SyslogIdentifier=node_exporter
Restart=always
RestartSec=1
StartLimitInterval=0

ProtectHome=yes
NoNewPrivileges=yes

ProtectSystem=strict
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=yes

[Install]
WantedBy=multi-user.target
```

### Script de Configuração Systemd

```bash
#!/bin/bash
# setup-node-exporter-systemd.sh

SERVICE_FILE="/etc/systemd/system/node_exporter.service"
CONFIG_FILE="/etc/default/node_exporter"
USER="node_exporter"
GROUP="node_exporter"

# Verificar se já está instalado
if ! command -v node_exporter &> /dev/null; then
    echo "Erro: Node Exporter não encontrado. Execute primeiro a instalação do binário."
    exit 1
fi

# Criar arquivo de configuração
sudo tee $CONFIG_FILE > /dev/null << 'EOF'
# Node Exporter configuration file
# Command line options for node_exporter

# Basic options
OPTIONS="--collector.systemd --collector.processes"

# Web interface
WEB_LISTEN_ADDRESS="0.0.0.0:9100"
WEB_TELEMETRY_PATH="/metrics"

# Logging
LOG_LEVEL="info"
LOG_FORMAT="logfmt"

# TextFile Collector
TEXTFILE_DIRECTORY="/var/lib/node_exporter/textfile_collector"

# Filesystem collector exclusions
FILESYSTEM_IGNORED_MOUNT_POINTS="^/(dev|proc|sys|var/lib/docker/.+)($|/)"
FILESYSTEM_IGNORED_FS_TYPES="^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
EOF

# Criar arquivo de serviço systemd
sudo tee $SERVICE_FILE > /dev/null << EOF
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$USER
Group=$GROUP
EnvironmentFile=-$CONFIG_FILE
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/node_exporter \\
    --collector.systemd \\
    --collector.processes \\
    --collector.textfile.directory=\${TEXTFILE_DIRECTORY} \\
    --web.listen-address=\${WEB_LISTEN_ADDRESS} \\
    --web.telemetry-path=\${WEB_TELEMETRY_PATH} \\
    --log.level=\${LOG_LEVEL} \\
    --log.format=\${LOG_FORMAT} \\
    --collector.filesystem.mount-points-exclude=\${FILESYSTEM_IGNORED_MOUNT_POINTS} \\
    --collector.filesystem.fs-types-exclude=\${FILESYSTEM_IGNORED_FS_TYPES}

SyslogIdentifier=node_exporter
Restart=always
RestartSec=1
StartLimitInterval=0

# Security settings
ProtectHome=yes
NoNewPrivileges=yes
ProtectSystem=strict
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=yes

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd e iniciar serviço
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verificar status
echo "Aguardando inicialização..."
sleep 3

if sudo systemctl is-active --quiet node_exporter; then
    echo "✅ Node Exporter configurado com sucesso!"
    echo "Status: $(sudo systemctl is-active node_exporter)"
    echo "URL: http://localhost:9100"
    echo "Logs: sudo journalctl -u node_exporter -f"
    
    # Testar endpoint
    if curl -s http://localhost:9100/metrics > /dev/null; then
        echo "✅ Endpoint /metrics respondendo corretamente"
    else
        echo "❌ Erro: Endpoint /metrics não está respondendo"
    fi
else
    echo "❌ Erro: Falha ao iniciar Node Exporter"
    echo "Logs de erro:"
    sudo journalctl -u node_exporter --no-pager -l
fi
```

### Comandos de Gerenciamento

```bash
# Iniciar serviço
sudo systemctl start node_exporter

# Parar serviço
sudo systemctl stop node_exporter

# Reiniciar serviço
sudo systemctl restart node_exporter

# Habilitar auto-start
sudo systemctl enable node_exporter

# Desabilitar auto-start
sudo systemctl disable node_exporter

# Verificar status
sudo systemctl status node_exporter

# Ver logs
sudo journalctl -u node_exporter -f

# Ver logs das últimas 24h
sudo journalctl -u node_exporter --since "24 hours ago"

# Recarregar configuração
sudo systemctl reload node_exporter

# Verificar se está habilitado
sudo systemctl is-enabled node_exporter

# Verificar se está ativo
sudo systemctl is-active node_exporter
```

## ☸️ Deployment em Kubernetes

### DaemonSet Básico

```yaml
# node-exporter-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    app: node-exporter
    version: v1.7.0
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9100"
        prometheus.io/path: "/metrics"
    spec:
      hostNetwork: true
      hostPID: true
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.7.0
        args:
        - '--path.procfs=/host/proc'
        - '--path.sysfs=/host/sys'
        - '--path.rootfs=/host/root'
        - '--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)'
        - '--collector.filesystem.fs-types-exclude=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$'
        - '--collector.systemd'
        - '--collector.processes'
        - '--web.listen-address=0.0.0.0:9100'
        ports:
        - containerPort: 9100
          hostPort: 9100
          name: metrics
        resources:
          limits:
            cpu: 200m
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        - name: root
          mountPath: /host/root
          mountPropagation: HostToContainer
          readOnly: true
        securityContext:
          runAsNonRoot: true
          runAsUser: 65534
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      - name: root
        hostPath:
          path: /
      serviceAccountName: node-exporter
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: node-exporter
  namespace: monitoring
---
apiVersion: v1
kind: Service
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    app: node-exporter
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9100"
spec:
  type: ClusterIP
  clusterIP: None
  ports:
  - name: metrics
    port: 9100
    targetPort: 9100
    protocol: TCP
  selector:
    app: node-exporter
```

### Configuração com Helm

```yaml
# values.yaml para Helm Chart
image:
  repository: prom/node-exporter
  tag: v1.7.0
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 9100
  targetPort: 9100
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9100"

resources:
  limits:
    cpu: 200m
    memory: 200Mi
  requests:
    cpu: 100m
    memory: 100Mi

nodeSelector: {}

tolerations:
  - key: node-role.kubernetes.io/master
    operator: Exists
    effect: NoSchedule
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule

affinity: {}

securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false

extraArgs:
  - --collector.systemd
  - --collector.processes
  - --collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)

prometheus:
  monitor:
    enabled: true
    namespace: monitoring
    interval: 30s
    scrapeTimeout: 10s
```

```bash
# Instalar via Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Node Exporter
helm install node-exporter prometheus-community/prometheus-node-exporter \
  --namespace monitoring \
  --create-namespace \
  --values values.yaml

# Verificar deployment
kubectl get daemonset -n monitoring
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-node-exporter

# Testar métricas
kubectl port-forward -n monitoring daemonset/node-exporter 9100:9100
curl http://localhost:9100/metrics | head -10
```

## 🔧 Configurações Avançadas

### Gerenciamento de Collectors

```bash
#!/bin/bash
# configure-collectors.sh

# Listar todos os collectors disponíveis
node_exporter --help 2>&1 | grep -E "collector\.(enable|disable)"

# Configuração para ambiente de desenvolvimento
DEV_COLLECTORS="
--collector.systemd \
--collector.processes \
--collector.interrupts \
--collector.tcpstat \
--collector.meminfo_numa \
--no-collector.arp \
--no-collector.bcache \
--no-collector.bonding \
--no-collector.btrfs \
--no-collector.conntrack \
--no-collector.cpufreq \
--no-collector.edac \
--no-collector.entropy \
--no-collector.fibrechannel \
--no-collector.hwmon \
--no-collector.infiniband \
--no-collector.ipvs \
--no-collector.mdadm \
--no-collector.nfs \
--no-collector.nfsd \
--no-collector.nvme \
--no-collector.powersupplyclass \
--no-collector.pressure \
--no-collector.rapl \
--no-collector.schedstat \
--no-collector.selinux \
--no-collector.sockstat \
--no-collector.softnet \
--no-collector.thermal_zone \
--no-collector.timex \
--no-collector.udp_queues \
--no-collector.xfs \
--no-collector.zfs"

# Configuração para ambiente de produção
PROD_COLLECTORS="
--collector.systemd \
--collector.processes \
--collector.interrupts \
--collector.tcpstat \
--collector.meminfo_numa \
--collector.hwmon \
--collector.pressure \
--collector.schedstat \
--collector.sockstat \
--collector.softnet \
--no-collector.arp \
--no-collector.bcache \
--no-collector.bonding \
--no-collector.btrfs \
--no-collector.conntrack \
--no-collector.cpufreq \
--no-collector.edac \
--no-collector.entropy \
--no-collector.fibrechannel \
--no-collector.infiniband \
--no-collector.ipvs \
--no-collector.mdadm \
--no-collector.nfs \
--no-collector.nfsd \
--no-collector.nvme \
--no-collector.powersupplyclass \
--no-collector.rapl \
--no-collector.selinux \
--no-collector.thermal_zone \
--no-collector.timex \
--no-collector.udp_queues \
--no-collector.xfs \
--no-collector.zfs"

# Configuração para monitoramento mínimo (baixo overhead)
MINIMAL_COLLECTORS="
--no-collector.arp \
--no-collector.bcache \
--no-collector.bonding \
--no-collector.btrfs \
--no-collector.conntrack \
--no-collector.cpufreq \
--no-collector.edac \
--no-collector.entropy \
--no-collector.fibrechannel \
--no-collector.hwmon \
--no-collector.infiniband \
--no-collector.interrupts \
--no-collector.ipvs \
--no-collector.mdadm \
--no-collector.meminfo_numa \
--no-collector.nfs \
--no-collector.nfsd \
--no-collector.nvme \
--no-collector.powersupplyclass \
--no-collector.pressure \
--no-collector.processes \
--no-collector.rapl \
--no-collector.schedstat \
--no-collector.selinux \
--no-collector.sockstat \
--no-collector.softnet \
--no-collector.systemd \
--no-collector.tcpstat \
--no-collector.thermal_zone \
--no-collector.timex \
--no-collector.udp_queues \
--no-collector.xfs \
--no-collector.zfs"

echo "Configurações de collectors disponíveis:"
echo "1. Desenvolvimento: $DEV_COLLECTORS"
echo "2. Produção: $PROD_COLLECTORS"
echo "3. Mínimo: $MINIMAL_COLLECTORS"
```

### TextFile Collector

```bash
#!/bin/bash
# setup-textfile-collector.sh

TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"

# Criar diretório se não existir
sudo mkdir -p $TEXTFILE_DIR
sudo chown node_exporter:node_exporter $TEXTFILE_DIR

# Script para métricas customizadas
cat > custom_metrics.sh << 'EOF'
#!/bin/bash
# Script para gerar métricas customizadas

TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
METRICS_FILE="$TEXTFILE_DIR/custom_metrics.prom"
TEMP_FILE="$TEXTFILE_DIR/custom_metrics.prom.$$"

# Função para adicionar métrica
add_metric() {
    local name="$1"
    local value="$2"
    local help="$3"
    local type="$4"
    
    echo "# HELP $name $help" >> "$TEMP_FILE"
    echo "# TYPE $name $type" >> "$TEMP_FILE"
    echo "$name $value" >> "$TEMP_FILE"
}

# Limpar arquivo temporário
> "$TEMP_FILE"

# Métrica de exemplo: número de usuários logados
USERS_LOGGED=$(who | wc -l)
add_metric "custom_users_logged_in" "$USERS_LOGGED" "Number of users currently logged in" "gauge"

# Métrica de exemplo: espaço em /tmp
TMP_USAGE=$(df /tmp | awk 'NR==2 {print $5}' | sed 's/%//')
add_metric "custom_tmp_usage_percent" "$TMP_USAGE" "Percentage of /tmp filesystem used" "gauge"

# Métrica de exemplo: processos zombie
ZOMBIE_PROCS=$(ps aux | awk '$8 ~ /^Z/ { count++ } END { print count+0 }')
add_metric "custom_zombie_processes" "$ZOMBIE_PROCS" "Number of zombie processes" "gauge"

# Métrica de exemplo: temperatura da CPU (se disponível)
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    CPU_TEMP_CELSIUS=$((CPU_TEMP / 1000))
    add_metric "custom_cpu_temperature_celsius" "$CPU_TEMP_CELSIUS" "CPU temperature in Celsius" "gauge"
fi

# Métrica de exemplo: uptime de serviços críticos
for service in sshd nginx mysql postgresql; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        UPTIME=$(systemctl show $service --property=ActiveEnterTimestamp --value)
        if [ -n "$UPTIME" ] && [ "$UPTIME" != "" ]; then
            UPTIME_EPOCH=$(date -d "$UPTIME" +%s 2>/dev/null || echo 0)
            CURRENT_EPOCH=$(date +%s)
            UPTIME_SECONDS=$((CURRENT_EPOCH - UPTIME_EPOCH))
            add_metric "custom_service_uptime_seconds{service=\"$service\"}" "$UPTIME_SECONDS" "Service uptime in seconds" "gauge"
        fi
    else
        add_metric "custom_service_uptime_seconds{service=\"$service\"}" "0" "Service uptime in seconds" "gauge"
    fi
done

# Mover arquivo temporário para final
mv "$TEMP_FILE" "$METRICS_FILE"
EOF

chmod +x custom_metrics.sh

# Criar cron job para executar a cada minuto
echo "* * * * * /path/to/custom_metrics.sh" | sudo crontab -u node_exporter -

# Executar uma vez para testar
./custom_metrics.sh

echo "TextFile Collector configurado!"
echo "Diretório: $TEXTFILE_DIR"
echo "Script: custom_metrics.sh"
echo "Arquivo de métricas: $TEXTFILE_DIR/custom_metrics.prom"
echo "Cron job configurado para executar a cada minuto"
```

### Configuração de Segurança

```yaml
# web-config.yml - Configuração de segurança
tls_server_config:
  cert_file: /etc/ssl/certs/node_exporter.crt
  key_file: /etc/ssl/private/node_exporter.key
  client_auth_type: RequireAndVerifyClientCert
  client_ca_file: /etc/ssl/certs/ca.crt
  min_version: TLS12
  max_version: TLS13
  cipher_suites:
    - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
    - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256

basic_auth_users:
  prometheus: $2b$12$hNf2lSsxfm0.i4a.1kVpSOVyBCfIB51VRjgBUyv6kdnyTlgWj81Ay
  grafana: $2b$12$M2Ql8UuHGF7CGQP8Ey8zKOQQ5cF5vF5F5F5F5F5F5F5F5F5F5F5F5F

http_server_config:
  http2: true
  headers:
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    X-XSS-Protection: 1; mode=block
    Strict-Transport-Security: max-age=31536000; includeSubDomains
```

```bash
#!/bin/bash
# setup-security.sh

# Gerar certificados SSL
sudo mkdir -p /etc/ssl/node_exporter
cd /etc/ssl/node_exporter

# Gerar CA privada
sudo openssl genrsa -out ca.key 4096

# Gerar certificado CA
sudo openssl req -new -x509 -key ca.key -sha256 -subj "/C=BR/ST=SP/O=MyOrg/CN=NodeExporter-CA" -days 3650 -out ca.crt

# Gerar chave privada do servidor
sudo openssl genrsa -out server.key 4096

# Gerar CSR do servidor
sudo openssl req -new -key server.key -out server.csr -subj "/C=BR/ST=SP/O=MyOrg/CN=node-exporter"

# Gerar certificado do servidor
sudo openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -sha256

# Configurar permissões
sudo chown -R node_exporter:node_exporter /etc/ssl/node_exporter
sudo chmod 600 /etc/ssl/node_exporter/*.key
sudo chmod 644 /etc/ssl/node_exporter/*.crt

# Gerar hash de senha para basic auth
echo "Gerando hash de senha..."
echo -n "Digite a senha para o usuário prometheus: "
read -s PASSWORD
echo
HASH=$(echo -n "$PASSWORD" | htpasswd -bnBC 12 "" "" | tr -d ':\n' | sed 's/^[^$]*$//')
echo "Hash gerado: $HASH"

echo "Configuração de segurança concluída!"
echo "Certificados em: /etc/ssl/node_exporter/"
echo "Use o hash gerado no arquivo web-config.yml"
```

## 🎯 Exercício Prático

### Objetivo
Implementar diferentes métodos de instalação e configuração do Node Exporter.

### Cenários do Exercício

#### Cenário 1: Instalação via Binário + Systemd

```bash
#!/bin/bash
# exercicio-cenario1.sh

echo "=== Cenário 1: Instalação via Binário + Systemd ==="

# 1. Download e instalação
VERSION="1.7.0"
ARCH="linux-amd64"

# Simular download (usar container para teste)
docker run --rm -v /tmp:/tmp alpine:latest sh -c "
    apk add --no-cache wget tar && \
    cd /tmp && \
    wget -q https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.${ARCH}.tar.gz && \
    tar xzf node_exporter-${VERSION}.${ARCH}.tar.gz
"

# 2. Verificar download
if [ -f "/tmp/node_exporter-${VERSION}.${ARCH}/node_exporter" ]; then
    echo "✅ Download realizado com sucesso"
    /tmp/node_exporter-${VERSION}.${ARCH}/node_exporter --version
else
    echo "❌ Erro no download"
    exit 1
fi

# 3. Testar execução
echo "Testando execução..."
/tmp/node_exporter-${VERSION}.${ARCH}/node_exporter --help | head -10

# 4. Simular configuração systemd (mostrar conteúdo)
echo "Conteúdo do arquivo systemd que seria criado:"
cat << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Cenário 1 concluído"
```

#### Cenário 2: Docker Compose Stack

```bash
#!/bin/bash
# exercicio-cenario2.sh

echo "=== Cenário 2: Docker Compose Stack ==="

# 1. Criar estrutura de diretórios
mkdir -p node-exporter-stack/{prometheus,grafana/provisioning/{datasources,dashboards}}
cd node-exporter-stack

# 2. Criar docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  node-exporter:
    image: prom/node-exporter:v1.7.0
    container_name: node-exporter
    restart: unless-stopped
    pid: host
    network_mode: host
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($$|/)'
      - '--web.listen-address=0.0.0.0:9100'

  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'

  grafana:
    image: grafana/grafana:10.2.0
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123

volumes:
  prometheus_data:
  grafana_data:
EOF

# 3. Criar configuração do Prometheus
cat > prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
    scrape_interval: 5s
    metrics_path: /metrics
EOF

# 4. Criar datasource do Grafana
cat > grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

# 5. Iniciar stack
echo "Iniciando stack..."
docker-compose up -d

# 6. Aguardar inicialização
echo "Aguardando inicialização dos serviços..."
sleep 15

# 7. Verificar serviços
echo "Verificando serviços:"
docker-compose ps

# 8. Testar endpoints
echo "Testando endpoints:"
echo "Node Exporter: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:9100/metrics)"
echo "Prometheus: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:9090)"
echo "Grafana: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000)"

echo "✅ Stack iniciado com sucesso!"
echo "URLs:"
echo "  Node Exporter: http://localhost:9100"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana: http://localhost:3000 (admin/admin123)"

echo "Para parar: docker-compose down"
echo "Para ver logs: docker-compose logs -f"
```

#### Cenário 3: Kubernetes com Helm

```bash
#!/bin/bash
# exercicio-cenario3.sh

echo "=== Cenário 3: Kubernetes com Helm ==="

# Verificar se kubectl está disponível
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado. Simulando deployment..."
    
    # Mostrar manifesto que seria aplicado
    echo "Manifesto que seria aplicado:"
    cat << 'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.7.0
        args:
        - '--path.procfs=/host/proc'
        - '--path.sysfs=/host/sys'
        - '--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+)($|/)'
        ports:
        - containerPort: 9100
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
EOF
    
    echo "✅ Manifesto gerado (simulação)"
    return
fi

# Verificar se cluster está disponível
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cluster Kubernetes não disponível"
    return
fi

# Criar namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Verificar se Helm está disponível
if command -v helm &> /dev/null; then
    echo "Instalando via Helm..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    helm install node-exporter prometheus-community/prometheus-node-exporter \
        --namespace monitoring \
        --set hostNetwork=true \
        --set hostPID=true
    
    echo "Aguardando deployment..."
    kubectl rollout status daemonset/node-exporter -n monitoring
else
    echo "Helm não disponível, aplicando manifesto diretamente..."
    # Aplicar manifesto diretamente
    kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.7.0
        args:
        - '--path.procfs=/host/proc'
        - '--path.sysfs=/host/sys'
        ports:
        - containerPort: 9100
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
EOF
fi

# Verificar deployment
echo "Verificando deployment:"
kubectl get daemonset -n monitoring
kubectl get pods -n monitoring

echo "✅ Deployment Kubernetes concluído"
```

### Script Principal do Exercício

```bash
#!/bin/bash
# exercicio-completo.sh

echo "🎯 Exercício Prático: Instalação e Configuração do Node Exporter"
echo "================================================================"

PS3="Escolha um cenário para executar: "
options=("Binário + Systemd" "Docker Compose Stack" "Kubernetes + Helm" "Todos" "Sair")

select opt in "${options[@]}"; do
    case $opt in
        "Binário + Systemd")
            source exercicio-cenario1.sh
            ;;
        "Docker Compose Stack")
            source exercicio-cenario2.sh
            ;;
        "Kubernetes + Helm")
            source exercicio-cenario3.sh
            ;;
        "Todos")
            source exercicio-cenario1.sh
            echo
            source exercicio-cenario2.sh
            echo
            source exercicio-cenario3.sh
            ;;
        "Sair")
            break
            ;;
        *) echo "Opção inválida $REPLY";;
    esac
done

echo "Exercício concluído! 🎉"
```

### Validação do Exercício

✅ **Critérios de Sucesso:**

1. **Binário**: Download e execução bem-sucedidos
2. **Docker**: Stack completa funcionando
3. **Kubernetes**: DaemonSet deployado corretamente
4. **Endpoints**: Todos os serviços respondendo
5. **Métricas**: Node Exporter coletando dados
6. **Integração**: Prometheus coletando métricas

## 📝 Resumo do Módulo

### Conceitos Aprendidos

✅ **Métodos de Instalação**
- Binário manual com configuração systemd
- Docker com volumes e configurações de segurança
- Kubernetes DaemonSet com Helm
- Package managers (APT, YUM)

✅ **Configurações Avançadas**
- Gerenciamento de collectors
- TextFile collector para métricas customizadas
- Configurações de segurança (TLS, Basic Auth)
- Otimizações de performance

✅ **Deployment em Produção**
- Serviço systemd com hardening
- Docker com security contexts
- Kubernetes com RBAC e resource limits
- Monitoramento e logging

✅ **Boas Práticas**
- Usuário dedicado sem privilégios
- Configuração de collectors por ambiente
- Backup e recovery de configurações
- Monitoramento da própria saúde

### Próximos Passos

🎯 **No próximo módulo** você aprenderá:
- Collectors específicos e suas configurações
- Métricas detalhadas por categoria
- Filtros e exclusões avançadas
- Customização de métricas
- Troubleshooting de collectors

---

## 🧭 Navegação

⬅️ **[Anterior: 01 - Introdução](01-introducao.md)**

➡️ **[Próximo: 03 - Collectors e Métricas](03-collectors-metricas.md)**

⬆️ **[Voltar ao README Principal](README.md)**

---

> 💡 **Dica:** Pratique todos os métodos de instalação apresentados. Cada um tem suas vantagens dependendo do ambiente e requisitos específicos!
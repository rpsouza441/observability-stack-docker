# Módulo 02: Configuração e Deploy

> **Implementação prática do cAdvisor** - Deploy em Docker, Kubernetes e configurações avançadas

## 📋 Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- ✅ Instalar cAdvisor via Docker com configurações otimizadas
- ✅ Implementar cAdvisor em clusters Kubernetes
- ✅ Configurar parâmetros avançados de performance
- ✅ Implementar estratégias de deploy para produção
- ✅ Configurar integração com sistemas de monitoramento

## 🐳 Deploy com Docker

### Instalação Básica

```bash
#!/bin/bash
# deploy-cadvisor-basic.sh - Deploy básico do cAdvisor

set -e

echo "🚀 Deploying cAdvisor..."

# Parar container existente se houver
docker stop cadvisor 2>/dev/null || true
docker rm cadvisor 2>/dev/null || true

# Deploy do cAdvisor
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --restart=unless-stopped \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor:latest

echo "✅ cAdvisor deployed successfully!"
echo "🌐 Web UI: http://localhost:8080"
echo "📊 Metrics: http://localhost:8080/metrics"
```

### Configuração Otimizada para Produção

```yaml
# docker-compose.yml - Configuração completa
version: '3.8'

services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
      - /etc/machine-id:/etc/machine-id:ro
    privileged: true
    devices:
      - /dev/kmsg
    command:
      - '/usr/bin/cadvisor'
      - '--logtostderr'
      - '--v=0'
      - '--housekeeping_interval=30s'
      - '--max_housekeeping_interval=35s'
      - '--event_storage_event_limit=default=0'
      - '--event_storage_age_limit=default=0'
      - '--disable_metrics=percpu,sched,tcp,udp,disk'
      - '--docker_only=true'
      - '--store_container_labels=false'
      - '--whitelisted_container_labels=io.kubernetes.container.name,io.kubernetes.pod.name,io.kubernetes.pod.namespace'
    labels:
      - "prometheus.io/scrape=true"
      - "prometheus.io/port=8080"
      - "prometheus.io/path=/metrics"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          memory: 200M
          cpus: '0.3'
        reservations:
          memory: 100M
          cpus: '0.1'

  # Exemplo de aplicação para monitorar
  nginx:
    image: nginx:alpine
    container_name: nginx-app
    ports:
      - "80:80"
    labels:
      - "cadvisor.monitor=true"
    deploy:
      resources:
        limits:
          memory: 50M
          cpus: '0.1'

  # Redis para teste de métricas
  redis:
    image: redis:alpine
    container_name: redis-app
    labels:
      - "cadvisor.monitor=true"
    deploy:
      resources:
        limits:
          memory: 100M
          cpus: '0.2'
```

### Script de Deploy Avançado

```bash
#!/bin/bash
# deploy-cadvisor-advanced.sh - Deploy com validações

set -e

# Configurações
CADVISOR_VERSION="v0.47.0"
CADVISOR_PORT="8080"
HEALTH_CHECK_TIMEOUT=30

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funções auxiliares
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Verificar se porta está disponível
    if netstat -tuln | grep -q ":${CADVISOR_PORT} "; then
        log_warn "Port ${CADVISOR_PORT} is already in use"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_info "Prerequisites check passed"
}

# Deploy do cAdvisor
deploy_cadvisor() {
    log_info "Deploying cAdvisor ${CADVISOR_VERSION}..."
    
    # Parar container existente
    if docker ps -q -f name=cadvisor | grep -q .; then
        log_info "Stopping existing cAdvisor container..."
        docker stop cadvisor
        docker rm cadvisor
    fi
    
    # Deploy novo container
    docker run \
        --volume=/:/rootfs:ro \
        --volume=/var/run:/var/run:ro \
        --volume=/sys:/sys:ro \
        --volume=/var/lib/docker/:/var/lib/docker:ro \
        --volume=/dev/disk/:/dev/disk:ro \
        --publish=${CADVISOR_PORT}:8080 \
        --detach=true \
        --name=cadvisor \
        --restart=unless-stopped \
        --privileged \
        --device=/dev/kmsg \
        --memory=200m \
        --cpus=0.3 \
        gcr.io/cadvisor/cadvisor:${CADVISOR_VERSION} \
        --logtostderr \
        --v=0 \
        --housekeeping_interval=30s \
        --max_housekeeping_interval=35s \
        --event_storage_event_limit=default=0 \
        --event_storage_age_limit=default=0 \
        --disable_metrics=percpu,sched,tcp,udp \
        --docker_only=true
    
    log_info "cAdvisor container started"
}

# Verificar saúde do serviço
health_check() {
    log_info "Performing health check..."
    
    local count=0
    while [ $count -lt $HEALTH_CHECK_TIMEOUT ]; do
        if curl -s -f "http://localhost:${CADVISOR_PORT}/healthz" > /dev/null; then
            log_info "✅ cAdvisor is healthy"
            return 0
        fi
        
        echo -n "."
        sleep 1
        ((count++))
    done
    
    log_error "❌ Health check failed after ${HEALTH_CHECK_TIMEOUT}s"
    return 1
}

# Mostrar informações do deploy
show_info() {
    log_info "Deployment completed successfully!"
    echo
    echo "📊 cAdvisor Information:"
    echo "   Web UI: http://localhost:${CADVISOR_PORT}"
    echo "   Metrics: http://localhost:${CADVISOR_PORT}/metrics"
    echo "   API: http://localhost:${CADVISOR_PORT}/api/v1.3/containers/"
    echo
    echo "🐳 Container Status:"
    docker ps --filter name=cadvisor --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo
    echo "📈 Sample Metrics:"
    echo "   curl http://localhost:${CADVISOR_PORT}/metrics | grep container_cpu_usage_seconds_total"
}

# Função principal
main() {
    log_info "Starting cAdvisor deployment..."
    
    check_prerequisites
    deploy_cadvisor
    
    if health_check; then
        show_info
    else
        log_error "Deployment failed"
        exit 1
    fi
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## ☸️ Deploy no Kubernetes

### DaemonSet Básico

```yaml
# cadvisor-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
  namespace: monitoring
  labels:
    app: cadvisor
spec:
  selector:
    matchLabels:
      name: cadvisor
  template:
    metadata:
      labels:
        name: cadvisor
        app: cadvisor
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: cadvisor
      hostNetwork: true
      hostPID: true
      containers:
      - name: cadvisor
        image: gcr.io/cadvisor/cadvisor:v0.47.0
        ports:
        - containerPort: 8080
          protocol: TCP
          name: http
        volumeMounts:
        - name: rootfs
          mountPath: /rootfs
          readOnly: true
        - name: var-run
          mountPath: /var/run
          readOnly: true
        - name: sys
          mountPath: /sys
          readOnly: true
        - name: docker
          mountPath: /var/lib/docker
          readOnly: true
        - name: disk
          mountPath: /dev/disk
          readOnly: true
        args:
        - --housekeeping_interval=30s
        - --max_housekeeping_interval=35s
        - --event_storage_event_limit=default=0
        - --event_storage_age_limit=default=0
        - --disable_metrics=percpu,sched,tcp,udp
        - --docker_only=false
        - --store_container_labels=false
        - --whitelisted_container_labels=io.kubernetes.container.name,io.kubernetes.pod.name,io.kubernetes.pod.namespace
        resources:
          requests:
            memory: 100Mi
            cpu: 100m
          limits:
            memory: 200Mi
            cpu: 300m
        securityContext:
          privileged: true
      terminationGracePeriodSeconds: 30
      volumes:
      - name: rootfs
        hostPath:
          path: /
      - name: var-run
        hostPath:
          path: /var/run
      - name: sys
        hostPath:
          path: /sys
      - name: docker
        hostPath:
          path: /var/lib/docker
      - name: disk
        hostPath:
          path: /dev/disk
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cadvisor
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cadvisor
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cadvisor
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cadvisor
subjects:
- kind: ServiceAccount
  name: cadvisor
  namespace: monitoring
```

### Service para Exposição

```yaml
# cadvisor-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: cadvisor
  namespace: monitoring
  labels:
    app: cadvisor
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: cadvisor
---
# Opcional: Ingress para acesso externo
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cadvisor-ingress
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - host: cadvisor.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: cadvisor
            port:
              number: 8080
```

### Script de Deploy Kubernetes

```bash
#!/bin/bash
# deploy-k8s-cadvisor.sh - Deploy cAdvisor no Kubernetes

set -e

# Configurações
NAMESPACE="monitoring"
RELEASE_NAME="cadvisor"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se kubectl está disponível
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Verificar conectividade com cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_info "kubectl check passed"
}

# Criar namespace se não existir
create_namespace() {
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        log_info "Creating namespace $NAMESPACE..."
        kubectl create namespace $NAMESPACE
    else
        log_info "Namespace $NAMESPACE already exists"
    fi
}

# Deploy dos recursos
deploy_resources() {
    log_info "Deploying cAdvisor resources..."
    
    # Aplicar manifests
    kubectl apply -f cadvisor-daemonset.yaml
    kubectl apply -f cadvisor-service.yaml
    
    log_info "Resources deployed successfully"
}

# Aguardar pods ficarem prontos
wait_for_pods() {
    log_info "Waiting for cAdvisor pods to be ready..."
    
    kubectl wait --for=condition=ready pod \
        -l app=cadvisor \
        -n $NAMESPACE \
        --timeout=300s
    
    log_info "All cAdvisor pods are ready"
}

# Mostrar status do deploy
show_status() {
    log_info "Deployment status:"
    
    echo
    echo "📊 Pods Status:"
    kubectl get pods -n $NAMESPACE -l app=cadvisor -o wide
    
    echo
    echo "🔗 Services:"
    kubectl get svc -n $NAMESPACE -l app=cadvisor
    
    echo
    echo "📈 Access Information:"
    echo "   Port Forward: kubectl port-forward -n $NAMESPACE svc/cadvisor 8080:8080"
    echo "   Then access: http://localhost:8080"
    
    # Se ingress estiver configurado
    if kubectl get ingress cadvisor-ingress -n $NAMESPACE &> /dev/null; then
        echo "   Ingress: http://cadvisor.local (configure /etc/hosts)"
    fi
}

# Função principal
main() {
    log_info "Starting cAdvisor Kubernetes deployment..."
    
    check_kubectl
    create_namespace
    deploy_resources
    wait_for_pods
    show_status
    
    log_info "✅ cAdvisor deployment completed successfully!"
}

# Executar
main "$@"
```

## ⚙️ Configurações Avançadas

### Parâmetros de Performance

```yaml
# Configuração otimizada para diferentes cenários

# Desenvolvimento (máxima visibilidade)
development_args:
  - --housekeeping_interval=10s
  - --max_housekeeping_interval=15s
  - --event_storage_event_limit=default=100
  - --event_storage_age_limit=default=24h
  - --store_container_labels=true
  - --docker_only=false

# Produção (performance otimizada)
production_args:
  - --housekeeping_interval=30s
  - --max_housekeeping_interval=35s
  - --event_storage_event_limit=default=0
  - --event_storage_age_limit=default=0
  - --disable_metrics=percpu,sched,tcp,udp,disk
  - --docker_only=true
  - --store_container_labels=false

# Alto volume (máxima performance)
high_volume_args:
  - --housekeeping_interval=60s
  - --max_housekeeping_interval=65s
  - --event_storage_event_limit=default=0
  - --event_storage_age_limit=default=0
  - --disable_metrics=percpu,sched,tcp,udp,disk,network
  - --docker_only=true
  - --store_container_labels=false
  - --max_procs=1
```

### Configuração de Storage

```yaml
# Diferentes backends de storage
storage_configs:
  # Memory (padrão)
  memory:
    driver: "memory"
    duration: "2m"
    
  # InfluxDB
  influxdb:
    driver: "influxdb"
    host: "influxdb:8086"
    database: "cadvisor"
    username: "root"
    password: "root"
    secure: false
    
  # Redis
  redis:
    driver: "redis"
    host: "redis:6379"
    password: ""
    db: 0
```

### Configuração de Segurança

```yaml
# Security Context para Kubernetes
securityContext:
  privileged: true
  runAsUser: 0
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: true
  capabilities:
    add:
    - SYS_ADMIN
    - DAC_OVERRIDE
    - SYS_RESOURCE

# Network Policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cadvisor-netpol
  namespace: monitoring
spec:
  podSelector:
    matchLabels:
      app: cadvisor
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

## 🔧 Configuração com Helm

### Chart Values

```yaml
# values.yaml para Helm Chart
image:
  repository: gcr.io/cadvisor/cadvisor
  tag: v0.47.0
  pullPolicy: IfNotPresent

resources:
  requests:
    memory: 100Mi
    cpu: 100m
  limits:
    memory: 200Mi
    cpu: 300m

args:
  - --housekeeping_interval=30s
  - --max_housekeeping_interval=35s
  - --event_storage_event_limit=default=0
  - --event_storage_age_limit=default=0
  - --disable_metrics=percpu,sched,tcp,udp
  - --docker_only=true

service:
  type: ClusterIP
  port: 8080
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: cadvisor.local
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls: []

serviceMonitor:
  enabled: true
  namespace: monitoring
  interval: 30s
  scrapeTimeout: 10s
  labels:
    release: prometheus

nodeSelector:
  kubernetes.io/os: linux

tolerations:
  - key: node-role.kubernetes.io/master
    effect: NoSchedule
  - key: node-role.kubernetes.io/control-plane
    effect: NoSchedule

affinity: {}
```

### Deploy com Helm

```bash
#!/bin/bash
# deploy-helm-cadvisor.sh

set -e

HELM_RELEASE="cadvisor"
NAMESPACE="monitoring"
CHART_VERSION="0.2.3"

# Adicionar repositório
helm repo add cadvisor https://ckotzbauer.github.io/cadvisor-helm-chart
helm repo update

# Deploy
helm upgrade --install $HELM_RELEASE cadvisor/cadvisor \
  --namespace $NAMESPACE \
  --create-namespace \
  --version $CHART_VERSION \
  --values values.yaml \
  --wait

echo "✅ cAdvisor deployed via Helm"
```

## 🚀 Exercício Prático

### Objetivo
Implementar cAdvisor em ambiente Docker e Kubernetes com configurações otimizadas.

### Parte 1: Docker Deploy

1. **Deploy básico:**
```bash
# Executar script de deploy
chmod +x deploy-cadvisor-advanced.sh
./deploy-cadvisor-advanced.sh
```

2. **Verificar funcionamento:**
```bash
# Testar endpoints
curl http://localhost:8080/healthz
curl http://localhost:8080/metrics | head -20
```

3. **Deploy com Docker Compose:**
```bash
# Usar configuração otimizada
docker-compose up -d
docker-compose ps
```

### Parte 2: Kubernetes Deploy

1. **Preparar manifests:**
```bash
# Aplicar recursos
kubectl apply -f cadvisor-daemonset.yaml
kubectl apply -f cadvisor-service.yaml
```

2. **Verificar deploy:**
```bash
# Status dos pods
kubectl get pods -n monitoring -l app=cadvisor

# Port forward para teste
kubectl port-forward -n monitoring svc/cadvisor 8080:8080
```

3. **Testar métricas:**
```bash
# Acessar métricas
curl http://localhost:8080/metrics | grep container_cpu_usage_seconds_total
```

### Validação
- [ ] cAdvisor executando em Docker
- [ ] Interface web acessível
- [ ] Métricas sendo coletadas
- [ ] Deploy Kubernetes funcionando
- [ ] Pods em todos os nós
- [ ] Service discovery configurado

## 📚 Resumo do Módulo

### Conceitos Aprendidos
- ✅ **Docker Deploy:** Configurações básicas e avançadas
- ✅ **Kubernetes:** DaemonSet, Service, RBAC
- ✅ **Performance:** Otimizações para produção
- ✅ **Segurança:** Configurações de segurança
- ✅ **Helm:** Deploy automatizado

### Próximos Passos
- **[Módulo 03: Métricas e Coleta](03-metricas-coleta.md)** - Aprofundamento em métricas
- **[Módulo 04: Integração com Prometheus](04-integracao-prometheus.md)** - Integração completa

---

## Navegação

- [← Módulo 01: Introdução](01-introducao.md)
- [🏠 Página Principal](README.md)
- [➡️ Próximo: Métricas e Coleta](03-metricas-coleta.md)

---

**Parabéns!** 🎉 Você dominou o deploy do cAdvisor em diferentes ambientes. Agora você pode implementar monitoramento de containers em qualquer infraestrutura!
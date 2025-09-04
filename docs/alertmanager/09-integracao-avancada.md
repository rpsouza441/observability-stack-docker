# 🔗 Módulo 9: Integração Avançada do Alertmanager

> **Objetivo:** Aprender a integrar o Alertmanager com outras ferramentas e sistemas

---

## 📋 ÍNDICE

1. [API do Alertmanager](#1-api-do-alertmanager)
2. [Integração com Grafana](#2-integração-com-grafana)
3. [Integração com Kubernetes](#3-integração-com-kubernetes)
4. [Webhooks Avançados](#4-webhooks-avançados)
5. [Integração com ITSM](#5-integração-com-itsm)
6. [Automação e Orquestração](#6-automação-e-orquestração)
7. [Integração com ChatOps](#7-integração-com-chatops)
8. [Multi-tenancy](#8-multi-tenancy)
9. [High Availability](#9-high-availability)
10. [Casos de Uso Avançados](#10-casos-de-uso-avançados)

---

## 1. API DO ALERTMANAGER

### 🔌 Endpoints Principais

#### 📊 Status e Informações
```bash
# Status geral
curl -s http://localhost:9093/api/v1/status | jq

# Informações de build
curl -s http://localhost:9093/api/v1/status | jq '.data.versionInfo'

# Configuração atual
curl -s http://localhost:9093/api/v1/status | jq '.data.config'

# Receivers disponíveis
curl -s http://localhost:9093/api/v1/receivers | jq '.data[].name'
```

#### 🚨 Gerenciamento de Alertas
```bash
# Listar todos os alertas
curl -s http://localhost:9093/api/v1/alerts | jq

# Filtrar alertas por label
curl -s "http://localhost:9093/api/v1/alerts?filter=severity=critical" | jq

# Alertas ativos apenas
curl -s "http://localhost:9093/api/v1/alerts?active=true" | jq

# Alertas silenciados
curl -s "http://localhost:9093/api/v1/alerts?silenced=true" | jq
```

#### 🔇 Gerenciamento de Silences
```bash
# Listar silences
curl -s http://localhost:9093/api/v1/silences | jq

# Criar silence via API
curl -X POST http://localhost:9093/api/v1/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {
        "name": "alertname",
        "value": "DatabaseDown",
        "isRegex": false
      }
    ],
    "startsAt": "2024-01-15T10:00:00Z",
    "endsAt": "2024-01-15T12:00:00Z",
    "createdBy": "admin",
    "comment": "Manutenção programada"
  }'

# Deletar silence
curl -X DELETE http://localhost:9093/api/v1/silence/SILENCE_ID
```

### 🐍 Cliente Python

#### 📦 Biblioteca Personalizada
```python
#!/usr/bin/env python3
# alertmanager_client.py

import requests
import json
from datetime import datetime, timedelta
from typing import List, Dict, Optional

class AlertmanagerClient:
    def __init__(self, base_url: str = "http://localhost:9093"):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
    
    def get_status(self) -> Dict:
        """Obter status do Alertmanager"""
        response = self.session.get(f"{self.base_url}/api/v1/status")
        response.raise_for_status()
        return response.json()['data']
    
    def get_alerts(self, 
                   active: Optional[bool] = None,
                   silenced: Optional[bool] = None,
                   inhibited: Optional[bool] = None,
                   unprocessed: Optional[bool] = None,
                   filter_labels: Optional[Dict[str, str]] = None) -> List[Dict]:
        """Listar alertas com filtros"""
        params = {}
        
        if active is not None:
            params['active'] = str(active).lower()
        if silenced is not None:
            params['silenced'] = str(silenced).lower()
        if inhibited is not None:
            params['inhibited'] = str(inhibited).lower()
        if unprocessed is not None:
            params['unprocessed'] = str(unprocessed).lower()
        
        if filter_labels:
            filters = []
            for key, value in filter_labels.items():
                filters.append(f"{key}={value}")
            params['filter'] = ','.join(filters)
        
        response = self.session.get(f"{self.base_url}/api/v1/alerts", params=params)
        response.raise_for_status()
        return response.json()['data']
    
    def create_silence(self, 
                      matchers: List[Dict[str, str]], 
                      duration_hours: int = 1,
                      comment: str = "Created via API",
                      created_by: str = "api-client") -> str:
        """Criar silence"""
        starts_at = datetime.utcnow()
        ends_at = starts_at + timedelta(hours=duration_hours)
        
        silence_data = {
            "matchers": matchers,
            "startsAt": starts_at.isoformat() + "Z",
            "endsAt": ends_at.isoformat() + "Z",
            "createdBy": created_by,
            "comment": comment
        }
        
        response = self.session.post(
            f"{self.base_url}/api/v1/silences",
            json=silence_data
        )
        response.raise_for_status()
        return response.json()['silenceID']
    
    def delete_silence(self, silence_id: str) -> bool:
        """Deletar silence"""
        response = self.session.delete(f"{self.base_url}/api/v1/silence/{silence_id}")
        return response.status_code == 200
    
    def get_silences(self) -> List[Dict]:
        """Listar silences"""
        response = self.session.get(f"{self.base_url}/api/v1/silences")
        response.raise_for_status()
        return response.json()['data']

# Exemplo de uso
if __name__ == "__main__":
    client = AlertmanagerClient()
    
    # Obter status
    status = client.get_status()
    print(f"Alertmanager versão: {status['versionInfo']['version']}")
    
    # Listar alertas críticos
    critical_alerts = client.get_alerts(
        active=True,
        filter_labels={'severity': 'critical'}
    )
    print(f"Alertas críticos ativos: {len(critical_alerts)}")
    
    # Criar silence para manutenção
    matchers = [
        {"name": "instance", "value": "db-01.prod.com", "isRegex": False},
        {"name": "severity", "value": "critical", "isRegex": False}
    ]
    
    silence_id = client.create_silence(
        matchers=matchers,
        duration_hours=2,
        comment="Manutenção do banco de dados",
        created_by="ops-team"
    )
    print(f"Silence criado: {silence_id}")
```

#### 🔄 Automação com Python
```python
#!/usr/bin/env python3
# alert_automation.py

import time
import logging
from alertmanager_client import AlertmanagerClient
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AlertAutomation:
    def __init__(self, alertmanager_url: str):
        self.client = AlertmanagerClient(alertmanager_url)
        self.auto_silence_rules = [
            {
                'name': 'maintenance_window',
                'matchers': [{'name': 'maintenance', 'value': 'true', 'isRegex': False}],
                'duration_hours': 4,
                'comment': 'Janela de manutenção automática'
            }
        ]
    
    def auto_silence_maintenance_alerts(self):
        """Silenciar automaticamente alertas de manutenção"""
        alerts = self.client.get_alerts(active=True)
        
        for alert in alerts:
            labels = alert.get('labels', {})
            
            # Verificar se é alerta de manutenção
            if labels.get('maintenance') == 'true':
                # Verificar se já não está silenciado
                if not alert.get('status', {}).get('silencedBy'):
                    matchers = [
                        {
                            'name': 'alertname',
                            'value': labels.get('alertname'),
                            'isRegex': False
                        },
                        {
                            'name': 'instance',
                            'value': labels.get('instance'),
                            'isRegex': False
                        }
                    ]
                    
                    silence_id = self.client.create_silence(
                        matchers=matchers,
                        duration_hours=4,
                        comment="Auto-silence: Manutenção detectada",
                        created_by="automation"
                    )
                    
                    logger.info(f"Auto-silenciado alerta {labels.get('alertname')} "
                              f"para {labels.get('instance')} - Silence ID: {silence_id}")
    
    def cleanup_expired_silences(self):
        """Limpar silences expirados"""
        silences = self.client.get_silences()
        now = datetime.utcnow()
        
        for silence in silences:
            ends_at = datetime.fromisoformat(silence['endsAt'].replace('Z', '+00:00'))
            
            if ends_at < now and silence['status']['state'] == 'active':
                if self.client.delete_silence(silence['id']):
                    logger.info(f"Removido silence expirado: {silence['id']}")
    
    def run_automation_cycle(self):
        """Executar ciclo de automação"""
        logger.info("Iniciando ciclo de automação")
        
        try:
            self.auto_silence_maintenance_alerts()
            self.cleanup_expired_silences()
            logger.info("Ciclo de automação concluído")
        except Exception as e:
            logger.error(f"Erro no ciclo de automação: {e}")

# Script principal
if __name__ == "__main__":
    automation = AlertAutomation("http://localhost:9093")
    
    # Executar a cada 5 minutos
    while True:
        automation.run_automation_cycle()
        time.sleep(300)  # 5 minutos
```

---

## 2. INTEGRAÇÃO COM GRAFANA

### 📊 Configuração do Data Source

#### ⚙️ Grafana Provisioning
```yaml
# grafana/provisioning/datasources/alertmanager.yml
apiVersion: 1

datasources:
  - name: Alertmanager
    type: alertmanager
    access: proxy
    url: http://alertmanager:9093
    isDefault: false
    editable: true
    jsonData:
      # Configurações específicas do Alertmanager
      implementation: prometheus  # ou cortex
      handleGrafanaManagedAlerts: false
    secureJsonData:
      # Credenciais se necessário
      basicAuthPassword: ''
```

#### 🎯 Dashboard de Alertas
```json
{
  "dashboard": {
    "id": null,
    "title": "Alertmanager Overview",
    "tags": ["alertmanager", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Active Alerts",
        "type": "alertlist",
        "targets": [
          {
            "datasource": {
              "type": "alertmanager",
              "uid": "alertmanager-uid"
            },
            "refId": "A"
          }
        ],
        "options": {
          "showOptions": "current",
          "maxItems": 20,
          "sortOrder": 1,
          "dashboardAlerts": false,
          "alertInstanceLabelFilter": "",
          "folder": ""
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "Alerts by Severity",
        "type": "piechart",
        "targets": [
          {
            "datasource": {
              "type": "prometheus",
              "uid": "prometheus-uid"
            },
            "expr": "alertmanager_alerts{state=\"active\"} by (severity)",
            "refId": "A"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 3,
        "title": "Notification Rate",
        "type": "graph",
        "targets": [
          {
            "datasource": {
              "type": "prometheus",
              "uid": "prometheus-uid"
            },
            "expr": "rate(alertmanager_notifications_total[5m]) by (receiver)",
            "legendFormat": "{{receiver}}",
            "refId": "A"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 8
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

### 🔔 Grafana Alerting Integration

#### ⚙️ Notification Policies
```yaml
# grafana/provisioning/alerting/notification-policies.yml
apiVersion: 1

policies:
  - orgId: 1
    receiver: grafana-default-email
    group_by: ['grafana_folder', 'alertname']
    group_wait: 10s
    group_interval: 5m
    repeat_interval: 12h
    routes:
      - receiver: critical-alerts
        matchers:
          - severity = critical
        group_wait: 0s
        repeat_interval: 5m
      - receiver: warning-alerts
        matchers:
          - severity = warning
        group_interval: 10m
        repeat_interval: 1h

contactPoints:
  - orgId: 1
    name: critical-alerts
    receivers:
      - uid: critical-webhook
        type: webhook
        settings:
          url: http://alertmanager:9093/api/v1/alerts
          httpMethod: POST
          title: 'Grafana Alert: {{ .GroupLabels.alertname }}'
      - uid: critical-slack
        type: slack
        settings:
          url: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
          channel: '#critical-alerts'
          username: Grafana
```

---

## 3. INTEGRAÇÃO COM KUBERNETES

### ☸️ Deployment no Kubernetes

#### 📦 Manifests Completos
```yaml
# alertmanager-namespace.yml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    name: monitoring

---
# alertmanager-configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  alertmanager.yml: |
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'alerts@example.com'
      smtp_auth_username: 'alerts@example.com'
      smtp_auth_password_file: '/etc/alertmanager/secrets/smtp-password'
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'default-receiver'
      routes:
      - match:
          severity: critical
        receiver: 'critical-receiver'
        group_wait: 10s
        repeat_interval: 5m
    
    receivers:
    - name: 'default-receiver'
      email_configs:
      - to: 'team@example.com'
        subject: '[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Labels: {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
          {{ end }}
    
    - name: 'critical-receiver'
      email_configs:
      - to: 'oncall@example.com'
        subject: '🔴 CRITICAL: {{ .GroupLabels.alertname }}'
      slack_configs:
      - api_url_file: '/etc/alertmanager/secrets/slack-webhook'
        channel: '#critical-alerts'
        title: '🔴 Critical Alert'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Annotations.summary }}
          *Severity:* {{ .Labels.severity }}
          *Instance:* {{ .Labels.instance }}
          {{ end }}

---
# alertmanager-secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-secrets
  namespace: monitoring
type: Opaque
data:
  smtp-password: <base64-encoded-password>
  slack-webhook: <base64-encoded-webhook-url>

---
# alertmanager-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
  namespace: monitoring
  labels:
    app: alertmanager
spec:
  replicas: 2
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      labels:
        app: alertmanager
    spec:
      serviceAccountName: alertmanager
      containers:
      - name: alertmanager
        image: prom/alertmanager:v0.25.0
        args:
          - '--config.file=/etc/alertmanager/alertmanager.yml'
          - '--storage.path=/alertmanager'
          - '--web.external-url=http://alertmanager.example.com'
          - '--web.route-prefix=/'
          - '--cluster.listen-address=0.0.0.0:9094'
          - '--cluster.peer=alertmanager-0.alertmanager.monitoring.svc.cluster.local:9094'
          - '--cluster.peer=alertmanager-1.alertmanager.monitoring.svc.cluster.local:9094'
        ports:
        - containerPort: 9093
          name: web
        - containerPort: 9094
          name: cluster
        volumeMounts:
        - name: config
          mountPath: /etc/alertmanager
        - name: secrets
          mountPath: /etc/alertmanager/secrets
          readOnly: true
        - name: storage
          mountPath: /alertmanager
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /-/healthy
            port: 9093
          initialDelaySeconds: 30
          timeoutSeconds: 10
        readinessProbe:
          httpGet:
            path: /-/ready
            port: 9093
          initialDelaySeconds: 5
          timeoutSeconds: 5
      volumes:
      - name: config
        configMap:
          name: alertmanager-config
      - name: secrets
        secret:
          secretName: alertmanager-secrets
      - name: storage
        persistentVolumeClaim:
          claimName: alertmanager-storage

---
# alertmanager-service.yml
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
  namespace: monitoring
  labels:
    app: alertmanager
spec:
  type: ClusterIP
  ports:
  - port: 9093
    targetPort: 9093
    name: web
  - port: 9094
    targetPort: 9094
    name: cluster
  selector:
    app: alertmanager

---
# alertmanager-ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alertmanager
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: alertmanager-auth
spec:
  tls:
  - hosts:
    - alertmanager.example.com
    secretName: alertmanager-tls
  rules:
  - host: alertmanager.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: alertmanager
            port:
              number: 9093
```

#### 🔐 RBAC Configuration
```yaml
# alertmanager-rbac.yml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: alertmanager
  namespace: monitoring

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: alertmanager
rules:
- apiGroups: [""]
  resources: ["nodes", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: alertmanager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: alertmanager
subjects:
- kind: ServiceAccount
  name: alertmanager
  namespace: monitoring
```

### 🎯 Kubernetes-specific Alerts

#### 🚨 Alert Rules para K8s
```yaml
# kubernetes-alerts.yml
groups:
- name: kubernetes.rules
  rules:
  # Pod crashlooping
  - alert: KubernetesPodCrashLooping
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
    for: 5m
    labels:
      severity: warning
      service: kubernetes
    annotations:
      summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
      description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been restarting {{ $value }} times in the last 15 minutes"
  
  # Node not ready
  - alert: KubernetesNodeNotReady
    expr: kube_node_status_condition{condition="Ready",status="true"} == 0
    for: 5m
    labels:
      severity: critical
      service: kubernetes
    annotations:
      summary: "Node {{ $labels.node }} is not ready"
      description: "Node {{ $labels.node }} has been not ready for more than 5 minutes"
  
  # High memory usage
  - alert: KubernetesPodHighMemoryUsage
    expr: |
      (
        container_memory_working_set_bytes{container!=""} / 
        container_spec_memory_limit_bytes{container!=""} * 100
      ) > 90
    for: 10m
    labels:
      severity: warning
      service: kubernetes
    annotations:
      summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} high memory usage"
      description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} memory usage is {{ $value }}%"
  
  # Deployment rollout stuck
  - alert: KubernetesDeploymentRolloutStuck
    expr: |
      kube_deployment_status_observed_generation{job="kube-state-metrics"}
      !=
      kube_deployment_metadata_generation{job="kube-state-metrics"}
    for: 15m
    labels:
      severity: warning
      service: kubernetes
    annotations:
      summary: "Deployment {{ $labels.namespace }}/{{ $labels.deployment }} rollout is stuck"
      description: "Deployment {{ $labels.namespace }}/{{ $labels.deployment }} rollout has been stuck for more than 15 minutes"
```

---

## 4. WEBHOOKS AVANÇADOS

### 🔗 Webhook Server Personalizado

#### 🐍 Flask Webhook Receiver
```python
#!/usr/bin/env python3
# webhook_server.py

from flask import Flask, request, jsonify
import json
import logging
import requests
from datetime import datetime
from typing import Dict, List

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AlertProcessor:
    def __init__(self):
        self.processors = {
            'critical': self.process_critical_alert,
            'warning': self.process_warning_alert,
            'info': self.process_info_alert
        }
        
        # Configurações de integração
        self.jira_config = {
            'url': 'https://company.atlassian.net',
            'username': 'alerts@company.com',
            'api_token': 'your-api-token',
            'project': 'OPS'
        }
        
        self.pagerduty_config = {
            'integration_key': 'your-integration-key',
            'api_url': 'https://events.pagerduty.com/v2/enqueue'
        }
    
    def process_alerts(self, alerts: List[Dict]) -> Dict:
        """Processar lista de alertas"""
        results = []
        
        for alert in alerts:
            severity = alert.get('labels', {}).get('severity', 'info')
            processor = self.processors.get(severity, self.process_info_alert)
            
            try:
                result = processor(alert)
                results.append(result)
                logger.info(f"Processado alerta {alert.get('labels', {}).get('alertname')} - {result}")
            except Exception as e:
                logger.error(f"Erro processando alerta: {e}")
                results.append({'status': 'error', 'message': str(e)})
        
        return {'processed': len(results), 'results': results}
    
    def process_critical_alert(self, alert: Dict) -> Dict:
        """Processar alerta crítico"""
        # 1. Criar ticket no Jira
        jira_ticket = self.create_jira_ticket(alert)
        
        # 2. Criar incident no PagerDuty
        pagerduty_incident = self.create_pagerduty_incident(alert)
        
        # 3. Notificar Slack com urgência
        slack_result = self.send_urgent_slack_notification(alert)
        
        return {
            'status': 'processed',
            'severity': 'critical',
            'actions': {
                'jira_ticket': jira_ticket,
                'pagerduty_incident': pagerduty_incident,
                'slack_notification': slack_result
            }
        }
    
    def process_warning_alert(self, alert: Dict) -> Dict:
        """Processar alerta de warning"""
        # 1. Verificar se já existe ticket relacionado
        existing_ticket = self.check_existing_jira_ticket(alert)
        
        if not existing_ticket:
            # 2. Criar ticket no Jira
            jira_ticket = self.create_jira_ticket(alert, priority='Medium')
        else:
            jira_ticket = existing_ticket
        
        # 3. Notificar Slack
        slack_result = self.send_slack_notification(alert)
        
        return {
            'status': 'processed',
            'severity': 'warning',
            'actions': {
                'jira_ticket': jira_ticket,
                'slack_notification': slack_result
            }
        }
    
    def process_info_alert(self, alert: Dict) -> Dict:
        """Processar alerta informativo"""
        # Apenas log e notificação Slack
        slack_result = self.send_slack_notification(alert, channel='#monitoring-info')
        
        return {
            'status': 'processed',
            'severity': 'info',
            'actions': {
                'slack_notification': slack_result
            }
        }
    
    def create_jira_ticket(self, alert: Dict, priority: str = 'High') -> Dict:
        """Criar ticket no Jira"""
        labels = alert.get('labels', {})
        annotations = alert.get('annotations', {})
        
        ticket_data = {
            'fields': {
                'project': {'key': self.jira_config['project']},
                'summary': f"[ALERT] {labels.get('alertname', 'Unknown Alert')}",
                'description': {
                    'type': 'doc',
                    'version': 1,
                    'content': [{
                        'type': 'paragraph',
                        'content': [{
                            'type': 'text',
                            'text': f"Alert: {annotations.get('summary', 'No summary')}\n"
                                   f"Description: {annotations.get('description', 'No description')}\n"
                                   f"Instance: {labels.get('instance', 'Unknown')}\n"
                                   f"Severity: {labels.get('severity', 'Unknown')}\n"
                                   f"Started: {alert.get('startsAt', 'Unknown')}"
                        }]
                    }]
                },
                'issuetype': {'name': 'Task'},
                'priority': {'name': priority},
                'labels': ['monitoring', 'alert', labels.get('severity', 'unknown')]
            }
        }
        
        try:
            response = requests.post(
                f"{self.jira_config['url']}/rest/api/3/issue",
                json=ticket_data,
                auth=(self.jira_config['username'], self.jira_config['api_token']),
                headers={'Content-Type': 'application/json'}
            )
            
            if response.status_code == 201:
                ticket = response.json()
                return {'status': 'created', 'key': ticket['key'], 'id': ticket['id']}
            else:
                return {'status': 'error', 'message': response.text}
        
        except Exception as e:
            return {'status': 'error', 'message': str(e)}
    
    def create_pagerduty_incident(self, alert: Dict) -> Dict:
        """Criar incident no PagerDuty"""
        labels = alert.get('labels', {})
        annotations = alert.get('annotations', {})
        
        incident_data = {
            'routing_key': self.pagerduty_config['integration_key'],
            'event_action': 'trigger',
            'dedup_key': f"{labels.get('alertname')}_{labels.get('instance')}",
            'payload': {
                'summary': f"[CRITICAL] {labels.get('alertname')}",
                'source': labels.get('instance', 'unknown'),
                'severity': 'critical',
                'component': labels.get('service', 'unknown'),
                'group': labels.get('team', 'ops'),
                'class': 'monitoring',
                'custom_details': {
                    'alert_description': annotations.get('description'),
                    'runbook_url': annotations.get('runbook_url'),
                    'dashboard_url': annotations.get('dashboard_url'),
                    'labels': labels
                }
            }
        }
        
        try:
            response = requests.post(
                self.pagerduty_config['api_url'],
                json=incident_data,
                headers={'Content-Type': 'application/json'}
            )
            
            if response.status_code == 202:
                result = response.json()
                return {'status': 'created', 'dedup_key': result['dedup_key']}
            else:
                return {'status': 'error', 'message': response.text}
        
        except Exception as e:
            return {'status': 'error', 'message': str(e)}
    
    def send_slack_notification(self, alert: Dict, channel: str = '#alerts') -> Dict:
        """Enviar notificação para Slack"""
        # Implementação simplificada
        return {'status': 'sent', 'channel': channel}
    
    def send_urgent_slack_notification(self, alert: Dict) -> Dict:
        """Enviar notificação urgente para Slack"""
        # Implementação com @here ou @channel
        return {'status': 'sent', 'channel': '#critical-alerts', 'urgent': True}
    
    def check_existing_jira_ticket(self, alert: Dict) -> Dict:
        """Verificar se já existe ticket para este alerta"""
        # Implementação de busca no Jira
        return None

# Instância global do processador
processor = AlertProcessor()

@app.route('/webhook', methods=['POST'])
def webhook():
    """Endpoint principal do webhook"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data received'}), 400
        
        # Log da requisição
        logger.info(f"Webhook recebido: {len(data.get('alerts', []))} alertas")
        
        # Processar alertas
        result = processor.process_alerts(data.get('alerts', []))
        
        return jsonify({
            'status': 'success',
            'timestamp': datetime.utcnow().isoformat(),
            'result': result
        })
    
    except Exception as e:
        logger.error(f"Erro processando webhook: {e}")
        return jsonify({
            'status': 'error',
            'message': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
```

#### 🐳 Docker para Webhook Server
```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY webhook_server.py .

EXPOSE 8080

CMD ["python", "webhook_server.py"]
```

```txt
# requirements.txt
Flask==2.3.3
requests==2.31.0
gunicorn==21.2.0
```

```yaml
# docker-compose.yml (adicionar ao existente)
services:
  webhook-server:
    build: ./webhook-server
    ports:
      - "8080:8080"
    environment:
      - JIRA_URL=https://company.atlassian.net
      - JIRA_USERNAME=alerts@company.com
      - JIRA_API_TOKEN=your-api-token
      - PAGERDUTY_INTEGRATION_KEY=your-integration-key
    networks:
      - monitoring
    restart: unless-stopped
```

---

## 5. INTEGRAÇÃO COM ITSM

### 🎫 ServiceNow Integration

#### 🔗 ServiceNow Webhook
```python
#!/usr/bin/env python3
# servicenow_integration.py

import requests
import json
from datetime import datetime
from typing import Dict, List

class ServiceNowIntegration:
    def __init__(self, instance_url: str, username: str, password: str):
        self.instance_url = instance_url.rstrip('/')
        self.auth = (username, password)
        self.headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
    
    def create_incident(self, alert: Dict) -> Dict:
        """Criar incident no ServiceNow"""
        labels = alert.get('labels', {})
        annotations = alert.get('annotations', {})
        
        # Mapear severity do Prometheus para ServiceNow
        severity_mapping = {
            'critical': '1',  # Critical
            'warning': '2',   # High
            'info': '3'       # Medium
        }
        
        urgency_mapping = {
            'critical': '1',  # High
            'warning': '2',   # Medium
            'info': '3'       # Low
        }
        
        prometheus_severity = labels.get('severity', 'info')
        
        incident_data = {
            'short_description': f"[MONITORING] {labels.get('alertname', 'Unknown Alert')}",
            'description': f"""
            Alert Summary: {annotations.get('summary', 'No summary available')}
            
            Description: {annotations.get('description', 'No description available')}
            
            Instance: {labels.get('instance', 'Unknown')}
            Service: {labels.get('service', 'Unknown')}
            Environment: {labels.get('environment', 'Unknown')}
            
            Alert Started: {alert.get('startsAt', 'Unknown')}
            
            Runbook: {annotations.get('runbook_url', 'Not available')}
            Dashboard: {annotations.get('dashboard_url', 'Not available')}
            
            Labels: {json.dumps(labels, indent=2)}
            """,
            'severity': severity_mapping.get(prometheus_severity, '3'),
            'urgency': urgency_mapping.get(prometheus_severity, '3'),
            'category': 'Infrastructure',
            'subcategory': 'Monitoring',
            'assignment_group': labels.get('team', 'IT Operations'),
            'caller_id': 'monitoring.system',
            'contact_type': 'Monitoring System',
            'u_alert_source': 'Prometheus/Alertmanager',
            'u_alert_name': labels.get('alertname'),
            'u_instance': labels.get('instance'),
            'u_severity': prometheus_severity,
            'work_notes': f"Incident created automatically from Prometheus alert at {datetime.utcnow().isoformat()}"
        }
        
        try:
            response = requests.post(
                f"{self.instance_url}/api/now/table/incident",
                json=incident_data,
                auth=self.auth,
                headers=self.headers
            )
            
            if response.status_code == 201:
                incident = response.json()['result']
                return {
                    'status': 'created',
                    'incident_number': incident['number'],
                    'sys_id': incident['sys_id'],
                    'url': f"{self.instance_url}/nav_to.do?uri=incident.do?sys_id={incident['sys_id']}"
                }
            else:
                return {
                    'status': 'error',
                    'message': f"HTTP {response.status_code}: {response.text}"
                }
        
        except Exception as e:
            return {'status': 'error', 'message': str(e)}
    
    def resolve_incident(self, incident_number: str, resolution_notes: str = "") -> Dict:
        """Resolver incident no ServiceNow"""
        # Buscar incident pelo número
        search_response = requests.get(
            f"{self.instance_url}/api/now/table/incident",
            params={'sysparm_query': f'number={incident_number}'},
            auth=self.auth,
            headers=self.headers
        )
        
        if search_response.status_code != 200:
            return {'status': 'error', 'message': 'Incident not found'}
        
        incidents = search_response.json()['result']
        if not incidents:
            return {'status': 'error', 'message': 'Incident not found'}
        
        incident = incidents[0]
        sys_id = incident['sys_id']
        
        # Atualizar incident para resolved
        update_data = {
            'state': '6',  # Resolved
            'resolution_code': 'Solved (Permanently)',
            'resolution_notes': resolution_notes or f"Alert resolved automatically at {datetime.utcnow().isoformat()}",
            'resolved_by': 'monitoring.system',
            'resolved_at': datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        try:
            response = requests.put(
                f"{self.instance_url}/api/now/table/incident/{sys_id}",
                json=update_data,
                auth=self.auth,
                headers=self.headers
            )
            
            if response.status_code == 200:
                return {
                    'status': 'resolved',
                    'incident_number': incident_number,
                    'sys_id': sys_id
                }
            else:
                return {
                    'status': 'error',
                    'message': f"HTTP {response.status_code}: {response.text}"
                }
        
        except Exception as e:
            return {'status': 'error', 'message': str(e)}

# Exemplo de uso no webhook
def process_servicenow_alert(alert: Dict) -> Dict:
    """Processar alerta para ServiceNow"""
    snow = ServiceNowIntegration(
        instance_url='https://your-instance.service-now.com',
        username='monitoring_user',
        password='your_password'
    )
    
    if alert.get('status') == 'firing':
        return snow.create_incident(alert)
    elif alert.get('status') == 'resolved':
        # Buscar incident relacionado e resolver
        incident_number = alert.get('labels', {}).get('incident_number')
        if incident_number:
            return snow.resolve_incident(
                incident_number,
                f"Alert {alert.get('labels', {}).get('alertname')} resolved"
            )
    
    return {'status': 'no_action', 'message': 'No action taken'}
```

---

## 6. AUTOMAÇÃO E ORQUESTRAÇÃO

### 🤖 Ansible Integration

#### 📋 Playbook de Resposta Automática
```yaml
# ansible/alert-response.yml
---
- name: Automated Alert Response
  hosts: localhost
  gather_facts: false
  vars:
    alert_data: "{{ alert | from_json }}"
    alert_labels: "{{ alert_data.labels }}"
    alert_annotations: "{{ alert_data.annotations }}"
  
  tasks:
    - name: Debug alert information
      debug:
        msg: |
          Alert: {{ alert_labels.alertname }}
          Severity: {{ alert_labels.severity }}
          Instance: {{ alert_labels.instance }}
          Status: {{ alert_data.status }}
    
    - name: Handle disk space alert
      block:
        - name: Clean temporary files
          shell: |
            find /tmp -type f -mtime +7 -delete
            find /var/log -name "*.log.gz" -mtime +30 -delete
          delegate_to: "{{ alert_labels.instance.split(':')[0] }}"
        
        - name: Restart log rotation
          service:
            name: logrotate
            state: restarted
          delegate_to: "{{ alert_labels.instance.split(':')[0] }}"
        
        - name: Create silence for 1 hour
          uri:
            url: "http://alertmanager:9093/api/v1/silences"
            method: POST
            body_format: json
            body:
              matchers:
                - name: "alertname"
                  value: "{{ alert_labels.alertname }}"
                  isRegex: false
                - name: "instance"
                  value: "{{ alert_labels.instance }}"
                  isRegex: false
              startsAt: "{{ ansible_date_time.iso8601 }}"
              endsAt: "{{ (ansible_date_time.epoch | int + 3600) | strftime('%Y-%m-%dT%H:%M:%SZ') }}"
              createdBy: "ansible-automation"
              comment: "Auto-remediation applied: disk cleanup performed"
      when: alert_labels.alertname == "DiskSpaceHigh" and alert_data.status == "firing"
    
    - name: Handle service down alert
      block:
        - name: Restart service
          service:
            name: "{{ alert_labels.service }}"
            state: restarted
          delegate_to: "{{ alert_labels.instance.split(':')[0] }}"
        
        - name: Wait for service to be healthy
          wait_for:
            port: "{{ alert_labels.port | default(80) }}"
            host: "{{ alert_labels.instance.split(':')[0] }}"
            timeout: 60
        
        - name: Create silence for 30 minutes
          uri:
            url: "http://alertmanager:9093/api/v1/silences"
            method: POST
            body_format: json
            body:
              matchers:
                - name: "alertname"
                  value: "{{ alert_labels.alertname }}"
                  isRegex: false
                - name: "instance"
                  value: "{{ alert_labels.instance }}"
                  isRegex: false
              startsAt: "{{ ansible_date_time.iso8601 }}"
              endsAt: "{{ (ansible_date_time.epoch | int + 1800) | strftime('%Y-%m-%dT%H:%M:%SZ') }}"
              createdBy: "ansible-automation"
              comment: "Auto-remediation applied: service restarted"
      when: alert_labels.alertname == "ServiceDown" and alert_data.status == "firing"
    
    - name: Send notification to Slack
      uri:
        url: "{{ slack_webhook_url }}"
        method: POST
        body_format: json
        body:
          channel: "#ops-automation"
          username: "Ansible Bot"
          text: |
            🤖 *Automated Response Executed*
            
            *Alert:* {{ alert_labels.alertname }}
            *Instance:* {{ alert_labels.instance }}
            *Action:* Auto-remediation completed
            *Status:* {{ 'Success' if ansible_failed_result is not defined else 'Failed' }}
      when: slack_webhook_url is defined
```

#### 🔧 Webhook para Ansible
```python
#!/usr/bin/env python3
# ansible_webhook.py

import subprocess
import json
import tempfile
import os
from flask import Flask, request, jsonify

app = Flask(__name__)

class AnsibleRunner:
    def __init__(self, playbook_path: str):
        self.playbook_path = playbook_path
    
    def run_playbook(self, alert_data: dict, extra_vars: dict = None) -> dict:
        """Executar playbook Ansible com dados do alerta"""
        
        # Preparar variáveis
        variables = {
            'alert': json.dumps(alert_data),
            **(extra_vars or {})
        }
        
        # Criar arquivo temporário para variáveis
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(variables, f)
            vars_file = f.name
        
        try:
            # Executar ansible-playbook
            cmd = [
                'ansible-playbook',
                self.playbook_path,
                '--extra-vars', f'@{vars_file}',
                '--inventory', 'localhost,',
                '--connection', 'local'
            ]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300  # 5 minutos timeout
            )
            
            return {
                'status': 'success' if result.returncode == 0 else 'failed',
                'return_code': result.returncode,
                'stdout': result.stdout,
                'stderr': result.stderr
            }
        
        except subprocess.TimeoutExpired:
            return {
                'status': 'timeout',
                'message': 'Playbook execution timed out'
            }
        
        except Exception as e:
            return {
                'status': 'error',
                'message': str(e)
            }
        
        finally:
            # Limpar arquivo temporário
            if os.path.exists(vars_file):
                os.unlink(vars_file)

ansible_runner = AnsibleRunner('/app/playbooks/alert-response.yml')

@app.route('/ansible-webhook', methods=['POST'])
def ansible_webhook():
    """Webhook para executar automação Ansible"""
    try:
        data = request.get_json()
        alerts = data.get('alerts', [])
        
        results = []
        
        for alert in alerts:
            # Executar playbook para cada alerta
            result = ansible_runner.run_playbook(
                alert_data=alert,
                extra_vars={
                    'slack_webhook_url': os.getenv('SLACK_WEBHOOK_URL')
                }
            )
            
            results.append({
                'alert': alert.get('labels', {}).get('alertname'),
                'instance': alert.get('labels', {}).get('instance'),
                'result': result
            })
        
        return jsonify({
            'status': 'completed',
            'processed_alerts': len(alerts),
            'results': results
        })
    
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)
```

---

## 7. INTEGRAÇÃO COM CHATOPS

### 💬 Slack Bot Integration

#### 🤖 Slack Bot para Alertmanager
```python
#!/usr/bin/env python3
# slack_bot.py

from slack_bolt import App
from slack_bolt.adapter.flask import SlackRequestHandler
from flask import Flask, request
import os
import requests
import json
from datetime import datetime, timedelta

# Inicializar Slack app
app = App(
    token=os.environ.get("SLACK_BOT_TOKEN"),
    signing_secret=os.environ.get("SLACK_SIGNING_SECRET")
)

# Configuração do Alertmanager
ALERTMANAGER_URL = os.environ.get("ALERTMANAGER_URL", "http://localhost:9093")

class AlertmanagerBot:
    def __init__(self, alertmanager_url: str):
        self.am_url = alertmanager_url
    
    def get_alerts(self, filters: dict = None) -> list:
        """Obter alertas do Alertmanager"""
        params = {}
        if filters:
            filter_strings = []
            for key, value in filters.items():
                filter_strings.append(f"{key}={value}")
            params['filter'] = ','.join(filter_strings)
        
        response = requests.get(f"{self.am_url}/api/v1/alerts", params=params)
        if response.status_code == 200:
            return response.json()['data']
        return []
    
    def create_silence(self, matchers: list, duration_hours: int, comment: str, created_by: str) -> dict:
        """Criar silence"""
        starts_at = datetime.utcnow()
        ends_at = starts_at + timedelta(hours=duration_hours)
        
        silence_data = {
            "matchers": matchers,
            "startsAt": starts_at.isoformat() + "Z",
            "endsAt": ends_at.isoformat() + "Z",
            "createdBy": created_by,
            "comment": comment
        }
        
        response = requests.post(f"{self.am_url}/api/v1/silences", json=silence_data)
        if response.status_code == 200:
            return response.json()
        return None
    
    def get_silences(self) -> list:
        """Obter silences ativos"""
        response = requests.get(f"{self.am_url}/api/v1/silences")
        if response.status_code == 200:
            return response.json()['data']
        return []

bot = AlertmanagerBot(ALERTMANAGER_URL)

# Comando: /alerts
@app.command("/alerts")
def handle_alerts_command(ack, respond, command):
    ack()
    
    # Parsear argumentos
    args = command['text'].strip().split() if command['text'] else []
    
    filters = {}
    if args:
        for arg in args:
            if '=' in arg:
                key, value = arg.split('=', 1)
                filters[key] = value
    
    # Obter alertas
    alerts = bot.get_alerts(filters)
    
    if not alerts:
        respond("📭 Nenhum alerta encontrado com os filtros especificados.")
        return
    
    # Formatar resposta
    blocks = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": f"🚨 Alertas Ativos ({len(alerts)})"
            }
        }
    ]
    
    for alert in alerts[:10]:  # Limitar a 10 alertas
        labels = alert.get('labels', {})
        annotations = alert.get('annotations', {})
        
        severity_emoji = {
            'critical': '🔴',
            'warning': '🟡',
            'info': '🔵'
        }.get(labels.get('severity'), '⚪')
        
        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"{severity_emoji} *{labels.get('alertname', 'Unknown')}*\n"
                       f"📍 Instance: `{labels.get('instance', 'Unknown')}`\n"
                       f"📝 Summary: {annotations.get('summary', 'No summary')}\n"
                       f"⏰ Started: {alert.get('startsAt', 'Unknown')}"
            },
            "accessory": {
                "type": "button",
                "text": {
                    "type": "plain_text",
                    "text": "Silence"
                },
                "action_id": "silence_alert",
                "value": json.dumps({
                    "alertname": labels.get('alertname'),
                    "instance": labels.get('instance')
                })
            }
        })
    
    if len(alerts) > 10:
        blocks.append({
            "type": "context",
            "elements": [{
                "type": "mrkdwn",
                "text": f"... e mais {len(alerts) - 10} alertas. Use filtros para refinar a busca."
            }]
        })
    
    respond(blocks=blocks)

# Comando: /silence
@app.command("/silence")
def handle_silence_command(ack, respond, command):
    ack()
    
    args = command['text'].strip().split() if command['text'] else []
    
    if len(args) < 2:
        respond({
            "text": "❌ Uso incorreto. Exemplo: `/silence alertname=DatabaseDown duration=2h comment=\"Manutenção programada\"`",
            "response_type": "ephemeral"
        })
        return
    
    # Parsear argumentos
    matchers = []
    duration_hours = 1
    comment = "Silenciado via Slack"
    
    for arg in args:
        if '=' in arg:
            key, value = arg.split('=', 1)
            if key == 'duration':
                # Parsear duração (ex: 2h, 30m)
                if value.endswith('h'):
                    duration_hours = int(value[:-1])
                elif value.endswith('m'):
                    duration_hours = int(value[:-1]) / 60
            elif key == 'comment':
                comment = value.strip('"\'')
            else:
                matchers.append({
                    "name": key,
                    "value": value,
                    "isRegex": False
                })
    
    if not matchers:
        respond({
            "text": "❌ Nenhum matcher especificado. Exemplo: `alertname=DatabaseDown`",
            "response_type": "ephemeral"
        })
        return
    
    # Criar silence
    result = bot.create_silence(
        matchers=matchers,
        duration_hours=duration_hours,
        comment=comment,
        created_by=command['user_name']
    )
    
    if result:
        respond({
            "text": f"✅ Silence criado com sucesso!\n"
                   f"🆔 ID: `{result.get('silenceID')}`\n"
                   f"⏱️ Duração: {duration_hours}h\n"
                   f"💬 Comentário: {comment}",
            "response_type": "ephemeral"
        })
    else:
        respond({
            "text": "❌ Erro ao criar silence. Verifique os parâmetros.",
            "response_type": "ephemeral"
        })

# Botão de silence
@app.action("silence_alert")
def handle_silence_button(ack, body, respond):
    ack()
    
    # Extrair dados do alerta
    alert_data = json.loads(body['actions'][0]['value'])
    
    # Criar matchers
    matchers = []
    if alert_data.get('alertname'):
        matchers.append({
            "name": "alertname",
            "value": alert_data['alertname'],
            "isRegex": False
        })
    if alert_data.get('instance'):
        matchers.append({
            "name": "instance",
            "value": alert_data['instance'],
            "isRegex": False
        })
    
    # Criar silence de 1 hora
    result = bot.create_silence(
        matchers=matchers,
        duration_hours=1,
        comment="Silenciado via botão do Slack",
        created_by=body['user']['username']
    )
    
    if result:
        respond({
            "text": f"✅ Alerta `{alert_data.get('alertname')}` silenciado por 1 hora!",
            "response_type": "ephemeral"
        })
    else:
        respond({
            "text": "❌ Erro ao silenciar alerta.",
            "response_type": "ephemeral"
        })

# Comando: /silences
@app.command("/silences")
def handle_silences_command(ack, respond):
    ack()
    
    silences = bot.get_silences()
    active_silences = [s for s in silences if s['status']['state'] == 'active']
    
    if not active_silences:
        respond("📭 Nenhum silence ativo no momento.")
        return
    
    blocks = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": f"🔇 Silences Ativos ({len(active_silences)})"
            }
        }
    ]
    
    for silence in active_silences[:5]:  # Limitar a 5 silences
        matchers_text = ", ".join([
            f"{m['name']}={m['value']}"
            for m in silence.get('matchers', [])
        ])
        
        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"🆔 `{silence['id'][:8]}...`\n"
                       f"🎯 Matchers: `{matchers_text}`\n"
                       f"👤 Criado por: {silence.get('createdBy', 'Unknown')}\n"
                       f"💬 Comentário: {silence.get('comment', 'No comment')}\n"
                       f"⏰ Expira: {silence.get('endsAt', 'Unknown')}"
            }
        })
    
    respond(blocks=blocks)

# Flask app para Slack
flask_app = Flask(__name__)
handler = SlackRequestHandler(app)

@flask_app.route("/slack/events", methods=["POST"])
def slack_events():
    return handler.handle(request)

if __name__ == "__main__":
    flask_app.run(host='0.0.0.0', port=3000)
```

#### 🐳 Docker para Slack Bot
```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY slack_bot.py .

EXPOSE 3000

CMD ["python", "slack_bot.py"]
```

```txt
# requirements.txt
slack-bolt==1.18.0
Flask==2.3.3
requests==2.31.0
```

---

## 8. MULTI-TENANCY

### 🏢 Configuração Multi-tenant

#### 🎯 Roteamento por Tenant
```yaml
# alertmanager-multitenant.yml
global:
  smtp_smarthost: 'smtp.company.com:587'
  smtp_from: 'alerts@company.com'

route:
  group_by: ['tenant', 'alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'default'
  
  routes:
  # Tenant A - Equipe de Desenvolvimento
  - match:
      tenant: 'team-a'
    receiver: 'team-a-alerts'
    group_by: ['alertname', 'service']
    routes:
    - match:
        severity: 'critical'
      receiver: 'team-a-critical'
      group_wait: 0s
      repeat_interval: 5m
  
  # Tenant B - Equipe de Infraestrutura
  - match:
      tenant: 'team-b'
    receiver: 'team-b-alerts'
    group_by: ['alertname', 'instance']
    routes:
    - match:
        severity: 'critical'
      receiver: 'team-b-critical'
      group_wait: 0s
      repeat_interval: 10m
  
  # Tenant C - Equipe de Dados
  - match:
      tenant: 'team-c'
    receiver: 'team-c-alerts'
    group_by: ['alertname', 'database']

receivers:
# Default receiver
- name: 'default'
  email_configs:
  - to: 'ops@company.com'
    subject: '[ALERT] {{ .GroupLabels.alertname }}'

# Team A receivers
- name: 'team-a-alerts'
  email_configs:
  - to: 'dev-team-a@company.com'
    subject: '[TEAM-A] {{ .GroupLabels.alertname }}'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/TEAM-A/WEBHOOK'
    channel: '#team-a-alerts'
    title: 'Team A Alert'

- name: 'team-a-critical'
  email_configs:
  - to: 'dev-team-a@company.com,oncall-a@company.com'
    subject: '🔴 [CRITICAL-TEAM-A] {{ .GroupLabels.alertname }}'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/TEAM-A/WEBHOOK'
    channel: '#team-a-critical'
    title: '🔴 CRITICAL: Team A Alert'
  pagerduty_configs:
  - routing_key: 'team-a-integration-key'

# Team B receivers
- name: 'team-b-alerts'
  email_configs:
  - to: 'infra-team-b@company.com'
    subject: '[TEAM-B] {{ .GroupLabels.alertname }}'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/TEAM-B/WEBHOOK'
    channel: '#team-b-alerts'

- name: 'team-b-critical'
  email_configs:
  - to: 'infra-team-b@company.com,oncall-b@company.com'
    subject: '🔴 [CRITICAL-TEAM-B] {{ .GroupLabels.alertname }}'
  pagerduty_configs:
  - routing_key: 'team-b-integration-key'

# Team C receivers
- name: 'team-c-alerts'
  email_configs:
  - to: 'data-team-c@company.com'
    subject: '[TEAM-C] {{ .GroupLabels.alertname }}'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/TEAM-C/WEBHOOK'
    channel: '#team-c-alerts'

inhibit_rules:
# Inibir alertas de warning quando há critical do mesmo serviço
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['tenant', 'service', 'instance']
```

#### 🏷️ Label Injection
```yaml
# prometheus.yml - Configuração para multi-tenancy
global:
  scrape_interval: 15s
  external_labels:
    cluster: 'production'
    region: 'us-east-1'

rule_files:
  - "rules/team-a/*.yml"
  - "rules/team-b/*.yml"
  - "rules/team-c/*.yml"

scrape_configs:
# Team A - Aplicações de desenvolvimento
- job_name: 'team-a-apps'
  static_configs:
  - targets: ['app1:8080', 'app2:8080']
  relabel_configs:
  - target_label: tenant
    replacement: 'team-a'
  - target_label: team
    replacement: 'development'

# Team B - Infraestrutura
- job_name: 'team-b-infra'
  static_configs:
  - targets: ['server1:9100', 'server2:9100']
  relabel_configs:
  - target_label: tenant
    replacement: 'team-b'
  - target_label: team
    replacement: 'infrastructure'

# Team C - Bancos de dados
- job_name: 'team-c-databases'
  static_configs:
  - targets: ['db1:9104', 'db2:9104']
  relabel_configs:
  - target_label: tenant
    replacement: 'team-c'
  - target_label: team
    replacement: 'data'
```

---

## 9. HIGH AVAILABILITY

### 🔄 Cluster Configuration

#### ⚙️ Alertmanager Cluster
```yaml
# docker-compose-ha.yml
version: '3.8'

services:
  alertmanager-1:
    image: prom/alertmanager:latest
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://alertmanager.company.com'
      - '--web.listen-address=0.0.0.0:9093'
      - '--cluster.listen-address=0.0.0.0:9094'
      - '--cluster.peer=alertmanager-2:9094'
      - '--cluster.peer=alertmanager-3:9094'
      - '--cluster.advertise-address=alertmanager-1:9094'
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager-1-data:/alertmanager
    ports:
      - "9093:9093"
    networks:
      - monitoring
    restart: unless-stopped

  alertmanager-2:
    image: prom/alertmanager:latest
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://alertmanager.company.com'
      - '--web.listen-address=0.0.0.0:9093'
      - '--cluster.listen-address=0.0.0.0:9094'
      - '--cluster.peer=alertmanager-1:9094'
      - '--cluster.peer=alertmanager-3:9094'
      - '--cluster.advertise-address=alertmanager-2:9094'
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager-2-data:/alertmanager
    ports:
      - "9094:9093"
    networks:
      - monitoring
    restart: unless-stopped

  alertmanager-3:
    image: prom/alertmanager:latest
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://alertmanager.company.com'
      - '--web.listen-address=0.0.0.0:9093'
      - '--cluster.listen-address=0.0.0.0:9094'
      - '--cluster.peer=alertmanager-1:9094'
      - '--cluster.peer=alertmanager-2:9094'
      - '--cluster.advertise-address=alertmanager-3:9094'
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager-3-data:/alertmanager
    ports:
      - "9095:9093"
    networks:
      - monitoring
    restart: unless-stopped

  # Load balancer para Alertmanager
  nginx-lb:
    image: nginx:alpine
    volumes:
      - ./nginx-alertmanager.conf:/etc/nginx/nginx.conf
    ports:
      - "80:80"
    depends_on:
      - alertmanager-1
      - alertmanager-2
      - alertmanager-3
    networks:
      - monitoring
    restart: unless-stopped

volumes:
  alertmanager-1-data:
  alertmanager-2-data:
  alertmanager-3-data:

networks:
  monitoring:
    driver: bridge
```

#### ⚖️ Nginx Load Balancer
```nginx
# nginx-alertmanager.conf
events {
    worker_connections 1024;
}

http {
    upstream alertmanager {
        server alertmanager-1:9093 max_fails=3 fail_timeout=30s;
        server alertmanager-2:9093 max_fails=3 fail_timeout=30s;
        server alertmanager-3:9093 max_fails=3 fail_timeout=30s;
    }

    server {
        listen 80;
        server_name alertmanager.company.com;

        location / {
            proxy_pass http://alertmanager;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Health check
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
            proxy_connect_timeout 5s;
            proxy_send_timeout 10s;
            proxy_read_timeout 10s;
        }

        location /-/healthy {
            access_log off;
            proxy_pass http://alertmanager;
        }
    }
}
```

### 📊 Monitoramento do Cluster

#### 🎯 Métricas de Cluster
```promql
# Número de instâncias ativas
count(up{job="alertmanager"} == 1)

# Status do cluster
alertmanager_cluster_members

# Peers conectados
alertmanager_cluster_peers

# Falhas de sincronização
rate(alertmanager_cluster_gossip_messages_failed_total[5m])

# Latência de sincronização
histogram_quantile(0.95, 
  rate(alertmanager_cluster_gossip_message_duration_seconds_bucket[5m])
)
```

---

## 10. CASOS DE USO AVANÇADOS

### 🎯 Escalation Automática

#### ⏰ Escalation por Tempo
```yaml
# alertmanager-escalation.yml
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'level-1'
  
  routes:
  # Escalation para alertas críticos
  - match:
      severity: 'critical'
    receiver: 'level-1-critical'
    group_wait: 0s
    repeat_interval: 15m
    routes:
    # Após 15 minutos, escalar para nível 2
    - match:
        escalation: 'level-2'
      receiver: 'level-2-critical'
      repeat_interval: 10m
      routes:
      # Após mais 10 minutos, escalar para nível 3
      - match:
          escalation: 'level-3'
        receiver: 'level-3-critical'
        repeat_interval: 5m

receivers:
- name: 'level-1'
  email_configs:
  - to: 'team@company.com'
    subject: '[L1] {{ .GroupLabels.alertname }}'

- name: 'level-1-critical'
  email_configs:
  - to: 'oncall-l1@company.com'
    subject: '🔴 [L1-CRITICAL] {{ .GroupLabels.alertname }}'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/L1/WEBHOOK'
    channel: '#level-1-alerts'

- name: 'level-2-critical'
  email_configs:
  - to: 'oncall-l2@company.com,manager@company.com'
    subject: '🔴🔴 [L2-CRITICAL] {{ .GroupLabels.alertname }}'
  pagerduty_configs:
  - routing_key: 'level-2-integration-key'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/L2/WEBHOOK'
    channel: '#level-2-alerts'
    text: '@here Critical alert escalated to Level 2'

- name: 'level-3-critical'
  email_configs:
  - to: 'cto@company.com,director@company.com'
    subject: '🔴🔴🔴 [L3-EXECUTIVE] {{ .GroupLabels.alertname }}'
  pagerduty_configs:
  - routing_key: 'executive-integration-key'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/EXEC/WEBHOOK'
    channel: '#executive-alerts'
    text: '@channel CRITICAL: Alert escalated to executive level'
```

#### 🤖 Escalation Automática via Webhook
```python
#!/usr/bin/env python3
# escalation_webhook.py

import time
import requests
import json
from datetime import datetime, timedelta
from threading import Thread
from typing import Dict, List

class EscalationManager:
    def __init__(self, alertmanager_url: str):
        self.am_url = alertmanager_url
        self.escalation_rules = {
            'critical': {
                'level_1_duration': 15,  # minutos
                'level_2_duration': 10,  # minutos
                'level_3_duration': 5    # minutos
            },
            'warning': {
                'level_1_duration': 60,  # minutos
                'level_2_duration': 30   # minutos
            }
        }
        self.active_escalations = {}
    
    def start_escalation(self, alert: Dict):
        """Iniciar processo de escalation para um alerta"""
        alert_key = self.get_alert_key(alert)
        severity = alert.get('labels', {}).get('severity', 'info')
        
        if severity not in self.escalation_rules:
            return
        
        # Agendar escalations
        escalation_config = self.escalation_rules[severity]
        
        # Level 1 -> Level 2
        if 'level_1_duration' in escalation_config:
            timer = Thread(
                target=self.schedule_escalation,
                args=(alert_key, 'level-2', escalation_config['level_1_duration'])
            )
            timer.start()
        
        # Level 2 -> Level 3
        if 'level_2_duration' in escalation_config:
            total_time = escalation_config['level_1_duration'] + escalation_config['level_2_duration']
            timer = Thread(
                target=self.schedule_escalation,
                args=(alert_key, 'level-3', total_time)
            )
            timer.start()
        
        self.active_escalations[alert_key] = {
            'alert': alert,
            'started_at': datetime.utcnow(),
            'severity': severity
        }
    
    def schedule_escalation(self, alert_key: str, escalation_level: str, delay_minutes: int):
        """Agendar escalation após delay"""
        time.sleep(delay_minutes * 60)
        
        # Verificar se alerta ainda está ativo
        if alert_key in self.active_escalations:
            self.escalate_alert(alert_key, escalation_level)
    
    def escalate_alert(self, alert_key: str, escalation_level: str):
        """Escalar alerta adicionando label de escalation"""
        if alert_key not in self.active_escalations:
            return
        
        escalation_data = self.active_escalations[alert_key]
        alert = escalation_data['alert']
        
        # Adicionar label de escalation
        alert['labels']['escalation'] = escalation_level
        
        # Reenviar alerta com novo label
        self.send_alert_to_alertmanager([alert])
        
        print(f"Alert {alert_key} escalated to {escalation_level}")
    
    def stop_escalation(self, alert: Dict):
        """Parar escalation quando alerta é resolvido"""
        alert_key = self.get_alert_key(alert)
        if alert_key in self.active_escalations:
            del self.active_escalations[alert_key]
            print(f"Escalation stopped for {alert_key}")
    
    def get_alert_key(self, alert: Dict) -> str:
        """Gerar chave única para o alerta"""
        labels = alert.get('labels', {})
        return f"{labels.get('alertname')}_{labels.get('instance')}"
    
    def send_alert_to_alertmanager(self, alerts: List[Dict]):
        """Enviar alerta para Alertmanager"""
        try:
            response = requests.post(
                f"{self.am_url}/api/v1/alerts",
                json=alerts,
                headers={'Content-Type': 'application/json'}
            )
            return response.status_code == 200
        except Exception as e:
            print(f"Error sending alert: {e}")
            return False

# Exemplo de uso
escalation_manager = EscalationManager("http://localhost:9093")

def process_webhook_alerts(alerts: List[Dict]):
    """Processar alertas do webhook"""
    for alert in alerts:
        if alert.get('status') == 'firing':
            escalation_manager.start_escalation(alert)
        elif alert.get('status') == 'resolved':
            escalation_manager.stop_escalation(alert)
```

---

## 🎯 RESUMO DO MÓDULO

### ✅ O que você aprendeu:

1. **API do Alertmanager** - Endpoints, clientes Python, automação
2. **Integração com Grafana** - Data sources, dashboards, alerting
3. **Integração com Kubernetes** - Deployments, RBAC, alertas específicos
4. **Webhooks avançados** - Servidores personalizados, processamento complexo
5. **Integração com ITSM** - ServiceNow, Jira, tickets automáticos
6. **Automação e orquestração** - Ansible, resposta automática
7. **Integração com ChatOps** - Slack bots, comandos interativos
8. **Multi-tenancy** - Roteamento por tenant, isolamento de equipes
9. **High Availability** - Clusters, load balancing, redundância
10. **Casos de uso avançados** - Escalation automática, workflows complexos

### 🔧 Principais conceitos:
- **API REST** - Integração programática com Alertmanager
- **Webhooks** - Processamento personalizado de alertas
- **Multi-tenancy** - Isolamento e roteamento por equipes
- **High Availability** - Redundância e tolerância a falhas
- **Automação** - Resposta automática e orquestração

### 🚀 Próximos Passos

Agora que você domina integrações avançadas, vamos finalizar com o **projeto final**:

**Próximo módulo:** [10-projeto-final.md](10-projeto-final.md) - Projeto prático completo

---

## 🔗 Links Relacionados

- **[Anterior: Troubleshooting](08-troubleshooting.md)**
- **[Próximo: Projeto Final](10-projeto-final.md)**
- **[Voltar ao Índice](README.md)**
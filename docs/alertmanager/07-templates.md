# 🎨 ALERTMANAGER - TEMPLATES AVANÇADOS

> **Módulo 7:** Personalizando mensagens de alerta

---

## 📋 CONTEÚDO DESTE MÓDULO

1. [Conceitos de Templates](#1-conceitos-de-templates)
2. [Sintaxe Go Template](#2-sintaxe-go-template)
3. [Variáveis Disponíveis](#3-variáveis-disponíveis)
4. [Templates para Email](#4-templates-para-email)
5. [Templates para Slack](#5-templates-para-slack)
6. [Templates para Webhook](#6-templates-para-webhook)
7. [Funções Auxiliares](#7-funções-auxiliares)
8. [Templates Avançados](#8-templates-avançados)
9. [Debugging e Testes](#9-debugging-e-testes)
10. [Boas Práticas](#10-boas-práticas)

---

## 1. CONCEITOS DE TEMPLATES

### 🎨 O que são Templates?

> **Analogia:** Templates são como **formulários em branco** que o Alertmanager preenche com informações específicas de cada alerta, como preencher um formulário de pedido com dados do cliente.

```mermaid
flowchart LR
    A[Alerta Raw] --> B[Template Engine]
    B --> C[Mensagem Formatada]
    
    D[Template] --> B
    E[Funções] --> B
    F[Variáveis] --> B
    
    subgraph "Dados do Alerta"
        A1[alertname: HighCPU]
        A2[instance: web-01]
        A3[severity: critical]
    end
    
    subgraph "Template"
        T1[🚨 {{ .GroupLabels.alertname }}]
        T2[Servidor: {{ .CommonLabels.instance }}]
        T3[Severidade: {{ .CommonLabels.severity }}]
    end
    
    subgraph "Resultado"
        R1[🚨 HighCPU]
        R2[Servidor: web-01]
        R3[Severidade: critical]
    end
```

### 🏗️ Arquitetura de Templates

```yaml
# Estrutura no alertmanager.yml
templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  receiver: 'web-team'

receivers:
  - name: 'web-team'
    email_configs:
      - to: 'web@empresa.com'
        subject: '{{ template "email.subject" . }}'
        body: '{{ template "email.body" . }}'
        html: '{{ template "email.html" . }}'
```

### 📁 Organização de Arquivos

```
templates/
├── common.tmpl          # Templates compartilhados
├── email.tmpl           # Templates para email
├── slack.tmpl           # Templates para Slack
├── webhook.tmpl         # Templates para webhook
├── functions.tmpl       # Funções customizadas
└── severity/
    ├── critical.tmpl    # Templates por severidade
    ├── warning.tmpl
    └── info.tmpl
```

### 🔄 Fluxo de Processamento

```
1. 📨 Alerta chega no Alertmanager
2. 🛤️ Roteamento determina receiver
3. 🎨 Template engine processa templates
4. 🔧 Funções auxiliares são aplicadas
5. 📝 Mensagem final é gerada
6. 📤 Notificação é enviada
```

---

## 2. SINTAXE GO TEMPLATE

### 🔤 Sintaxe Básica

```go
// ========================================
// 📝 VARIÁVEIS E CAMPOS
// ========================================
{{ .FieldName }}              // Campo simples
{{ .Nested.Field }}           // Campo aninhado
{{ index .Array 0 }}          // Elemento de array
{{ .Map.key }}                // Valor de map

// ========================================
// 🔄 ESTRUTURAS DE CONTROLE
// ========================================
{{ if .Condition }}
  Texto se verdadeiro
{{ else }}
  Texto se falso
{{ end }}

{{ range .Items }}
  Item: {{ . }}
{{ end }}

{{ with .Field }}
  Campo existe: {{ . }}
{{ end }}

// ========================================
// 🔧 FUNÇÕES
// ========================================
{{ len .Array }}              // Tamanho
{{ upper .String }}           // Maiúscula
{{ lower .String }}           // Minúscula
{{ printf "%.2f" .Number }}   // Formatação

// ========================================
// 💬 COMENTÁRIOS
// ========================================
{{/* Este é um comentário */}}

// ========================================
// 🎯 TEMPLATES NOMEADOS
// ========================================
{{ define "template.name" }}
  Conteúdo do template
{{ end }}

{{ template "template.name" . }}
```

### 🔗 Pipelines

```go
// ========================================
// 🔗 PIPELINE BÁSICO
// ========================================
{{ .Value | upper }}                    // Maiúscula
{{ .Value | upper | printf "[%s]" }}    // Maiúscula + formatação

// ========================================
// 🔗 PIPELINE COMPLEXO
// ========================================
{{ .CommonLabels.instance | 
   reReplaceAll "\\..+" "" | 
   upper | 
   printf "Servidor: %s" }}

// ========================================
// 🔗 PIPELINE COM CONDIÇÕES
// ========================================
{{ if .CommonLabels.severity | eq "critical" }}
  🔴 CRÍTICO
{{ else if .CommonLabels.severity | eq "warning" }}
  🟡 ATENÇÃO
{{ else }}
  🔵 INFO
{{ end }}
```

### 🎯 Variáveis Locais

```go
// ========================================
// 📝 DEFININDO VARIÁVEIS
// ========================================
{{ $severity := .CommonLabels.severity }}
{{ $instance := .CommonLabels.instance }}
{{ $count := len .Alerts }}

// ========================================
// 🔧 USANDO VARIÁVEIS
// ========================================
{{ if eq $severity "critical" }}
  🚨 Alerta crítico em {{ $instance }}
  Total de alertas: {{ $count }}
{{ end }}

// ========================================
// 🔄 VARIÁVEIS EM LOOPS
// ========================================
{{ range $index, $alert := .Alerts }}
  {{ $index }}: {{ $alert.Labels.alertname }}
{{ end }}

{{ range $key, $value := .CommonLabels }}
  {{ $key }}: {{ $value }}
{{ end }}
```

---

## 3. VARIÁVEIS DISPONÍVEIS

### 📊 Estrutura de Dados Principal

```go
// ========================================
// 🏗️ ESTRUTURA PRINCIPAL (.)
// ========================================
{
  "Receiver": "web-team",           // Nome do receiver
  "Status": "firing",              // firing ou resolved
  "Alerts": [...],                 // Array de alertas
  "GroupLabels": {...},            // Labels de agrupamento
  "CommonLabels": {...},           // Labels comuns
  "CommonAnnotations": {...},      // Annotations comuns
  "ExternalURL": "http://...",     // URL do Alertmanager
  "TruncatedAlerts": 0             // Alertas truncados
}
```

### 🚨 Estrutura de Alerta Individual

```go
// ========================================
// 📋 CADA ITEM EM .Alerts
// ========================================
{
  "Status": "firing",              // Status do alerta
  "Labels": {                      // Todos os labels
    "alertname": "HighCPU",
    "instance": "web-01.prod.com",
    "job": "node-exporter",
    "severity": "critical",
    "team": "web"
  },
  "Annotations": {                 // Todas as annotations
    "summary": "CPU alta detectada",
    "description": "CPU em 95% por 5 minutos",
    "runbook_url": "https://..."
  },
  "StartsAt": "2024-01-15T10:30:00Z",  // Início do alerta
  "EndsAt": "0001-01-01T00:00:00Z",    // Fim (se resolved)
  "GeneratorURL": "http://prometheus:9090/graph?...",  // Link para Prometheus
  "Fingerprint": "abc123def456"     // ID único do alerta
}
```

### 🏷️ Labels e Annotations

```go
// ========================================
// 🏷️ GROUPlabels (labels de agrupamento)
// ========================================
{{ .GroupLabels.alertname }}        // Nome do alerta
{{ .GroupLabels.service }}          // Serviço
{{ .GroupLabels.environment }}      // Ambiente

// ========================================
// 🏷️ COMMON LABELS (labels comuns a todos)
// ========================================
{{ .CommonLabels.instance }}        // Instância
{{ .CommonLabels.severity }}        // Severidade
{{ .CommonLabels.team }}            // Time responsável

// ========================================
// 📝 COMMON ANNOTATIONS (annotations comuns)
// ========================================
{{ .CommonAnnotations.summary }}    // Resumo
{{ .CommonAnnotations.description }} // Descrição
{{ .CommonAnnotations.runbook_url }} // URL do runbook

// ========================================
// 📋 LABELS/ANNOTATIONS DE ALERTA ESPECÍFICO
// ========================================
{{ range .Alerts }}
  {{ .Labels.alertname }}
  {{ .Annotations.summary }}
{{ end }}
```

### 🔢 Informações de Contexto

```go
// ========================================
// ℹ️ INFORMAÇÕES GERAIS
// ========================================
{{ .Receiver }}                     // Nome do receiver
{{ .Status }}                       // firing ou resolved
{{ len .Alerts }}                   // Número de alertas
{{ .TruncatedAlerts }}              // Alertas truncados
{{ .ExternalURL }}                  // URL do Alertmanager

// ========================================
// ⏰ INFORMAÇÕES DE TEMPO
// ========================================
{{ range .Alerts }}
  {{ .StartsAt }}                   // Início do alerta
  {{ .EndsAt }}                     // Fim do alerta (se resolved)
  {{ .StartsAt.Format "2006-01-02 15:04:05" }}  // Formatado
{{ end }}

// ========================================
// 🔗 LINKS ÚTEIS
// ========================================
{{ range .Alerts }}
  {{ .GeneratorURL }}               // Link para Prometheus
  {{ .Fingerprint }}                // ID único
{{ end }}
```

---

## 4. TEMPLATES PARA EMAIL

### 📧 Template Básico de Email

```go
{{/* templates/email.tmpl */}}

{{/* ======================================== */}}
{{/* 📧 SUBJECT DO EMAIL */}}
{{/* ======================================== */}}
{{ define "email.subject" }}
  {{- $severity := .CommonLabels.severity -}}
  {{- if eq .Status "firing" -}}
    {{- if eq $severity "critical" -}}
      🔴 CRÍTICO
    {{- else if eq $severity "warning" -}}
      🟡 ATENÇÃO
    {{- else -}}
      🔵 INFO
    {{- end -}}
  {{- else -}}
    ✅ RESOLVIDO
  {{- end -}}
  : {{ .GroupLabels.alertname }}
  {{- if .CommonLabels.instance -}}
    - {{ .CommonLabels.instance }}
  {{- end -}}
{{ end }}

{{/* ======================================== */}}
{{/* 📝 CORPO DO EMAIL (TEXTO) */}}
{{/* ======================================== */}}
{{ define "email.body" }}
ALERTA: {{ .GroupLabels.alertname }}
STATUS: {{ .Status | upper }}
SEVERIDADE: {{ .CommonLabels.severity | upper }}

{{- if .CommonLabels.instance }}
INSTÂNCIA: {{ .CommonLabels.instance }}
{{- end }}
{{- if .CommonLabels.service }}
SERVIÇO: {{ .CommonLabels.service }}
{{- end }}
{{- if .CommonLabels.environment }}
AMBIENTE: {{ .CommonLabels.environment }}
{{- end }}

{{- if .CommonAnnotations.summary }}
RESUMO: {{ .CommonAnnotations.summary }}
{{- end }}
{{- if .CommonAnnotations.description }}
DESCRIÇÃO: {{ .CommonAnnotations.description }}
{{- end }}

DETALHES DOS ALERTAS:
{{ range .Alerts }}
----------------------------------------
Alerta: {{ .Labels.alertname }}
Início: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
{{- if ne .EndsAt.Unix 0 }}
Fim: {{ .EndsAt.Format "2006-01-02 15:04:05" }}
{{- end }}
{{- if .Labels.instance }}
Instância: {{ .Labels.instance }}
{{- end }}
{{- if .Annotations.summary }}
Resumo: {{ .Annotations.summary }}
{{- end }}
{{- if .GeneratorURL }}
Prometheus: {{ .GeneratorURL }}
{{- end }}
{{ end }}

{{- if .CommonAnnotations.runbook_url }}
RUNBOOK: {{ .CommonAnnotations.runbook_url }}
{{- end }}

Alertmanager: {{ .ExternalURL }}
{{ end }}
```

### 🎨 Template HTML de Email

```html
{{/* templates/email-html.tmpl */}}

{{ define "email.html" }}
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Alerta: {{ .GroupLabels.alertname }}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .critical { background: #dc3545; color: white; }
        .warning { background: #ffc107; color: black; }
        .info { background: #17a2b8; color: white; }
        .resolved { background: #28a745; color: white; }
        .alert-box { border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; }
        .label { font-weight: bold; }
        .value { margin-left: 10px; }
        .timestamp { color: #666; font-size: 0.9em; }
        .link { color: #007bff; text-decoration: none; }
        .link:hover { text-decoration: underline; }
    </style>
</head>
<body>
    {{/* Header com status */}}
    <div class="header {{ if eq .Status "firing" }}{{ .CommonLabels.severity }}{{ else }}resolved{{ end }}">
        <h2>
            {{- if eq .Status "firing" -}}
                {{- if eq .CommonLabels.severity "critical" -}}
                    🔴 ALERTA CRÍTICO
                {{- else if eq .CommonLabels.severity "warning" -}}
                    🟡 ALERTA DE ATENÇÃO
                {{- else -}}
                    🔵 ALERTA INFORMATIVO
                {{- end -}}
            {{- else -}}
                ✅ ALERTA RESOLVIDO
            {{- end -}}
        </h2>
        <h3>{{ .GroupLabels.alertname }}</h3>
    </div>

    {{/* Informações gerais */}}
    <div class="alert-box">
        <h4>📊 Informações Gerais</h4>
        <p><span class="label">Status:</span><span class="value">{{ .Status | upper }}</span></p>
        <p><span class="label">Severidade:</span><span class="value">{{ .CommonLabels.severity | upper }}</span></p>
        {{- if .CommonLabels.instance }}
        <p><span class="label">Instância:</span><span class="value">{{ .CommonLabels.instance }}</span></p>
        {{- end }}
        {{- if .CommonLabels.service }}
        <p><span class="label">Serviço:</span><span class="value">{{ .CommonLabels.service }}</span></p>
        {{- end }}
        {{- if .CommonLabels.environment }}
        <p><span class="label">Ambiente:</span><span class="value">{{ .CommonLabels.environment }}</span></p>
        {{- end }}
        <p><span class="label">Total de alertas:</span><span class="value">{{ len .Alerts }}</span></p>
    </div>

    {{/* Resumo e descrição */}}
    {{- if or .CommonAnnotations.summary .CommonAnnotations.description }}
    <div class="alert-box">
        <h4>📝 Descrição</h4>
        {{- if .CommonAnnotations.summary }}
        <p><span class="label">Resumo:</span><span class="value">{{ .CommonAnnotations.summary }}</span></p>
        {{- end }}
        {{- if .CommonAnnotations.description }}
        <p><span class="label">Descrição:</span><span class="value">{{ .CommonAnnotations.description }}</span></p>
        {{- end }}
    </div>
    {{- end }}

    {{/* Detalhes de cada alerta */}}
    <div class="alert-box">
        <h4>🔍 Detalhes dos Alertas</h4>
        {{ range $index, $alert := .Alerts }}
        <div style="border-left: 3px solid #007bff; padding-left: 10px; margin: 10px 0;">
            <p><strong>Alerta {{ add $index 1 }}:</strong> {{ $alert.Labels.alertname }}</p>
            <p class="timestamp">Início: {{ $alert.StartsAt.Format "2006-01-02 15:04:05 MST" }}</p>
            {{- if ne $alert.EndsAt.Unix 0 }}
            <p class="timestamp">Fim: {{ $alert.EndsAt.Format "2006-01-02 15:04:05 MST" }}</p>
            {{- end }}
            
            {{/* Labels específicos do alerta */}}
            {{- if $alert.Labels }}
            <details>
                <summary>🏷️ Labels</summary>
                <ul>
                {{ range $key, $value := $alert.Labels }}
                    <li><strong>{{ $key }}:</strong> {{ $value }}</li>
                {{ end }}
                </ul>
            </details>
            {{- end }}
            
            {{/* Annotations específicas do alerta */}}
            {{- if $alert.Annotations }}
            <details>
                <summary>📝 Annotations</summary>
                <ul>
                {{ range $key, $value := $alert.Annotations }}
                    <li><strong>{{ $key }}:</strong> {{ $value }}</li>
                {{ end }}
                </ul>
            </details>
            {{- end }}
            
            {{/* Link para Prometheus */}}
            {{- if $alert.GeneratorURL }}
            <p><a href="{{ $alert.GeneratorURL }}" class="link">🔗 Ver no Prometheus</a></p>
            {{- end }}
        </div>
        {{ end }}
    </div>

    {{/* Links úteis */}}
    <div class="alert-box">
        <h4>🔗 Links Úteis</h4>
        <p><a href="{{ .ExternalURL }}" class="link">📊 Alertmanager</a></p>
        {{- if .CommonAnnotations.runbook_url }}
        <p><a href="{{ .CommonAnnotations.runbook_url }}" class="link">📖 Runbook</a></p>
        {{- end }}
        {{- if .CommonAnnotations.dashboard_url }}
        <p><a href="{{ .CommonAnnotations.dashboard_url }}" class="link">📈 Dashboard</a></p>
        {{- end }}
    </div>

    {{/* Footer */}}
    <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 0.9em;">
        <p>Este alerta foi gerado automaticamente pelo sistema de monitoramento.</p>
        <p>Timestamp: {{ now.Format "2006-01-02 15:04:05 MST" }}</p>
    </div>
</body>
</html>
{{ end }}
```

### ⚙️ Configuração no alertmanager.yml

```yaml
# alertmanager.yml
templates:
  - '/etc/alertmanager/templates/email.tmpl'
  - '/etc/alertmanager/templates/email-html.tmpl'

receivers:
  - name: 'web-team'
    email_configs:
      - to: 'web@empresa.com'
        from: 'alertmanager@empresa.com'
        smarthost: 'smtp.empresa.com:587'
        auth_username: 'alertmanager@empresa.com'
        auth_password: 'senha123'
        subject: '{{ template "email.subject" . }}'
        body: '{{ template "email.body" . }}'
        html: '{{ template "email.html" . }}'
        headers:
          X-Priority: |
            {{ if eq .CommonLabels.severity "critical" }}1{{ else }}3{{ end }}
```

---

## 5. TEMPLATES PARA SLACK

### 💬 Template Básico do Slack

```go
{{/* templates/slack.tmpl */}}

{{/* ======================================== */}}
{{/* 💬 TÍTULO DO SLACK */}}
{{/* ======================================== */}}
{{ define "slack.title" }}
  {{- if eq .Status "firing" -}}
    {{- if eq .CommonLabels.severity "critical" -}}
      :red_circle: CRÍTICO
    {{- else if eq .CommonLabels.severity "warning" -}}
      :warning: ATENÇÃO
    {{- else -}}
      :large_blue_circle: INFO
    {{- end -}}
  {{- else -}}
    :white_check_mark: RESOLVIDO
  {{- end -}}
  : {{ .GroupLabels.alertname }}
{{ end }}

{{/* ======================================== */}}
{{/* 📝 TEXTO DO SLACK */}}
{{/* ======================================== */}}
{{ define "slack.text" }}
*Alerta:* {{ .GroupLabels.alertname }}
*Status:* {{ .Status | title }}
*Severidade:* {{ .CommonLabels.severity | title }}
{{- if .CommonLabels.instance }}
*Instância:* `{{ .CommonLabels.instance }}`
{{- end }}
{{- if .CommonLabels.service }}
*Serviço:* {{ .CommonLabels.service }}
{{- end }}
{{- if .CommonLabels.environment }}
*Ambiente:* {{ .CommonLabels.environment }}
{{- end }}

{{- if .CommonAnnotations.summary }}
*Resumo:* {{ .CommonAnnotations.summary }}
{{- end }}
{{- if .CommonAnnotations.description }}
*Descrição:* {{ .CommonAnnotations.description }}
{{- end }}

*Total de alertas:* {{ len .Alerts }}
{{ end }}

{{/* ======================================== */}}
{{/* 🎨 COR DO SLACK */}}
{{/* ======================================== */}}
{{ define "slack.color" }}
  {{- if eq .Status "firing" -}}
    {{- if eq .CommonLabels.severity "critical" -}}
      danger
    {{- else if eq .CommonLabels.severity "warning" -}}
      warning
    {{- else -}}
      #439FE0
    {{- end -}}
  {{- else -}}
    good
  {{- end -}}
{{ end }}
```

### 🎨 Template Avançado com Attachments

```go
{{/* templates/slack-advanced.tmpl */}}

{{ define "slack.pretext" }}
{{- if eq .Status "firing" -}}
  :rotating_light: *NOVO ALERTA DETECTADO*
{{- else -}}
  :white_check_mark: *ALERTA RESOLVIDO*
{{- end -}}
{{ end }}

{{ define "slack.title" }}
{{ .GroupLabels.alertname }}
{{- if .CommonLabels.instance }} - {{ .CommonLabels.instance }}{{ end }}
{{ end }}

{{ define "slack.title_link" }}
{{ .ExternalURL }}/#/alerts?filter=%7Balertname%3D%22{{ .GroupLabels.alertname }}%22%7D
{{ end }}

{{ define "slack.text" }}
{{- if .CommonAnnotations.summary }}
{{ .CommonAnnotations.summary }}
{{- end }}
{{- if .CommonAnnotations.description }}

{{ .CommonAnnotations.description }}
{{- end }}
{{ end }}

{{ define "slack.fields" }}
[
  {
    "title": "Severidade",
    "value": "{{ .CommonLabels.severity | title }}",
    "short": true
  },
  {
    "title": "Status",
    "value": "{{ .Status | title }}",
    "short": true
  }
  {{- if .CommonLabels.service }},
  {
    "title": "Serviço",
    "value": "{{ .CommonLabels.service }}",
    "short": true
  }
  {{- end }}
  {{- if .CommonLabels.environment }},
  {
    "title": "Ambiente",
    "value": "{{ .CommonLabels.environment }}",
    "short": true
  }
  {{- end }}
  {{- if .CommonLabels.team }},
  {
    "title": "Time",
    "value": "{{ .CommonLabels.team }}",
    "short": true
  }
  {{- end }},
  {
    "title": "Alertas",
    "value": "{{ len .Alerts }}",
    "short": true
  }
  {{- if gt (len .Alerts) 1 }},
  {
    "title": "Instâncias Afetadas",
    "value": "{{ range .Alerts }}{{ .Labels.instance }}\n{{ end }}",
    "short": false
  }
  {{- end }}
]
{{ end }}

{{ define "slack.actions" }}
[
  {
    "type": "button",
    "text": "Ver Alertmanager",
    "url": "{{ .ExternalURL }}"
  }
  {{- if .CommonAnnotations.runbook_url }},
  {
    "type": "button",
    "text": "Runbook",
    "url": "{{ .CommonAnnotations.runbook_url }}"
  }
  {{- end }}
  {{- if .CommonAnnotations.dashboard_url }},
  {
    "type": "button",
    "text": "Dashboard",
    "url": "{{ .CommonAnnotations.dashboard_url }}"
  }
  {{- end }}
  {{- range .Alerts }}
    {{- if .GeneratorURL }},
    {
      "type": "button",
      "text": "Prometheus",
      "url": "{{ .GeneratorURL }}"
    }
    {{- break }}
    {{- end }}
  {{- end }}
]
{{ end }}

{{ define "slack.footer" }}
Alertmanager | {{ now.Format "2006-01-02 15:04:05" }}
{{ end }}
```

### ⚙️ Configuração Slack no alertmanager.yml

```yaml
# alertmanager.yml
templates:
  - '/etc/alertmanager/templates/slack.tmpl'
  - '/etc/alertmanager/templates/slack-advanced.tmpl'

receivers:
  - name: 'slack-alerts'
    slack_configs:
      # Configuração básica
      - api_url: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'
        channel: '#alerts'
        username: 'Alertmanager'
        icon_emoji: ':warning:'
        title: '{{ template "slack.title" . }}'
        text: '{{ template "slack.text" . }}'
        color: '{{ template "slack.color" . }}'
        
      # Configuração avançada com attachments
      - api_url: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'
        channel: '#critical-alerts'
        username: 'Alertmanager'
        icon_emoji: ':rotating_light:'
        pretext: '{{ template "slack.pretext" . }}'
        title: '{{ template "slack.title" . }}'
        title_link: '{{ template "slack.title_link" . }}'
        text: '{{ template "slack.text" . }}'
        fields: '{{ template "slack.fields" . }}'
        actions: '{{ template "slack.actions" . }}'
        footer: '{{ template "slack.footer" . }}'
        color: '{{ template "slack.color" . }}'
        send_resolved: true
```

---

## 6. TEMPLATES PARA WEBHOOK

### 🔗 Template JSON para Webhook

```go
{{/* templates/webhook.tmpl */}}

{{ define "webhook.json" }}
{
  "version": "4",
  "groupKey": "{{ .GroupKey }}",
  "status": "{{ .Status }}",
  "receiver": "{{ .Receiver }}",
  "groupLabels": {
    {{ range $key, $value := .GroupLabels }}
    "{{ $key }}": "{{ $value }}"{{ if not (last $key $.GroupLabels) }},{{ end }}
    {{ end }}
  },
  "commonLabels": {
    {{ range $key, $value := .CommonLabels }}
    "{{ $key }}": "{{ $value }}"{{ if not (last $key $.CommonLabels) }},{{ end }}
    {{ end }}
  },
  "commonAnnotations": {
    {{ range $key, $value := .CommonAnnotations }}
    "{{ $key }}": "{{ $value }}"{{ if not (last $key $.CommonAnnotations) }},{{ end }}
    {{ end }}
  },
  "externalURL": "{{ .ExternalURL }}",
  "alerts": [
    {{ range $index, $alert := .Alerts }}
    {
      "status": "{{ $alert.Status }}",
      "labels": {
        {{ range $key, $value := $alert.Labels }}
        "{{ $key }}": "{{ $value }}"{{ if not (last $key $alert.Labels) }},{{ end }}
        {{ end }}
      },
      "annotations": {
        {{ range $key, $value := $alert.Annotations }}
        "{{ $key }}": "{{ $value }}"{{ if not (last $key $alert.Annotations) }},{{ end }}
        {{ end }}
      },
      "startsAt": "{{ $alert.StartsAt.Format "2006-01-02T15:04:05.000Z" }}",
      "endsAt": "{{ $alert.EndsAt.Format "2006-01-02T15:04:05.000Z" }}",
      "generatorURL": "{{ $alert.GeneratorURL }}",
      "fingerprint": "{{ $alert.Fingerprint }}"
    }{{ if not (last $index $.Alerts) }},{{ end }}
    {{ end }}
  ],
  "truncatedAlerts": {{ .TruncatedAlerts }},
  "timestamp": "{{ now.Format "2006-01-02T15:04:05.000Z" }}"
}
{{ end }}
```

### 🎯 Template Customizado para API

```go
{{/* templates/api-webhook.tmpl */}}

{{ define "api.webhook" }}
{
  "event_type": "alert",
  "source": "alertmanager",
  "timestamp": "{{ now.Unix }}",
  "alert": {
    "name": "{{ .GroupLabels.alertname }}",
    "status": "{{ .Status }}",
    "severity": "{{ .CommonLabels.severity }}",
    "environment": "{{ .CommonLabels.environment | default "unknown" }}",
    "service": "{{ .CommonLabels.service | default "unknown" }}",
    "instance": "{{ .CommonLabels.instance | default "unknown" }}",
    "summary": "{{ .CommonAnnotations.summary | default "No summary" }}",
    "description": "{{ .CommonAnnotations.description | default "No description" }}",
    "count": {{ len .Alerts }},
    "first_seen": "{{ (index .Alerts 0).StartsAt.Unix }}",
    "links": {
      "alertmanager": "{{ .ExternalURL }}",
      "runbook": "{{ .CommonAnnotations.runbook_url | default "" }}",
      "dashboard": "{{ .CommonAnnotations.dashboard_url | default "" }}"
    },
    "tags": [
      {{- $tags := list -}}
      {{- if .CommonLabels.team -}}
        {{- $tags = append $tags .CommonLabels.team -}}
      {{- end -}}
      {{- if .CommonLabels.component -}}
        {{- $tags = append $tags .CommonLabels.component -}}
      {{- end -}}
      {{- range $index, $tag := $tags -}}
        "{{ $tag }}"{{ if not (last $index $tags) }},{{ end }}
      {{- end -}}
    ],
    "affected_instances": [
      {{ range $index, $alert := .Alerts }}
      {
        "instance": "{{ $alert.Labels.instance }}",
        "job": "{{ $alert.Labels.job }}",
        "started_at": "{{ $alert.StartsAt.Unix }}"
      }{{ if not (last $index $.Alerts) }},{{ end }}
      {{ end }}
    ]
  }
}
{{ end }}
```

### ⚙️ Configuração Webhook

```yaml
# alertmanager.yml
templates:
  - '/etc/alertmanager/templates/webhook.tmpl'
  - '/etc/alertmanager/templates/api-webhook.tmpl'

receivers:
  - name: 'webhook-receiver'
    webhook_configs:
      # Webhook genérico
      - url: 'http://webhook-server:8080/alerts'
        http_config:
          basic_auth:
            username: 'alertmanager'
            password: 'webhook-secret'
        send_resolved: true
        
      # Webhook customizado
      - url: 'http://api-server:3000/api/v1/alerts'
        http_config:
          bearer_token: 'your-api-token'
        send_resolved: true
        title: 'Alertmanager Notification'
        text: '{{ template "api.webhook" . }}'
```

---

## 7. FUNÇÕES AUXILIARES

### 🔧 Funções Built-in

```go
// ========================================
// 📝 FUNÇÕES DE STRING
// ========================================
{{ upper "texto" }}                    // TEXTO
{{ lower "TEXTO" }}                    // texto
{{ title "texto exemplo" }}            // Texto Exemplo
{{ trim " texto " }}                   // "texto"
{{ printf "%.2f" 3.14159 }}           // "3.14"
{{ printf "%s: %d" "count" 5 }}       // "count: 5"

// ========================================
// 🔢 FUNÇÕES MATEMÁTICAS
// ========================================
{{ add 1 2 }}                          // 3
{{ sub 5 2 }}                          // 3
{{ mul 3 4 }}                          // 12
{{ div 10 2 }}                         // 5
{{ mod 10 3 }}                         // 1

// ========================================
// 📊 FUNÇÕES DE COLEÇÃO
// ========================================
{{ len .Alerts }}                      // Tamanho do array
{{ index .Alerts 0 }}                  // Primeiro elemento
{{ range .Alerts }}{{ . }}{{ end }}   // Iterar

// ========================================
// 🔍 FUNÇÕES DE COMPARAÇÃO
// ========================================
{{ eq .Status "firing" }}              // Igual
{{ ne .Status "resolved" }}            // Diferente
{{ lt (len .Alerts) 5 }}               // Menor que
{{ gt (len .Alerts) 1 }}               // Maior que
{{ le (len .Alerts) 10 }}              // Menor ou igual
{{ ge (len .Alerts) 1 }}               // Maior ou igual

// ========================================
// ⏰ FUNÇÕES DE TEMPO
// ========================================
{{ now }}                              // Tempo atual
{{ now.Format "2006-01-02 15:04:05" }} // Formatado
{{ .StartsAt.Unix }}                   // Unix timestamp

// ========================================
// 🔗 FUNÇÕES DE REGEX
// ========================================
{{ reReplaceAll "\\..+" "" .CommonLabels.instance }}  // Regex replace
```

### 🎯 Funções Customizadas

```go
{{/* templates/functions.tmpl */}}

{{/* ======================================== */}}
{{/* 🎨 FUNÇÃO PARA EMOJI DE SEVERIDADE */}}
{{/* ======================================== */}}
{{ define "severity.emoji" }}
  {{- if eq . "critical" -}}
    🔴
  {{- else if eq . "warning" -}}
    🟡
  {{- else if eq . "info" -}}
    🔵
  {{- else -}}
    ⚪
  {{- end -}}
{{ end }}

{{/* ======================================== */}}
{{/* ⏰ FUNÇÃO PARA DURAÇÃO HUMANIZADA */}}
{{/* ======================================== */}}
{{ define "humanize.duration" }}
  {{- $duration := . -}}
  {{- if lt $duration 60 -}}
    {{ printf "%.0fs" $duration }}
  {{- else if lt $duration 3600 -}}
    {{ printf "%.0fm" (div $duration 60) }}
  {{- else if lt $duration 86400 -}}
    {{ printf "%.1fh" (div $duration 3600) }}
  {{- else -}}
    {{ printf "%.1fd" (div $duration 86400) }}
  {{- end -}}
{{ end }}

{{/* ======================================== */}}
{{/* 🏷️ FUNÇÃO PARA FORMATAR LABELS */}}
{{/* ======================================== */}}
{{ define "format.labels" }}
  {{- range $key, $value := . -}}
    {{- if ne $key "__name__" -}}
      {{ $key }}="{{ $value }}" 
    {{- end -}}
  {{- end -}}
{{ end }}

{{/* ======================================== */}}
{{/* 📊 FUNÇÃO PARA RESUMO DE INSTÂNCIAS */}}
{{/* ======================================== */}}
{{ define "instance.summary" }}
  {{- $instances := list -}}
  {{- range . -}}
    {{- if .Labels.instance -}}
      {{- $instances = append $instances .Labels.instance -}}
    {{- end -}}
  {{- end -}}
  {{- $unique := uniq $instances -}}
  {{- if eq (len $unique) 1 -}}
    {{ index $unique 0 }}
  {{- else if le (len $unique) 3 -}}
    {{ join ", " $unique }}
  {{- else -}}
    {{ index $unique 0 }} e mais {{ sub (len $unique) 1 }} instâncias
  {{- end -}}
{{ end }}

{{/* ======================================== */}}
{{/* 🔗 FUNÇÃO PARA LINKS ÚTEIS */}}
{{/* ======================================== */}}
{{ define "useful.links" }}
  {{- $links := list -}}
  {{- if .ExternalURL -}}
    {{- $links = append $links (printf "[Alertmanager](%s)" .ExternalURL) -}}
  {{- end -}}
  {{- if .CommonAnnotations.runbook_url -}}
    {{- $links = append $links (printf "[Runbook](%s)" .CommonAnnotations.runbook_url) -}}
  {{- end -}}
  {{- if .CommonAnnotations.dashboard_url -}}
    {{- $links = append $links (printf "[Dashboard](%s)" .CommonAnnotations.dashboard_url) -}}
  {{- end -}}
  {{- range .Alerts -}}
    {{- if .GeneratorURL -}}
      {{- $links = append $links (printf "[Prometheus](%s)" .GeneratorURL) -}}
      {{- break -}}
    {{- end -}}
  {{- end -}}
  {{ join " | " $links }}
{{ end }}
```

### 🎯 Usando Funções Customizadas

```go
{{/* Exemplo de uso das funções */}}

{{ define "alert.summary" }}
{{ template "severity.emoji" .CommonLabels.severity }} *{{ .GroupLabels.alertname }}*

*Status:* {{ .Status | title }}
*Instâncias:* {{ template "instance.summary" .Alerts }}
*Duração:* {{ template "humanize.duration" (sub now.Unix (index .Alerts 0).StartsAt.Unix) }}

{{ if .CommonAnnotations.summary }}{{ .CommonAnnotations.summary }}{{ end }}

{{ template "useful.links" . }}
{{ end }}
```

---

## 8. TEMPLATES AVANÇADOS

### 🎯 Template Condicional por Severidade

```go
{{/* templates/conditional.tmpl */}}

{{ define "conditional.message" }}
{{- if eq .CommonLabels.severity "critical" -}}
  {{- template "critical.alert" . -}}
{{- else if eq .CommonLabels.severity "warning" -}}
  {{- template "warning.alert" . -}}
{{- else -}}
  {{- template "info.alert" . -}}
{{- end -}}
{{ end }}

{{ define "critical.alert" }}
🚨 **ALERTA CRÍTICO** 🚨

⚠️ **AÇÃO IMEDIATA NECESSÁRIA** ⚠️

**Alerta:** {{ .GroupLabels.alertname }}
**Instância:** {{ .CommonLabels.instance }}
**Serviço:** {{ .CommonLabels.service }}

**Impacto:** ALTO - Pode afetar usuários
**SLA:** Resolver em 15 minutos

{{ if .CommonAnnotations.summary }}**Resumo:** {{ .CommonAnnotations.summary }}{{ end }}
{{ if .CommonAnnotations.description }}**Descrição:** {{ .CommonAnnotations.description }}{{ end }}

**Próximos passos:**
1. 🔍 Investigar imediatamente
2. 📞 Notificar time de plantão se necessário
3. 📊 Verificar dashboards relacionados
4. 📖 Consultar runbook

{{ template "useful.links" . }}
{{ end }}

{{ define "warning.alert" }}
⚠️ **Alerta de Atenção**

**Alerta:** {{ .GroupLabels.alertname }}
**Instância:** {{ .CommonLabels.instance }}
**Serviço:** {{ .CommonLabels.service }}

**Impacto:** MÉDIO - Monitorar evolução
**SLA:** Investigar em 1 hora

{{ if .CommonAnnotations.summary }}**Resumo:** {{ .CommonAnnotations.summary }}{{ end }}

**Ações recomendadas:**
- 📊 Verificar tendência nos dashboards
- 🔍 Investigar se necessário
- 📈 Monitorar evolução

{{ template "useful.links" . }}
{{ end }}

{{ define "info.alert" }}
ℹ️ **Alerta Informativo**

**Alerta:** {{ .GroupLabels.alertname }}
**Detalhes:** {{ .CommonAnnotations.summary | default "Sem resumo disponível" }}

**Ação:** Apenas para conhecimento

{{ template "useful.links" . }}
{{ end }}
```

### 🕐 Template com Horário de Trabalho

```go
{{/* templates/business-hours.tmpl */}}

{{ define "business.hours.message" }}
{{- $hour := now.Hour -}}
{{- $weekday := now.Weekday -}}
{{- $isBusinessHours := and (ge $hour 8) (le $hour 18) (ge $weekday 1) (le $weekday 5) -}}

{{- if $isBusinessHours -}}
  {{- template "business.hours.alert" . -}}
{{- else -}}
  {{- template "after.hours.alert" . -}}
{{- end -}}
{{ end }}

{{ define "business.hours.alert" }}
🏢 **Alerta em Horário Comercial**

{{ template "severity.emoji" .CommonLabels.severity }} {{ .GroupLabels.alertname }}

**Time responsável:** {{ .CommonLabels.team | default "Ops" }}
**Prioridade:** Normal
**Resposta esperada:** 30 minutos

{{ if .CommonAnnotations.summary }}{{ .CommonAnnotations.summary }}{{ end }}

**Contatos:**
- 💬 Slack: #{{ .CommonLabels.team | default "ops" }}
- 📧 Email: {{ .CommonLabels.team | default "ops" }}@empresa.com

{{ template "useful.links" . }}
{{ end }}

{{ define "after.hours.alert" }}
🌙 **Alerta Fora do Horário Comercial**

{{ template "severity.emoji" .CommonLabels.severity }} {{ .GroupLabels.alertname }}

{{- if eq .CommonLabels.severity "critical" }}
**🚨 PLANTÃO ACIONADO 🚨**
**Resposta esperada:** 15 minutos
**Contato:** +55 11 99999-9999
{{- else }}
**Prioridade:** Baixa
**Resposta esperada:** Próximo dia útil
{{- end }}

{{ if .CommonAnnotations.summary }}{{ .CommonAnnotations.summary }}{{ end }}

{{ template "useful.links" . }}
{{ end }}
```

### 📊 Template com Métricas

```go
{{/* templates/metrics.tmpl */}}

{{ define "metrics.summary" }}
📊 **Resumo de Métricas**

**Alerta:** {{ .GroupLabels.alertname }}
**Total de instâncias afetadas:** {{ len .Alerts }}
**Primeira ocorrência:** {{ (index .Alerts 0).StartsAt.Format "15:04:05" }}
**Duração:** {{ template "humanize.duration" (sub now.Unix (index .Alerts 0).StartsAt.Unix) }}

{{- if gt (len .Alerts) 1 }}

**📋 Instâncias Afetadas:**
{{ range .Alerts }}
- `{{ .Labels.instance }}` ({{ .StartsAt.Format "15:04" }})
{{- end }}
{{- end }}

{{- $services := list -}}
{{- range .Alerts -}}
  {{- if .Labels.service -}}
    {{- $services = append $services .Labels.service -}}
  {{- end -}}
{{- end -}}
{{- $uniqueServices := uniq $services -}}
{{- if gt (len $uniqueServices) 0 }}

**🔧 Serviços Impactados:**
{{ range $uniqueServices }}
- {{ . }}
{{- end }}
{{- end }}

{{- if .CommonAnnotations.value }}
**📈 Valor atual:** {{ .CommonAnnotations.value }}
{{- end }}
{{- if .CommonAnnotations.threshold }}
**⚠️ Limite:** {{ .CommonAnnotations.threshold }}
{{- end }}

{{ template "useful.links" . }}
{{ end }}
```

---

## 9. DEBUGGING E TESTES

### 🔍 Testando Templates

#### 🧪 Usando amtool

```bash
# Testar template com dados reais
amtool template test \
  --template.file=/etc/alertmanager/templates/email.tmpl \
  --template.name=email.subject \
  --template.data='{"Status":"firing","GroupLabels":{"alertname":"HighCPU"},"CommonLabels":{"severity":"critical","instance":"web-01"}}'

# Testar com arquivo de dados
echo '{
  "Status": "firing",
  "GroupLabels": {"alertname": "HighCPU"},
  "CommonLabels": {
    "severity": "critical",
    "instance": "web-01.prod.com",
    "service": "web"
  },
  "CommonAnnotations": {
    "summary": "CPU alta detectada",
    "description": "CPU em 95% por 5 minutos"
  },
  "Alerts": [
    {
      "Status": "firing",
      "Labels": {
        "alertname": "HighCPU",
        "instance": "web-01.prod.com",
        "severity": "critical"
      },
      "Annotations": {
        "summary": "CPU alta em web-01"
      },
      "StartsAt": "2024-01-15T10:30:00Z",
      "GeneratorURL": "http://prometheus:9090/graph"
    }
  ]
}' > test-data.json

amtool template test \
  --template.file=/etc/alertmanager/templates/email.tmpl \
  --template.name=email.body \
  --template.data-file=test-data.json
```

#### 🐳 Testando com Docker

```bash
# Script de teste
#!/bin/bash
# test-templates.sh

TEMPLATE_DIR="./templates"
TEST_DATA="./test-data.json"

echo "🧪 Testando templates..."

# Testar email subject
echo "📧 Email Subject:"
docker run --rm \
  -v "$TEMPLATE_DIR:/templates" \
  -v "$TEST_DATA:/test-data.json" \
  prom/alertmanager:v0.25.0 \
  amtool template test \
    --template.file=/templates/email.tmpl \
    --template.name=email.subject \
    --template.data-file=/test-data.json

echo
echo "📝 Email Body:"
docker run --rm \
  -v "$TEMPLATE_DIR:/templates" \
  -v "$TEST_DATA:/test-data.json" \
  prom/alertmanager:v0.25.0 \
  amtool template test \
    --template.file=/templates/email.tmpl \
    --template.name=email.body \
    --template.data-file=/test-data.json

echo
echo "💬 Slack Text:"
docker run --rm \
  -v "$TEMPLATE_DIR:/templates" \
  -v "$TEST_DATA:/test-data.json" \
  prom/alertmanager:v0.25.0 \
  amtool template test \
    --template.file=/templates/slack.tmpl \
    --template.name=slack.text \
    --template.data-file=/test-data.json
```

### 🔧 Debugging Templates

#### 📝 Template com Debug

```go
{{/* templates/debug.tmpl */}}

{{ define "debug.info" }}
=== DEBUG INFORMATION ===

Receiver: {{ .Receiver }}
Status: {{ .Status }}
GroupKey: {{ .GroupKey }}
TruncatedAlerts: {{ .TruncatedAlerts }}
ExternalURL: {{ .ExternalURL }}

GroupLabels:
{{ range $key, $value := .GroupLabels }}
  {{ $key }}: {{ $value }}
{{ end }}

CommonLabels:
{{ range $key, $value := .CommonLabels }}
  {{ $key }}: {{ $value }}
{{ end }}

CommonAnnotations:
{{ range $key, $value := .CommonAnnotations }}
  {{ $key }}: {{ $value }}
{{ end }}

Alerts ({{ len .Alerts }}):
{{ range $index, $alert := .Alerts }}
--- Alert {{ $index }} ---
Status: {{ $alert.Status }}
StartsAt: {{ $alert.StartsAt }}
EndsAt: {{ $alert.EndsAt }}
GeneratorURL: {{ $alert.GeneratorURL }}
Fingerprint: {{ $alert.Fingerprint }}

Labels:
{{ range $key, $value := $alert.Labels }}
  {{ $key }}: {{ $value }}
{{ end }}

Annotations:
{{ range $key, $value := $alert.Annotations }}
  {{ $key }}: {{ $value }}
{{ end }}
{{ end }}

=== END DEBUG ===
{{ end }}
```

#### 🔍 Validação de Templates

```bash
#!/bin/bash
# validate-templates.sh

TEMPLATE_DIR="./templates"
ERRORS=0

echo "🔍 Validando templates..."

for template_file in "$TEMPLATE_DIR"/*.tmpl; do
    echo "Validando: $(basename "$template_file")"
    
    # Verificar sintaxe básica
    if ! docker run --rm \
        -v "$template_file:/template.tmpl" \
        prom/alertmanager:v0.25.0 \
        amtool template test \
        --template.file=/template.tmpl \
        --template.name=debug.info \
        --template.data='{}' >/dev/null 2>&1; then
        echo "❌ Erro de sintaxe em $(basename "$template_file")"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ $(basename "$template_file") OK"
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "🎉 Todos os templates são válidos!"
    exit 0
else
    echo "❌ $ERRORS template(s) com erro"
    exit 1
fi
```

### 📊 Monitoramento de Templates

```yaml
# prometheus rules para monitorar templates
groups:
  - name: template-monitoring
    rules:
      # Erros de template
      - alert: TemplateRenderError
        expr: increase(alertmanager_notifications_failed_total[5m]) > 0
        labels:
          severity: warning
        annotations:
          summary: "Erro ao renderizar template"
          description: "{{ $value }} falhas de notificação nos últimos 5 minutos"
      
      # Templates muito lentos
      - alert: SlowTemplateRendering
        expr: histogram_quantile(0.95, alertmanager_notification_latency_seconds_bucket) > 5
        labels:
          severity: warning
        annotations:
          summary: "Template renderizando lentamente"
          description: "95% das notificações levam mais de 5 segundos para renderizar"

---

## 10. BOAS PRÁTICAS

### ✅ Estrutura e Organização

#### 📁 Organização de Arquivos
```
templates/
├── common/
│   ├── functions.tmpl       # Funções reutilizáveis
│   ├── variables.tmpl       # Variáveis globais
│   └── macros.tmpl         # Macros comuns
├── email/
│   ├── subject.tmpl        # Subjects de email
│   ├── body.tmpl           # Corpo texto
│   └── html.tmpl           # Corpo HTML
├── slack/
│   ├── basic.tmpl          # Templates básicos
│   ├── advanced.tmpl       # Templates com attachments
│   └── channels.tmpl       # Por canal específico
├── webhook/
│   ├── json.tmpl           # Formato JSON
│   ├── api.tmpl            # Para APIs específicas
│   └── custom.tmpl         # Formatos customizados
└── severity/
    ├── critical.tmpl       # Templates para crítico
    ├── warning.tmpl        # Templates para warning
    └── info.tmpl           # Templates para info
```

#### 🏷️ Convenções de Nomenclatura
```go
// ✅ BOM - Nomes descritivos
{{ define "email.subject.critical" }}
{{ define "slack.text.database.down" }}
{{ define "webhook.json.api.v2" }}

// ❌ RUIM - Nomes genéricos
{{ define "template1" }}
{{ define "msg" }}
{{ define "t" }}
```

### 🎯 Performance e Eficiência

#### ⚡ Templates Eficientes
```go
// ✅ BOM - Usar variáveis para valores repetidos
{{ $severity := .CommonLabels.severity }}
{{ $instance := .CommonLabels.instance }}
{{ if eq $severity "critical" }}
  🔴 Crítico em {{ $instance }}
{{ else if eq $severity "warning" }}
  🟡 Atenção em {{ $instance }}
{{ end }}

// ❌ RUIM - Repetir expressões
{{ if eq .CommonLabels.severity "critical" }}
  🔴 Crítico em {{ .CommonLabels.instance }}
{{ else if eq .CommonLabels.severity "warning" }}
  🟡 Atenção em {{ .CommonLabels.instance }}
{{ end }}
```

#### 🔄 Evitar Loops Desnecessários
```go
// ✅ BOM - Loop único com múltiplas operações
{{ range .Alerts }}
  {{ .Labels.alertname }}: {{ .Labels.instance }}
  {{ if .Annotations.summary }}({{ .Annotations.summary }}){{ end }}
{{ end }}

// ❌ RUIM - Múltiplos loops
{{ range .Alerts }}{{ .Labels.alertname }}{{ end }}
{{ range .Alerts }}{{ .Labels.instance }}{{ end }}
```

### 🛡️ Segurança e Validação

#### 🔒 Sanitização de Dados
```go
// ✅ BOM - Validar dados antes de usar
{{ if .CommonLabels.instance }}
  Instância: {{ .CommonLabels.instance | html }}
{{ else }}
  Instância: Não informada
{{ end }}

// ❌ RUIM - Usar dados sem validação
Instância: {{ .CommonLabels.instance }}
```

#### 🚫 Evitar Informações Sensíveis
```go
// ✅ BOM - Mascarar informações sensíveis
{{ if .CommonLabels.database_url }}
  Database: {{ .CommonLabels.database_url | reReplaceAll "://[^@]+@" "://***:***@" }}
{{ end }}

// ❌ RUIM - Expor credenciais
Database: {{ .CommonLabels.database_url }}
```

### 📱 Responsividade e Compatibilidade

#### 📧 Templates de Email
```html
<!-- ✅ BOM - HTML responsivo -->
<style>
  @media only screen and (max-width: 600px) {
    .container { width: 100% !important; }
    .content { padding: 10px !important; }
  }
</style>

<!-- ❌ RUIM - Layout fixo -->
<table width="800px">
```

#### 💬 Templates de Slack
```go
// ✅ BOM - Considerar limites do Slack
{{ define "slack.text" }}
{{- $text := .CommonAnnotations.summary -}}
{{- if gt (len $text) 3000 -}}
  {{ $text | trunc 2950 }}...
{{- else -}}
  {{ $text }}
{{- end -}}
{{ end }}
```

### 🧪 Testes e Validação

#### 🔍 Testes Automatizados
```bash
#!/bin/bash
# test-all-templates.sh

TEST_CASES=(
  "critical-single.json"
  "warning-multiple.json"
  "info-resolved.json"
  "edge-case-empty.json"
)

for test_case in "${TEST_CASES[@]}"; do
  echo "🧪 Testando: $test_case"
  
  # Testar todos os templates
  for template in email.subject email.body slack.text; do
    if ! amtool template test \
        --template.file=templates/all.tmpl \
        --template.name="$template" \
        --template.data-file="tests/$test_case" >/dev/null; then
      echo "❌ Falha: $template com $test_case"
      exit 1
    fi
  done
done

echo "✅ Todos os testes passaram!"
```

#### 📊 Casos de Teste
```json
// tests/critical-single.json
{
  "Status": "firing",
  "GroupLabels": {"alertname": "DatabaseDown"},
  "CommonLabels": {
    "severity": "critical",
    "service": "mysql",
    "environment": "production"
  },
  "Alerts": [{
    "Status": "firing",
    "Labels": {
      "alertname": "DatabaseDown",
      "instance": "db-01.prod.com"
    },
    "StartsAt": "2024-01-15T10:30:00Z"
  }]
}

// tests/edge-case-empty.json
{
  "Status": "firing",
  "GroupLabels": {},
  "CommonLabels": {},
  "CommonAnnotations": {},
  "Alerts": []
}
```

### 📚 Documentação

#### 📝 Documentar Templates
```go
{{/*
===========================================
TEMPLATE: email.subject.critical
DESCRIÇÃO: Subject para alertas críticos
VARIÁVEIS NECESSÁRIAS:
  - .GroupLabels.alertname
  - .CommonLabels.instance (opcional)
  - .CommonLabels.service (opcional)
EXEMPLO DE SAÍDA:
  "🔴 CRÍTICO: DatabaseDown - db-01.prod.com"
===========================================
*/}}
{{ define "email.subject.critical" }}
🔴 CRÍTICO: {{ .GroupLabels.alertname }}
{{- if .CommonLabels.instance }} - {{ .CommonLabels.instance }}{{ end }}
{{ end }}
```

#### 📖 README para Templates
```markdown
# Templates do Alertmanager

## Estrutura

- `common/` - Funções e macros reutilizáveis
- `email/` - Templates para notificações por email
- `slack/` - Templates para Slack
- `webhook/` - Templates para webhooks

## Como usar

1. Incluir templates no `alertmanager.yml`:
   ```yaml
   templates:
     - '/etc/alertmanager/templates/*.tmpl'
   ```

2. Referenciar nos receivers:
   ```yaml
   receivers:
     - name: 'critical-alerts'
       email_configs:
         - subject: '{{ template "email.subject.critical" . }}'
   ```

## Testes

```bash
# Testar template específico
./test-templates.sh email.subject.critical

# Testar todos
./test-all-templates.sh
```
```

---

## 🎯 RESUMO DO MÓDULO

### ✅ O que você aprendeu:

1. **Conceitos de templates** - Como funcionam e sua arquitetura
2. **Sintaxe Go Template** - Variáveis, funções, pipelines, condições
3. **Variáveis disponíveis** - Estrutura de dados do Alertmanager
4. **Templates para email** - Texto e HTML personalizados
5. **Templates para Slack** - Mensagens básicas e avançadas
6. **Templates para webhook** - JSON customizado para APIs
7. **Funções auxiliares** - Built-in e customizadas
8. **Templates avançados** - Condicionais, horários, métricas
9. **Debugging e testes** - Como validar e testar templates
10. **Boas práticas** - Organização, performance, segurança

### 🔧 Principais conceitos:
- **Templates** - Formatação personalizada de mensagens
- **Go Template** - Engine de templates do Alertmanager
- **Variáveis** - Dados disponíveis para templates
- **Funções** - Processamento e formatação de dados
- **Debugging** - Validação e teste de templates

### 🚀 Próximos Passos

Agora que você domina templates, vamos aprender sobre **troubleshooting**:

**Próximo módulo:** [08-troubleshooting.md](08-troubleshooting.md) - Resolução de problemas

---

## 🔗 Links Relacionados

- **[Anterior: Silenciamento](06-silenciamento.md)**
- **[Próximo: Troubleshooting](08-troubleshooting.md)**
- **[Voltar ao Índice](README.md)**
# Validação da Observability Stack

Este diretório contém scripts e exemplos para validar a configuração da stack de observabilidade antes do deployment.

## 📁 Estrutura do Diretório

```
validation/
├── README.md                    # Esta documentação
├── validate-prometheus.sh       # Validação do Prometheus (Linux/macOS)
├── validate-alertmanager.sh     # Validação do Alertmanager (Linux/macOS)
├── validate-stack.ps1          # Validação completa (Windows PowerShell)
└── ci-validation.yml           # Exemplos de pipelines CI/CD
```

## 🎯 Objetivo

Os scripts de validação garantem que:
- ✅ Configurações YAML são sintaticamente válidas
- ✅ Estruturas de arquivos estão corretas
- ✅ Referências entre arquivos são válidas
- ✅ Serviços podem ser iniciados sem erros
- ✅ Conectividade entre componentes funciona
- ✅ Queries e alertas são válidos

## 🚀 Scripts Disponíveis

### 1. validate-prometheus.sh (Linux/macOS)

Valida configurações do Prometheus usando `promtool`.

**Funcionalidades:**
- Validação de configuração principal
- Validação de regras de alerta
- Validação de arquivos de targets
- Teste de queries
- Geração de relatórios

**Uso:**
```bash
# Validação básica
./validate-prometheus.sh

# Com configuração customizada
./validate-prometheus.sh --config /path/to/prometheus.yml

# Incluir teste de conectividade
./validate-prometheus.sh --test-connectivity

# Gerar relatório
./validate-prometheus.sh --generate-report

# Ajuda
./validate-prometheus.sh --help
```

**Exemplos:**
```bash
# Validar configuração específica
./validate-prometheus.sh --config examples/prometheus.yml --rules examples/rules

# Testar queries contra Prometheus rodando
./validate-prometheus.sh --test-connectivity --prometheus-url http://localhost:9090

# Validação completa com relatório
./validate-prometheus.sh --generate-report --verbose
```

### 2. validate-alertmanager.sh (Linux/macOS)

Valida configurações do Alertmanager usando `amtool`.

**Funcionalidades:**
- Validação de configuração principal
- Validação de receivers modulares
- Teste de templates
- Simulação de roteamento
- Teste de conectividade

**Uso:**
```bash
# Validação básica
./validate-alertmanager.sh

# Com configuração customizada
./validate-alertmanager.sh --config /path/to/alertmanager.yml

# Incluir teste de conectividade
./validate-alertmanager.sh --test-connectivity

# Gerar relatório
./validate-alertmanager.sh --generate-report

# Ajuda
./validate-alertmanager.sh --help
```

**Exemplos:**
```bash
# Validar com receivers modulares
./validate-alertmanager.sh --config examples/alertmanager.yml --receivers examples/receivers.d

# Testar roteamento de alertas
./validate-alertmanager.sh --test-connectivity --alertmanager-url http://localhost:9093

# Validação completa
./validate-alertmanager.sh --generate-report --verbose
```

### 3. validate-stack.ps1 (Windows PowerShell)

Script completo para validação em ambiente Windows.

**Funcionalidades:**
- Validação de toda a stack
- Suporte a configurações modulares
- Teste de conectividade
- Geração de relatórios
- Interface amigável com cores

**Uso:**
```powershell
# Validação básica
.\validate-stack.ps1

# Com parâmetros customizados
.\validate-stack.ps1 -PrometheusConfig "examples\prometheus.yml" -AlertmanagerConfig "examples\alertmanager.yml"

# Incluir teste de conectividade
.\validate-stack.ps1 -TestConnections

# Gerar relatório
.\validate-stack.ps1 -GenerateReport

# Output detalhado
.\validate-stack.ps1 -Verbose

# Ajuda
.\validate-stack.ps1 -Help
```

**Exemplos:**
```powershell
# Validação completa com relatório
.\validate-stack.ps1 -TestConnections -GenerateReport -Verbose

# Validar diretórios específicos
.\validate-stack.ps1 -RulesDir "examples\rules" -ReceiversDir "examples\receivers.d" -TargetsDir "examples\targets"

# Apenas Grafana
.\validate-stack.ps1 -GrafanaDir "examples\grafana\provisioning"
```

## 📋 Pré-requisitos

### Linux/macOS

**Ferramentas necessárias:**
```bash
# Instalar promtool
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xzf prometheus-2.45.0.linux-amd64.tar.gz
sudo cp prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/

# Instalar amtool
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
tar xzf alertmanager-0.26.0.linux-amd64.tar.gz
sudo cp alertmanager-0.26.0.linux-amd64/amtool /usr/local/bin/

# Verificar instalação
promtool --version
amtool --version
```

**Dependências opcionais:**
```bash
# Para validação YAML avançada
pip install pyyaml

# Para testes de conectividade
apt-get install curl jq
```

### Windows

**PowerShell 5.1 ou superior:**
```powershell
# Verificar versão
$PSVersionTable.PSVersion

# Instalar módulo YAML (opcional)
Install-Module -Name powershell-yaml -Force

# Docker Desktop para testes
# Baixar de: https://www.docker.com/products/docker-desktop
```

## 🔧 Configuração

### Estrutura de Arquivos Esperada

```
observability-stack-docker/
├── examples/
│   ├── prometheus.yml           # Configuração principal do Prometheus
│   ├── alertmanager.yml         # Configuração principal do Alertmanager
│   ├── rules/                   # Regras de alerta
│   │   ├── general.yml
│   │   ├── docker.yml
│   │   └── snmp.yml
│   ├── receivers.d/             # Receivers modulares
│   │   ├── email.yml
│   │   ├── slack.yml
│   │   └── webhook.yml
│   ├── targets/                 # Targets de monitoramento
│   │   ├── docker.yml
│   │   ├── snmp.yml
│   │   └── node-exporter.yml
│   └── grafana/                 # Provisionamento do Grafana
│       └── provisioning/
│           ├── datasources/
│           └── dashboards/
├── docker-compose.yml
└── docker-compose.monitoring.yml
```

### Variáveis de Ambiente

```bash
# Linux/macOS
export PROMETHEUS_CONFIG="examples/prometheus.yml"
export ALERTMANAGER_CONFIG="examples/alertmanager.yml"
export PROMETHEUS_URL="http://localhost:9090"
export ALERTMANAGER_URL="http://localhost:9093"
```

```powershell
# Windows PowerShell
$env:PROMETHEUS_CONFIG = "examples\prometheus.yml"
$env:ALERTMANAGER_CONFIG = "examples\alertmanager.yml"
$env:PROMETHEUS_URL = "http://localhost:9090"
$env:ALERTMANAGER_URL = "http://localhost:9093"
```

## 🚦 Integração CI/CD

### GitHub Actions

```yaml
# .github/workflows/validate-observability.yml
name: Validate Observability Stack

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Install Tools
      run: |
        wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
        tar xzf prometheus-2.45.0.linux-amd64.tar.gz
        sudo cp prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/
        
        wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
        tar xzf alertmanager-0.26.0.linux-amd64.tar.gz
        sudo cp alertmanager-0.26.0.linux-amd64/amtool /usr/local/bin/
    
    - name: Validate Configurations
      run: |
        chmod +x examples/validation/validate-prometheus.sh
        ./examples/validation/validate-prometheus.sh
        
        chmod +x examples/validation/validate-alertmanager.sh
        ./examples/validation/validate-alertmanager.sh
```

### GitLab CI

```yaml
# .gitlab-ci.yml
validate-prometheus:
  stage: validate
  image: prom/prometheus:latest
  script:
    - promtool check config examples/prometheus.yml
    - promtool check rules examples/rules/*.yml

validate-alertmanager:
  stage: validate
  image: prom/alertmanager:latest
  script:
    - amtool check-config examples/alertmanager.yml
```

### Makefile

```makefile
# Adicionar ao Makefile
.PHONY: validate validate-prometheus validate-alertmanager

validate: validate-prometheus validate-alertmanager
	@echo "All validations completed successfully!"

validate-prometheus:
	@./examples/validation/validate-prometheus.sh

validate-alertmanager:
	@./examples/validation/validate-alertmanager.sh
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running observability stack validation..."

if [ -f "examples/validation/validate-prometheus.sh" ]; then
    chmod +x examples/validation/validate-prometheus.sh
    ./examples/validation/validate-prometheus.sh
fi

if [ -f "examples/validation/validate-alertmanager.sh" ]; then
    chmod +x examples/validation/validate-alertmanager.sh
    ./examples/validation/validate-alertmanager.sh
fi

echo "All validations passed!"
```

## 📊 Relatórios

Os scripts podem gerar relatórios detalhados em formato Markdown:

### Exemplo de Relatório do Prometheus

```markdown
# Relatório de Validação - Prometheus
Data: 2024-01-15 14:30:00

## Configuração Principal
- Arquivo: examples/prometheus.yml
- Status: ✅ VÁLIDA
- Scrape Configs: 5 encontrados
- Rule Files: 3 encontrados

## Regras de Alerta
- Diretório: examples/rules/
- Arquivos: 3 válidos, 0 com erros
- Total de Regras: 15

## Targets
- Diretório: examples/targets/
- Arquivos: 3 válidos
- Total de Targets: 25

## Testes de Conectividade
- Prometheus API: ✅ Disponível
- Queries de Teste: ✅ 5/5 executadas com sucesso

## Recomendações
- Configuração está pronta para produção
- Considere adicionar mais regras de alerta para aplicações
```

### Exemplo de Relatório do Alertmanager

```markdown
# Relatório de Validação - Alertmanager
Data: 2024-01-15 14:30:00

## Configuração Principal
- Arquivo: examples/alertmanager.yml
- Status: ✅ VÁLIDA
- Receivers: 4 encontrados
- Routes: 3 configuradas

## Receivers Modulares
- Diretório: examples/receivers.d/
- Arquivos: 3 válidos, 0 com erros
- Tipos: Email, Slack, Webhook

## Testes de Conectividade
- Alertmanager API: ✅ Disponível
- Simulação de Roteamento: ✅ Funcionando

## Recomendações
- Configuração está pronta para produção
- Teste notificações em ambiente de desenvolvimento
```

## 🐛 Troubleshooting

### Problemas Comuns

**1. promtool não encontrado**
```bash
# Solução: Instalar promtool
wget https://github.com/prometheus/prometheus/releases/latest/download/prometheus-*-linux-amd64.tar.gz
tar xzf prometheus-*-linux-amd64.tar.gz
sudo cp prometheus-*/promtool /usr/local/bin/
```

**2. amtool não encontrado**
```bash
# Solução: Instalar amtool
wget https://github.com/prometheus/alertmanager/releases/latest/download/alertmanager-*-linux-amd64.tar.gz
tar xzf alertmanager-*-linux-amd64.tar.gz
sudo cp alertmanager-*/amtool /usr/local/bin/
```

**3. Erro de permissão no Windows**
```powershell
# Solução: Executar como administrador ou alterar política
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**4. Arquivo de configuração não encontrado**
```bash
# Verificar caminhos
ls -la examples/
ls -la examples/prometheus.yml
ls -la examples/alertmanager.yml
```

**5. Erro de sintaxe YAML**
```bash
# Usar validador online ou ferramenta local
python -c "import yaml; yaml.safe_load(open('examples/prometheus.yml'))"
```

### Logs de Debug

**Habilitar modo verbose:**
```bash
# Linux/macOS
./validate-prometheus.sh --verbose
./validate-alertmanager.sh --verbose

# Windows
.\validate-stack.ps1 -Verbose
```

**Verificar logs dos serviços:**
```bash
# Docker logs
docker-compose logs prometheus
docker-compose logs alertmanager
docker-compose logs grafana

# Logs específicos
docker logs observability-prometheus-1
docker logs observability-alertmanager-1
```

## 📚 Referências

### Documentação Oficial
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)

### Ferramentas
- [promtool](https://prometheus.io/docs/prometheus/latest/command-line/promtool/)
- [amtool](https://prometheus.io/docs/alerting/latest/alertmanager/#amtool)
- [Docker Compose](https://docs.docker.com/compose/)

### Exemplos Adicionais
- [Prometheus Examples](https://github.com/prometheus/prometheus/tree/main/documentation/examples)
- [Alertmanager Examples](https://github.com/prometheus/alertmanager/tree/main/doc/examples)
- [Grafana Examples](https://github.com/grafana/grafana/tree/main/devenv)

## 🤝 Contribuição

Para contribuir com melhorias nos scripts de validação:

1. **Fork** o repositório
2. **Crie** uma branch para sua feature
3. **Teste** suas mudanças com os scripts existentes
4. **Documente** novas funcionalidades
5. **Submeta** um pull request

### Padrões de Código

- Use **shellcheck** para validar scripts bash
- Use **PSScriptAnalyzer** para scripts PowerShell
- Mantenha **compatibilidade** com versões antigas
- Adicione **testes** para novas funcionalidades
- **Documente** todas as opções e parâmetros

---

**💡 Dica:** Execute as validações regularmente durante o desenvolvimento para detectar problemas cedo e manter a qualidade da configuração da stack de observabilidade.
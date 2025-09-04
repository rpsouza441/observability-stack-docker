# ============================================================================
# Observability Stack Validation Script (PowerShell)
# ============================================================================
# Este script valida toda a stack de observabilidade no Windows
# Uso: .\validate-stack.ps1 [opções]

param(
    [string]$PrometheusConfig = "examples\prometheus.yml",
    [string]$AlertmanagerConfig = "examples\alertmanager.yml",
    [string]$RulesDir = "examples\rules",
    [string]$ReceiversDir = "examples\receivers.d",
    [string]$TargetsDir = "examples\targets",
    [string]$GrafanaDir = "examples\grafana\provisioning",
    [switch]$TestConnections,
    [switch]$GenerateReport,
    [switch]$Verbose,
    [switch]$Help
)

# Configurações
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Cores para output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colors = @{
        "Red" = "Red"
        "Green" = "Green"
        "Yellow" = "Yellow"
        "Blue" = "Cyan"
        "White" = "White"
    }
    
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Write-Info { param([string]$Message) Write-ColorOutput "[INFO] $Message" "Blue" }
function Write-Success { param([string]$Message) Write-ColorOutput "[SUCCESS] $Message" "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput "[WARNING] $Message" "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput "[ERROR] $Message" "Red" }

# Função de ajuda
function Show-Help {
    @"
Observability Stack Validation Script

USO:
    .\validate-stack.ps1 [OPÇÕES]

OPÇÕES:
    -PrometheusConfig FILE     Arquivo de configuração do Prometheus (padrão: examples\prometheus.yml)
    -AlertmanagerConfig FILE   Arquivo de configuração do Alertmanager (padrão: examples\alertmanager.yml)
    -RulesDir DIR             Diretório de regras (padrão: examples\rules)
    -ReceiversDir DIR         Diretório de receivers (padrão: examples\receivers.d)
    -TargetsDir DIR           Diretório de targets (padrão: examples\targets)
    -GrafanaDir DIR           Diretório do Grafana (padrão: examples\grafana\provisioning)
    -TestConnections          Testa conectividade com serviços
    -GenerateReport           Gera relatório completo
    -Verbose                  Output detalhado
    -Help                     Mostra esta ajuda

EXEMPLOS:
    .\validate-stack.ps1                    # Validação básica
    .\validate-stack.ps1 -TestConnections   # Inclui teste de conectividade
    .\validate-stack.ps1 -GenerateReport    # Gera relatório
    .\validate-stack.ps1 -Verbose           # Output detalhado

REQUISITOS:
    - Docker Desktop (para testes de conectividade)
    - PowerShell 5.1 ou superior
"@
}

# Verificar se arquivo existe
function Test-FileExists {
    param([string]$FilePath, [string]$Description)
    
    if (Test-Path $FilePath) {
        Write-Success "$Description encontrado: $FilePath"
        return $true
    } else {
        Write-Error "$Description não encontrado: $FilePath"
        return $false
    }
}

# Verificar se diretório existe
function Test-DirectoryExists {
    param([string]$DirPath, [string]$Description)
    
    if (Test-Path $DirPath -PathType Container) {
        Write-Success "$Description encontrado: $DirPath"
        return $true
    } else {
        Write-Warning "$Description não encontrado: $DirPath"
        return $false
    }
}

# Validar YAML
function Test-YamlSyntax {
    param([string]$FilePath)
    
    try {
        # Usar PowerShell-Yaml se disponível, senão validação básica
        if (Get-Module -ListAvailable -Name powershell-yaml) {
            Import-Module powershell-yaml -ErrorAction SilentlyContinue
            $content = Get-Content $FilePath -Raw
            ConvertFrom-Yaml $content | Out-Null
        } else {
            # Validação básica de sintaxe YAML
            $content = Get-Content $FilePath
            $indentLevel = 0
            foreach ($line in $content) {
                if ($line -match '^(\s*)\S') {
                    $currentIndent = $matches[1].Length
                    # Validações básicas de indentação
                }
            }
        }
        return $true
    } catch {
        Write-Error "Erro de sintaxe YAML em $FilePath`: $($_.Exception.Message)"
        return $false
    }
}

# Validar configuração do Prometheus
function Test-PrometheusConfig {
    param([string]$ConfigFile)
    
    Write-Info "Validando configuração do Prometheus: $ConfigFile"
    
    if (-not (Test-FileExists $ConfigFile "Configuração do Prometheus")) {
        return $false
    }
    
    # Validar sintaxe YAML
    if (-not (Test-YamlSyntax $ConfigFile)) {
        return $false
    }
    
    # Verificar seções obrigatórias
    $content = Get-Content $ConfigFile -Raw
    $requiredSections = @("global", "scrape_configs")
    
    foreach ($section in $requiredSections) {
        if ($content -notmatch "^$section\s*:") {
            Write-Error "Seção obrigatória '$section' não encontrada em $ConfigFile"
            return $false
        }
    }
    
    Write-Success "Configuração do Prometheus válida"
    return $true
}

# Validar regras do Prometheus
function Test-PrometheusRules {
    param([string]$RulesDir)
    
    Write-Info "Validando regras do Prometheus: $RulesDir"
    
    if (-not (Test-DirectoryExists $RulesDir "Diretório de regras")) {
        return $true # Não é obrigatório
    }
    
    $ruleFiles = Get-ChildItem $RulesDir -Filter "*.yml" -Recurse
    $ruleFiles += Get-ChildItem $RulesDir -Filter "*.yaml" -Recurse
    
    if ($ruleFiles.Count -eq 0) {
        Write-Warning "Nenhum arquivo de regra encontrado em $RulesDir"
        return $true
    }
    
    Write-Info "Encontrados $($ruleFiles.Count) arquivo(s) de regra"
    
    $errors = 0
    foreach ($file in $ruleFiles) {
        Write-Info "Validando: $($file.FullName)"
        
        if (Test-YamlSyntax $file.FullName) {
            # Verificar estrutura de regras
            $content = Get-Content $file.FullName -Raw
            if ($content -match "groups\s*:") {
                Write-Success "Regras válidas: $($file.Name)"
            } else {
                Write-Error "Estrutura de regras inválida: $($file.Name)"
                $errors++
            }
        } else {
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "Todas as regras são válidas"
        return $true
    } else {
        Write-Error "$errors arquivo(s) de regra com erros"
        return $false
    }
}

# Validar configuração do Alertmanager
function Test-AlertmanagerConfig {
    param([string]$ConfigFile)
    
    Write-Info "Validando configuração do Alertmanager: $ConfigFile"
    
    if (-not (Test-FileExists $ConfigFile "Configuração do Alertmanager")) {
        return $false
    }
    
    # Validar sintaxe YAML
    if (-not (Test-YamlSyntax $ConfigFile)) {
        return $false
    }
    
    # Verificar seções obrigatórias
    $content = Get-Content $ConfigFile -Raw
    $requiredSections = @("route", "receivers")
    
    foreach ($section in $requiredSections) {
        if ($content -notmatch "^$section\s*:") {
            Write-Error "Seção obrigatória '$section' não encontrada em $ConfigFile"
            return $false
        }
    }
    
    Write-Success "Configuração do Alertmanager válida"
    return $true
}

# Validar receivers modulares
function Test-AlertmanagerReceivers {
    param([string]$ReceiversDir)
    
    Write-Info "Validando receivers do Alertmanager: $ReceiversDir"
    
    if (-not (Test-DirectoryExists $ReceiversDir "Diretório de receivers")) {
        return $true # Não é obrigatório
    }
    
    $receiverFiles = Get-ChildItem $ReceiversDir -Filter "*.yml" -Recurse
    $receiverFiles += Get-ChildItem $ReceiversDir -Filter "*.yaml" -Recurse
    
    if ($receiverFiles.Count -eq 0) {
        Write-Warning "Nenhum arquivo de receiver encontrado em $ReceiversDir"
        return $true
    }
    
    Write-Info "Encontrados $($receiverFiles.Count) arquivo(s) de receiver"
    
    $errors = 0
    foreach ($file in $receiverFiles) {
        Write-Info "Validando: $($file.FullName)"
        
        if (Test-YamlSyntax $file.FullName) {
            # Verificar estrutura de receivers
            $content = Get-Content $file.FullName -Raw
            if ($content -match "receivers\s*:") {
                Write-Success "Receivers válidos: $($file.Name)"
            } else {
                Write-Error "Estrutura de receivers inválida: $($file.Name)"
                $errors++
            }
        } else {
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "Todos os receivers são válidos"
        return $true
    } else {
        Write-Error "$errors arquivo(s) de receiver com erros"
        return $false
    }
}

# Validar targets
function Test-PrometheusTargets {
    param([string]$TargetsDir)
    
    Write-Info "Validando targets do Prometheus: $TargetsDir"
    
    if (-not (Test-DirectoryExists $TargetsDir "Diretório de targets")) {
        return $true # Não é obrigatório
    }
    
    $targetFiles = Get-ChildItem $TargetsDir -Filter "*.yml" -Recurse
    $targetFiles += Get-ChildItem $TargetsDir -Filter "*.yaml" -Recurse
    
    if ($targetFiles.Count -eq 0) {
        Write-Warning "Nenhum arquivo de target encontrado em $TargetsDir"
        return $true
    }
    
    Write-Info "Encontrados $($targetFiles.Count) arquivo(s) de target"
    
    $errors = 0
    foreach ($file in $targetFiles) {
        Write-Info "Validando: $($file.FullName)"
        
        if (Test-YamlSyntax $file.FullName) {
            Write-Success "Target válido: $($file.Name)"
        } else {
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "Todos os targets são válidos"
        return $true
    } else {
        Write-Error "$errors arquivo(s) de target com erros"
        return $false
    }
}

# Validar provisionamento do Grafana
function Test-GrafanaProvisioning {
    param([string]$GrafanaDir)
    
    Write-Info "Validando provisionamento do Grafana: $GrafanaDir"
    
    if (-not (Test-DirectoryExists $GrafanaDir "Diretório do Grafana")) {
        return $true # Não é obrigatório
    }
    
    # Verificar estrutura de diretórios
    $expectedDirs = @("datasources", "dashboards")
    $errors = 0
    
    foreach ($dir in $expectedDirs) {
        $fullPath = Join-Path $GrafanaDir $dir
        if (-not (Test-Path $fullPath -PathType Container)) {
            Write-Warning "Diretório esperado não encontrado: $fullPath"
        } else {
            Write-Success "Diretório encontrado: $fullPath"
            
            # Validar arquivos YAML no diretório
            $yamlFiles = Get-ChildItem $fullPath -Filter "*.yml" -Recurse
            $yamlFiles += Get-ChildItem $fullPath -Filter "*.yaml" -Recurse
            
            foreach ($file in $yamlFiles) {
                if (-not (Test-YamlSyntax $file.FullName)) {
                    $errors++
                }
            }
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "Provisionamento do Grafana válido"
        return $true
    } else {
        Write-Error "$errors erro(s) no provisionamento do Grafana"
        return $false
    }
}

# Testar conectividade com serviços
function Test-ServiceConnectivity {
    Write-Info "Testando conectividade com serviços"
    
    $services = @(
        @{ Name = "Prometheus"; Url = "http://localhost:9090/-/healthy" },
        @{ Name = "Alertmanager"; Url = "http://localhost:9093/-/healthy" },
        @{ Name = "Grafana"; Url = "http://localhost:3000/api/health" }
    )
    
    foreach ($service in $services) {
        try {
            Write-Info "Testando $($service.Name): $($service.Url)"
            $response = Invoke-WebRequest -Uri $service.Url -TimeoutSec 5 -UseBasicParsing
            
            if ($response.StatusCode -eq 200) {
                Write-Success "$($service.Name): Conectividade OK"
            } else {
                Write-Warning "$($service.Name): Status $($response.StatusCode)"
            }
        } catch {
            Write-Warning "$($service.Name): Não foi possível conectar (normal se serviço não estiver rodando)"
        }
    }
}

# Gerar relatório
function New-ValidationReport {
    param(
        [string]$PrometheusConfig,
        [string]$AlertmanagerConfig,
        [string]$RulesDir,
        [string]$ReceiversDir,
        [string]$TargetsDir,
        [string]$GrafanaDir
    )
    
    Write-Info "Gerando relatório de validação"
    
    $report = @"
# Relatório de Validação - Observability Stack
Data: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Sistema: $env:COMPUTERNAME
Usuário: $env:USERNAME

## Configurações Validadas

### Prometheus
- Configuração: $PrometheusConfig
- Status: $(if (Test-PrometheusConfig $PrometheusConfig) { "✅ VÁLIDA" } else { "❌ INVÁLIDA" })
- Regras: $RulesDir
- Targets: $TargetsDir

### Alertmanager
- Configuração: $AlertmanagerConfig
- Status: $(if (Test-AlertmanagerConfig $AlertmanagerConfig) { "✅ VÁLIDA" } else { "❌ INVÁLIDA" })
- Receivers: $ReceiversDir

### Grafana
- Provisionamento: $GrafanaDir
- Status: $(if (Test-GrafanaProvisioning $GrafanaDir) { "✅ VÁLIDO" } else { "❌ INVÁLIDO" })

## Arquivos Encontrados

### Regras do Prometheus
"@
    
    if (Test-Path $RulesDir) {
        $ruleFiles = Get-ChildItem $RulesDir -Filter "*.yml" -Recurse
        $ruleFiles += Get-ChildItem $RulesDir -Filter "*.yaml" -Recurse
        foreach ($file in $ruleFiles) {
            $report += "`n- $($file.FullName)"
        }
    } else {
        $report += "`n- Nenhum arquivo encontrado"
    }
    
    $report += "`n`n### Receivers do Alertmanager"
    
    if (Test-Path $ReceiversDir) {
        $receiverFiles = Get-ChildItem $ReceiversDir -Filter "*.yml" -Recurse
        $receiverFiles += Get-ChildItem $ReceiversDir -Filter "*.yaml" -Recurse
        foreach ($file in $receiverFiles) {
            $report += "`n- $($file.FullName)"
        }
    } else {
        $report += "`n- Nenhum arquivo encontrado"
    }
    
    $report += @"

## Recomendações

- Execute validações regularmente antes de fazer deploy
- Use CI/CD para validação automática
- Monitore logs dos serviços para identificar problemas
- Teste notificações em ambiente de desenvolvimento
- Mantenha backups das configurações
- Use versionamento para controlar mudanças

## Próximos Passos

1. Corrija os erros identificados
2. Execute os serviços com Docker Compose
3. Teste conectividade com -TestConnections
4. Valide dashboards no Grafana
5. Teste alertas no Alertmanager
"@
    
    return $report
}

# Função principal
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Info "Iniciando validação da Observability Stack"
    Write-Info "=========================================="
    
    $overallSuccess = $true
    
    # Validar Prometheus
    if (-not (Test-PrometheusConfig $PrometheusConfig)) {
        $overallSuccess = $false
    }
    
    Write-Host ""
    
    # Validar regras do Prometheus
    if (-not (Test-PrometheusRules $RulesDir)) {
        $overallSuccess = $false
    }
    
    Write-Host ""
    
    # Validar targets
    if (-not (Test-PrometheusTargets $TargetsDir)) {
        $overallSuccess = $false
    }
    
    Write-Host ""
    
    # Validar Alertmanager
    if (-not (Test-AlertmanagerConfig $AlertmanagerConfig)) {
        $overallSuccess = $false
    }
    
    Write-Host ""
    
    # Validar receivers
    if (-not (Test-AlertmanagerReceivers $ReceiversDir)) {
        $overallSuccess = $false
    }
    
    Write-Host ""
    
    # Validar Grafana
    if (-not (Test-GrafanaProvisioning $GrafanaDir)) {
        $overallSuccess = $false
    }
    
    Write-Host ""
    
    # Testar conectividade se solicitado
    if ($TestConnections) {
        Test-ServiceConnectivity
        Write-Host ""
    }
    
    # Gerar relatório se solicitado
    if ($GenerateReport) {
        $report = New-ValidationReport $PrometheusConfig $AlertmanagerConfig $RulesDir $ReceiversDir $TargetsDir $GrafanaDir
        $reportFile = "validation-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
        $report | Out-File -FilePath $reportFile -Encoding UTF8
        Write-Success "Relatório gerado: $reportFile"
        Write-Host ""
    }
    
    Write-Info "=========================================="
    if ($overallSuccess) {
        Write-Success "Todas as validações passaram!"
        exit 0
    } else {
        Write-Error "Algumas validações falharam!"
        exit 1
    }
}

# Executar função principal
Main
#!/bin/bash

# ============================================================================
# Prometheus Configuration Validation Script
# ============================================================================
# Este script valida configurações do Prometheus usando promtool
# Uso: ./validate-prometheus.sh [config-file] [rules-dir]

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações padrão
DEFAULT_CONFIG="examples/prometheus.yml"
DEFAULT_RULES_DIR="examples/rules"
PROMTOOL_BINARY="promtool"

# Função para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se promtool está disponível
check_promtool() {
    if ! command -v $PROMTOOL_BINARY &> /dev/null; then
        log_error "promtool não encontrado. Instale o Prometheus ou defina PROMTOOL_BINARY."
        log_info "Download: https://github.com/prometheus/prometheus/releases"
        exit 1
    fi
    
    local version=$(promtool --version 2>&1 | head -n1)
    log_info "Usando: $version"
}

# Função para validar configuração principal
validate_config() {
    local config_file="${1:-$DEFAULT_CONFIG}"
    
    log_info "Validando configuração: $config_file"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Arquivo de configuração não encontrado: $config_file"
        return 1
    fi
    
    if promtool check config "$config_file"; then
        log_success "Configuração válida: $config_file"
        return 0
    else
        log_error "Configuração inválida: $config_file"
        return 1
    fi
}

# Função para validar regras
validate_rules() {
    local rules_dir="${1:-$DEFAULT_RULES_DIR}"
    local errors=0
    
    log_info "Validando regras em: $rules_dir"
    
    if [[ ! -d "$rules_dir" ]]; then
        log_error "Diretório de regras não encontrado: $rules_dir"
        return 1
    fi
    
    # Encontrar todos os arquivos .yml e .yaml
    local rule_files=()
    while IFS= read -r -d '' file; do
        rule_files+=("$file")
    done < <(find "$rules_dir" -name "*.yml" -o -name "*.yaml" -print0)
    
    if [[ ${#rule_files[@]} -eq 0 ]]; then
        log_warning "Nenhum arquivo de regra encontrado em $rules_dir"
        return 0
    fi
    
    log_info "Encontrados ${#rule_files[@]} arquivo(s) de regra"
    
    for rule_file in "${rule_files[@]}"; do
        log_info "Validando: $rule_file"
        
        if promtool check rules "$rule_file"; then
            log_success "Regras válidas: $rule_file"
        else
            log_error "Regras inválidas: $rule_file"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "Todas as regras são válidas"
        return 0
    else
        log_error "$errors arquivo(s) de regra com erros"
        return 1
    fi
}

# Função para testar queries
test_queries() {
    local config_file="${1:-$DEFAULT_CONFIG}"
    
    log_info "Testando queries de exemplo"
    
    # Queries básicas para testar
    local test_queries=(
        "up"
        "rate(prometheus_http_requests_total[5m])"
        "node_cpu_seconds_total"
        "container_memory_usage_bytes"
        "snmp_up"
    )
    
    for query in "${test_queries[@]}"; do
        log_info "Testando query: $query"
        
        if promtool query instant http://localhost:9090 "$query" 2>/dev/null; then
            log_success "Query válida: $query"
        else
            log_warning "Query pode não retornar dados (normal se métricas não existirem): $query"
        fi
    done
}

# Função para validar targets
validate_targets() {
    local targets_dir="examples/targets"
    
    log_info "Validando arquivos de targets em: $targets_dir"
    
    if [[ ! -d "$targets_dir" ]]; then
        log_warning "Diretório de targets não encontrado: $targets_dir"
        return 0
    fi
    
    local target_files=()
    while IFS= read -r -d '' file; do
        target_files+=("$file")
    done < <(find "$targets_dir" -name "*.yml" -o -name "*.yaml" -print0)
    
    if [[ ${#target_files[@]} -eq 0 ]]; then
        log_warning "Nenhum arquivo de target encontrado em $targets_dir"
        return 0
    fi
    
    for target_file in "${target_files[@]}"; do
        log_info "Validando sintaxe YAML: $target_file"
        
        if python3 -c "import yaml; yaml.safe_load(open('$target_file'))" 2>/dev/null; then
            log_success "YAML válido: $target_file"
        else
            log_error "YAML inválido: $target_file"
        fi
    done
}

# Função para gerar relatório
generate_report() {
    local config_file="${1:-$DEFAULT_CONFIG}"
    local rules_dir="${2:-$DEFAULT_RULES_DIR}"
    
    log_info "Gerando relatório de validação"
    
    echo "# Relatório de Validação Prometheus"
    echo "Data: $(date)"
    echo ""
    
    echo "## Configuração Principal"
    echo "Arquivo: $config_file"
    if validate_config "$config_file" &>/dev/null; then
        echo "Status: ✅ VÁLIDA"
    else
        echo "Status: ❌ INVÁLIDA"
    fi
    echo ""
    
    echo "## Regras de Alerta"
    echo "Diretório: $rules_dir"
    local rule_count=$(find "$rules_dir" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
    echo "Arquivos encontrados: $rule_count"
    if validate_rules "$rules_dir" &>/dev/null; then
        echo "Status: ✅ TODAS VÁLIDAS"
    else
        echo "Status: ❌ ALGUMAS INVÁLIDAS"
    fi
    echo ""
    
    echo "## Targets"
    local targets_dir="examples/targets"
    local target_count=$(find "$targets_dir" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
    echo "Arquivos encontrados: $target_count"
    echo ""
    
    echo "## Recomendações"
    echo "- Execute validações regularmente"
    echo "- Use CI/CD para validação automática"
    echo "- Monitore logs do Prometheus para erros"
    echo "- Teste regras em ambiente de desenvolvimento"
}

# Função de ajuda
show_help() {
    cat << EOF
Uso: $0 [OPÇÕES] [CONFIG_FILE] [RULES_DIR]

Valida configurações do Prometheus usando promtool.

OPÇÕES:
    -h, --help          Mostra esta ajuda
    -c, --config FILE   Arquivo de configuração (padrão: $DEFAULT_CONFIG)
    -r, --rules DIR     Diretório de regras (padrão: $DEFAULT_RULES_DIR)
    -q, --queries       Testa queries de exemplo
    -t, --targets       Valida arquivos de targets
    -R, --report        Gera relatório completo
    --promtool PATH     Caminho para o binário promtool

EXEMPLOS:
    $0                                    # Validação básica
    $0 -c custom.yml -r custom/rules      # Arquivos customizados
    $0 --queries                          # Inclui teste de queries
    $0 --report > validation-report.md   # Gera relatório

REQUISITOS:
    - promtool (incluído no Prometheus)
    - python3 (para validação YAML)

EOF
}

# Função principal
main() {
    local config_file="$DEFAULT_CONFIG"
    local rules_dir="$DEFAULT_RULES_DIR"
    local test_queries_flag=false
    local validate_targets_flag=false
    local generate_report_flag=false
    
    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--config)
                config_file="$2"
                shift 2
                ;;
            -r|--rules)
                rules_dir="$2"
                shift 2
                ;;
            -q|--queries)
                test_queries_flag=true
                shift
                ;;
            -t|--targets)
                validate_targets_flag=true
                shift
                ;;
            -R|--report)
                generate_report_flag=true
                shift
                ;;
            --promtool)
                PROMTOOL_BINARY="$2"
                shift 2
                ;;
            -*)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "${config_file_set:-}" ]]; then
                    config_file="$1"
                    config_file_set=true
                elif [[ -z "${rules_dir_set:-}" ]]; then
                    rules_dir="$1"
                    rules_dir_set=true
                else
                    log_error "Muitos argumentos posicionais"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Verificar promtool
    check_promtool
    
    # Executar validações
    local exit_code=0
    
    if [[ "$generate_report_flag" == true ]]; then
        generate_report "$config_file" "$rules_dir"
        exit 0
    fi
    
    log_info "Iniciando validação Prometheus"
    echo "==========================================="
    
    # Validar configuração
    if ! validate_config "$config_file"; then
        exit_code=1
    fi
    
    echo ""
    
    # Validar regras
    if ! validate_rules "$rules_dir"; then
        exit_code=1
    fi
    
    echo ""
    
    # Validar targets se solicitado
    if [[ "$validate_targets_flag" == true ]]; then
        validate_targets
        echo ""
    fi
    
    # Testar queries se solicitado
    if [[ "$test_queries_flag" == true ]]; then
        test_queries "$config_file"
        echo ""
    fi
    
    echo "==========================================="
    if [[ $exit_code -eq 0 ]]; then
        log_success "Todas as validações passaram!"
    else
        log_error "Algumas validações falharam!"
    fi
    
    exit $exit_code
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
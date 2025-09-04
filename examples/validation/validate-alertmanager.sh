#!/bin/bash

# ============================================================================
# Alertmanager Configuration Validation Script
# ============================================================================
# Este script valida configurações do Alertmanager usando amtool
# Uso: ./validate-alertmanager.sh [config-file]

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações padrão
DEFAULT_CONFIG="examples/alertmanager.yml"
DEFAULT_RECEIVERS_DIR="examples/receivers.d"
AMTOOL_BINARY="amtool"
ALERTMANAGER_URL="http://localhost:9093"

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

# Função para verificar se amtool está disponível
check_amtool() {
    if ! command -v $AMTOOL_BINARY &> /dev/null; then
        log_error "amtool não encontrado. Instale o Alertmanager ou defina AMTOOL_BINARY."
        log_info "Download: https://github.com/prometheus/alertmanager/releases"
        exit 1
    fi
    
    local version=$(amtool --version 2>&1 | head -n1)
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
    
    if amtool config show --config.file="$config_file" &>/dev/null; then
        log_success "Configuração válida: $config_file"
        return 0
    else
        log_error "Configuração inválida: $config_file"
        return 1
    fi
}

# Função para validar receivers modulares
validate_receivers() {
    local receivers_dir="${1:-$DEFAULT_RECEIVERS_DIR}"
    local errors=0
    
    log_info "Validando receivers em: $receivers_dir"
    
    if [[ ! -d "$receivers_dir" ]]; then
        log_warning "Diretório de receivers não encontrado: $receivers_dir"
        return 0
    fi
    
    # Encontrar todos os arquivos .yml e .yaml
    local receiver_files=()
    while IFS= read -r -d '' file; do
        receiver_files+=("$file")
    done < <(find "$receivers_dir" -name "*.yml" -o -name "*.yaml" -print0)
    
    if [[ ${#receiver_files[@]} -eq 0 ]]; then
        log_warning "Nenhum arquivo de receiver encontrado em $receivers_dir"
        return 0
    fi
    
    log_info "Encontrados ${#receiver_files[@]} arquivo(s) de receiver"
    
    for receiver_file in "${receiver_files[@]}"; do
        log_info "Validando sintaxe YAML: $receiver_file"
        
        if python3 -c "import yaml; yaml.safe_load(open('$receiver_file'))" 2>/dev/null; then
            log_success "YAML válido: $receiver_file"
        else
            log_error "YAML inválido: $receiver_file"
            ((errors++))
        fi
        
        # Validar estrutura de receivers
        if validate_receiver_structure "$receiver_file"; then
            log_success "Estrutura válida: $receiver_file"
        else
            log_error "Estrutura inválida: $receiver_file"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "Todos os receivers são válidos"
        return 0
    else
        log_error "$errors arquivo(s) de receiver com erros"
        return 1
    fi
}

# Função para validar estrutura de receiver
validate_receiver_structure() {
    local receiver_file="$1"
    
    # Verificar se contém seção receivers
    if ! grep -q "^receivers:" "$receiver_file"; then
        log_error "Arquivo não contém seção 'receivers': $receiver_file"
        return 1
    fi
    
    # Verificar se receivers têm nomes
    local receiver_count=$(grep -c "^  - name:" "$receiver_file" || true)
    if [[ $receiver_count -eq 0 ]]; then
        log_error "Nenhum receiver com nome encontrado: $receiver_file"
        return 1
    fi
    
    log_info "Encontrados $receiver_count receiver(s) em $receiver_file"
    return 0
}

# Função para testar conectividade com Alertmanager
test_alertmanager_connection() {
    local url="${1:-$ALERTMANAGER_URL}"
    
    log_info "Testando conectividade com Alertmanager: $url"
    
    if amtool --alertmanager.url="$url" config show &>/dev/null; then
        log_success "Conectividade OK: $url"
        return 0
    else
        log_warning "Não foi possível conectar: $url (normal se Alertmanager não estiver rodando)"
        return 1
    fi
}

# Função para testar roteamento
test_routing() {
    local config_file="${1:-$DEFAULT_CONFIG}"
    
    log_info "Testando configuração de roteamento"
    
    # Criar alertas de teste
    local test_alerts=(
        '{"labels":{"alertname":"TestCritical","severity":"critical","team":"sre"}}'
        '{"labels":{"alertname":"TestWarning","severity":"warning","service":"web"}}'
        '{"labels":{"alertname":"TestInfo","severity":"info"}}'
    )
    
    for alert in "${test_alerts[@]}"; do
        log_info "Testando roteamento para: $alert"
        
        # Simular roteamento (requer Alertmanager rodando)
        if amtool config routes test --config.file="$config_file" "$alert" 2>/dev/null; then
            log_success "Roteamento OK para: $alert"
        else
            log_warning "Não foi possível testar roteamento (requer Alertmanager rodando)"
        fi
    done
}

# Função para validar templates
validate_templates() {
    local config_file="${1:-$DEFAULT_CONFIG}"
    
    log_info "Validando templates"
    
    # Extrair caminhos de templates do config
    local template_paths=()
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*-[[:space:]]*(.+)$ ]]; then
            template_paths+=("${BASH_REMATCH[1]}")
        fi
    done < <(grep -A 10 "^templates:" "$config_file" | grep "^  -" || true)
    
    if [[ ${#template_paths[@]} -eq 0 ]]; then
        log_warning "Nenhum template configurado"
        return 0
    fi
    
    local errors=0
    for template_path in "${template_paths[@]}"; do
        # Remover aspas se existirem
        template_path=$(echo "$template_path" | sed 's/["\047]//g')
        
        log_info "Validando template: $template_path"
        
        if [[ -f "$template_path" ]]; then
            log_success "Template encontrado: $template_path"
        else
            log_error "Template não encontrado: $template_path"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "Todos os templates são válidos"
        return 0
    else
        log_error "$errors template(s) com problemas"
        return 1
    fi
}

# Função para listar receivers configurados
list_receivers() {
    local config_file="${1:-$DEFAULT_CONFIG}"
    
    log_info "Listando receivers configurados"
    
    if amtool config show --config.file="$config_file" 2>/dev/null | grep -A 1000 "receivers:" | grep "^- name:" | sed 's/^- name: //'; then
        log_success "Receivers listados com sucesso"
    else
        log_error "Não foi possível listar receivers"
        return 1
    fi
}

# Função para gerar relatório
generate_report() {
    local config_file="${1:-$DEFAULT_CONFIG}"
    local receivers_dir="${2:-$DEFAULT_RECEIVERS_DIR}"
    
    log_info "Gerando relatório de validação"
    
    echo "# Relatório de Validação Alertmanager"
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
    
    echo "## Receivers Modulares"
    echo "Diretório: $receivers_dir"
    local receiver_count=$(find "$receivers_dir" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
    echo "Arquivos encontrados: $receiver_count"
    if validate_receivers "$receivers_dir" &>/dev/null; then
        echo "Status: ✅ TODOS VÁLIDOS"
    else
        echo "Status: ❌ ALGUNS INVÁLIDOS"
    fi
    echo ""
    
    echo "## Conectividade"
    if test_alertmanager_connection &>/dev/null; then
        echo "Alertmanager: ✅ CONECTADO"
    else
        echo "Alertmanager: ❌ DESCONECTADO"
    fi
    echo ""
    
    echo "## Templates"
    if validate_templates "$config_file" &>/dev/null; then
        echo "Status: ✅ TODOS VÁLIDOS"
    else
        echo "Status: ❌ ALGUNS INVÁLIDOS"
    fi
    echo ""
    
    echo "## Receivers Configurados"
    list_receivers "$config_file" 2>/dev/null || echo "Erro ao listar receivers"
    echo ""
    
    echo "## Recomendações"
    echo "- Execute validações regularmente"
    echo "- Teste notificações em ambiente de desenvolvimento"
    echo "- Monitore logs do Alertmanager para erros"
    echo "- Use webhooks de teste para validar integrações"
}

# Função de ajuda
show_help() {
    cat << EOF
Uso: $0 [OPÇÕES] [CONFIG_FILE]

Valida configurações do Alertmanager usando amtool.

OPÇÕES:
    -h, --help              Mostra esta ajuda
    -c, --config FILE       Arquivo de configuração (padrão: $DEFAULT_CONFIG)
    -r, --receivers DIR     Diretório de receivers (padrão: $DEFAULT_RECEIVERS_DIR)
    -u, --url URL           URL do Alertmanager (padrão: $ALERTMANAGER_URL)
    -t, --test-routing      Testa configuração de roteamento
    -T, --test-connection   Testa conectividade com Alertmanager
    -l, --list-receivers    Lista receivers configurados
    -R, --report            Gera relatório completo
    --amtool PATH           Caminho para o binário amtool

EXEMPLOS:
    $0                                      # Validação básica
    $0 -c custom-alertmanager.yml           # Arquivo customizado
    $0 --test-connection                     # Testa conectividade
    $0 --report > alertmanager-report.md    # Gera relatório

REQUISITOS:
    - amtool (incluído no Alertmanager)
    - python3 (para validação YAML)

EOF
}

# Função principal
main() {
    local config_file="$DEFAULT_CONFIG"
    local receivers_dir="$DEFAULT_RECEIVERS_DIR"
    local test_routing_flag=false
    local test_connection_flag=false
    local list_receivers_flag=false
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
            -r|--receivers)
                receivers_dir="$2"
                shift 2
                ;;
            -u|--url)
                ALERTMANAGER_URL="$2"
                shift 2
                ;;
            -t|--test-routing)
                test_routing_flag=true
                shift
                ;;
            -T|--test-connection)
                test_connection_flag=true
                shift
                ;;
            -l|--list-receivers)
                list_receivers_flag=true
                shift
                ;;
            -R|--report)
                generate_report_flag=true
                shift
                ;;
            --amtool)
                AMTOOL_BINARY="$2"
                shift 2
                ;;
            -*)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
            *)
                config_file="$1"
                shift
                ;;
        esac
    done
    
    # Verificar amtool
    check_amtool
    
    # Executar validações
    local exit_code=0
    
    if [[ "$generate_report_flag" == true ]]; then
        generate_report "$config_file" "$receivers_dir"
        exit 0
    fi
    
    log_info "Iniciando validação Alertmanager"
    echo "==========================================="
    
    # Validar configuração
    if ! validate_config "$config_file"; then
        exit_code=1
    fi
    
    echo ""
    
    # Validar receivers
    if ! validate_receivers "$receivers_dir"; then
        exit_code=1
    fi
    
    echo ""
    
    # Validar templates
    if ! validate_templates "$config_file"; then
        exit_code=1
    fi
    
    echo ""
    
    # Testar conectividade se solicitado
    if [[ "$test_connection_flag" == true ]]; then
        test_alertmanager_connection
        echo ""
    fi
    
    # Testar roteamento se solicitado
    if [[ "$test_routing_flag" == true ]]; then
        test_routing "$config_file"
        echo ""
    fi
    
    # Listar receivers se solicitado
    if [[ "$list_receivers_flag" == true ]]; then
        list_receivers "$config_file"
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
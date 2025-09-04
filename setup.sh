#!/bin/bash

# =============================================================================
# SCRIPT DE CONFIGURAÇÃO INICIAL DO STACK DE OBSERVABILIDADE
# =============================================================================
# Este script automatiza a configuração inicial do ambiente
# Execute: chmod +x setup.sh && ./setup.sh
# =============================================================================

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar pré-requisitos
check_prerequisites() {
    print_info "Verificando pré-requisitos..."
    
    if ! command_exists docker; then
        print_error "Docker não está instalado. Instale o Docker primeiro."
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose não está instalado. Instale o Docker Compose primeiro."
        exit 1
    fi
    
    print_success "Pré-requisitos verificados com sucesso!"
}

# Criar arquivo .env se não existir
setup_env_file() {
    print_info "Configurando arquivo de ambiente..."
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Arquivo .env criado a partir do .env.example"
            print_warning "IMPORTANTE: Edite o arquivo .env com suas configurações específicas!"
        else
            print_error "Arquivo .env.example não encontrado!"
            exit 1
        fi
    else
        print_info "Arquivo .env já existe, pulando..."
    fi
}

# Criar diretórios necessários
create_directories() {
    print_info "Criando diretórios necessários..."
    
    directories=(
        "prometheus_data"
        "grafana_data"
        "alertmanager_data"
        "grafana/dashboards/infrastructure"
        "grafana/dashboards/network"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Diretório $dir criado"
        else
            print_info "Diretório $dir já existe"
        fi
    done
}

# Configurar permissões
set_permissions() {
    print_info "Configurando permissões..."
    
    # Grafana precisa de permissões específicas
    if [ -d "grafana_data" ]; then
        sudo chown -R 472:472 grafana_data/ 2>/dev/null || {
            print_warning "Não foi possível alterar permissões do grafana_data (pode precisar de sudo)"
        }
    fi
    
    # Prometheus precisa de permissões específicas
    if [ -d "prometheus_data" ]; then
        sudo chown -R 65534:65534 prometheus_data/ 2>/dev/null || {
            print_warning "Não foi possível alterar permissões do prometheus_data (pode precisar de sudo)"
        }
    fi
    
    print_success "Permissões configuradas"
}

# Validar configurações
validate_config() {
    print_info "Validando configurações..."
    
    # Verificar se arquivos de configuração existem
    config_files=(
        "prometheus.yml"
        "alertmanager/alertmanager.yml"
        "snmp_exporter/snmp.yml"
        "compose.yml"
    )
    
    for file in "${config_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Arquivo de configuração $file não encontrado!"
            exit 1
        fi
    done
    
    print_success "Configurações validadas"
}

# Testar configuração do Docker Compose
test_compose() {
    print_info "Testando configuração do Docker Compose..."
    
    if docker-compose config >/dev/null 2>&1; then
        print_success "Configuração do Docker Compose válida"
    else
        print_error "Erro na configuração do Docker Compose!"
        print_info "Execute 'docker-compose config' para ver os detalhes do erro"
        exit 1
    fi
}

# Função principal
main() {
    echo "="*70
    echo "    CONFIGURAÇÃO INICIAL DO STACK DE OBSERVABILIDADE"
    echo "="*70
    echo
    
    check_prerequisites
    setup_env_file
    create_directories
    set_permissions
    validate_config
    test_compose
    
    echo
    echo "="*70
    print_success "CONFIGURAÇÃO INICIAL CONCLUÍDA COM SUCESSO!"
    echo "="*70
    echo
    
    print_info "Próximos passos:"
    echo "1. Edite o arquivo .env com suas configurações específicas"
    echo "2. Configure os IPs dos dispositivos SNMP no arquivo .env"
    echo "3. Configure as credenciais de email para alertas no arquivo .env"
    echo "4. Execute: docker-compose up -d"
    echo "5. Acesse o Grafana em http://localhost:3000"
    echo
    
    print_warning "IMPORTANTE: Não esqueça de configurar o arquivo .env antes de iniciar os serviços!"
    
    # Perguntar se quer iniciar os serviços
    echo
    read -p "Deseja iniciar os serviços agora? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Iniciando serviços..."
        docker-compose up -d
        
        echo
        print_success "Serviços iniciados com sucesso!"
        print_info "Aguarde alguns minutos para que todos os serviços inicializem completamente"
        print_info "Acesse o Grafana em: http://localhost:3000"
        print_info "Acesse o Prometheus em: http://localhost:9090"
        print_info "Acesse o Alertmanager em: http://localhost:9093"
        
        # Mostrar status dos containers
        echo
        print_info "Status dos containers:"
        docker-compose ps
    else
        print_info "Serviços não foram iniciados. Execute 'docker-compose up -d' quando estiver pronto."
    fi
}

# Executar função principal
main "$@"
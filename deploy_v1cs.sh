#!/bin/bash

# Set strict error handling
set -eo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global variables
required_tools=("kubectl" "jq")
STATE_FILE=".container-security-demo"

# Welcome banner
display_welcome() {
    clear
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     Trend Vision One - Container Security Demo Deploy      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "This script will deploy Container Security and required components."
    echo
    echo "Required Files:"
    echo "  • calico/values.yaml - Calico configuration"
    echo "  • app-server-1.yaml - Demo application manifest"
    echo "  • app-server-2.yaml - Demo application manifest"
    echo "  • overrides.yaml - V1CS configuration with API key"
    echo
    echo "Required Tools:"
    echo "  • kubectl - Kubernetes command-line tool"
    echo "  • jq - JSON processor"
    echo
    echo "The script will:"
    echo "  1. Check and install prerequisites (including Helm if missing)"
    echo "  2. Deploy Calico network policy (if not already installed)"
    echo "  3. Deploy demo applications"
    echo "  4. Install Container Security"
    echo
}

# Help message
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help     Show this help message
    cleanup        Remove V1CS and applications
    verify        Verify deployment status
    
Without options, the script will start interactive deployment.

Examples:
    $0              # Start interactive deployment
    $0 cleanup     # Remove deployed components
    $0 verify      # Check deployment status
EOF
}

# Logging function
log() {
    local level=$1
    shift
    local message=$*
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}${timestamp} [${level}]${NC} ${message}"
}

# Function to check and install prerequisites
check_prerequisites() {
    log "INFO" "Checking prerequisites..."

    # Check required files
    local required_files=(
        "overrides.yaml"
        "app-server-1.yaml"
        "app-server-2.yaml"
        "calico/values.yaml"
    )
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log "ERROR" "Required file not found: $file"
            exit 1
        fi
    done

    # Check for required tools
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log "ERROR" "Required tool not found: $tool"
            log "ERROR" "Please install $tool before proceeding"
            exit 1
        fi
    done

    # Check and install Helm if needed
    if ! command -v helm &> /dev/null; then
        log "INFO" "Helm not found. Installing Helm..."
        curl --silent https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        if ! command -v helm &> /dev/null; then
            log "ERROR" "Helm installation failed"
            exit 1
        fi
        log "INFO" "Helm installed successfully"
    fi

    # Check kubectl access
    if ! kubectl cluster-info &>/dev/null; then
        log "ERROR" "Unable to connect to Kubernetes cluster"
        exit 1
    fi

    log "INFO" "All prerequisites checked successfully"
}

# Function to deploy Calico
deploy_calico() {
    log "INFO" "Checking if Calico is already installed..."
    
    # Check if namespace exists first
    if kubectl get namespace tigera-operator >/dev/null 2>&1; then
        if helm list -n tigera-operator 2>/dev/null | grep -q "calico"; then
            log "INFO" "Calico is already installed, skipping deployment..."
            return
        fi
    fi

    log "INFO" "Deploying Calico network policy..."

    # Create namespace
    log "INFO" "Creating tigera-operator namespace..."
    kubectl create namespace tigera-operator --dry-run=client -o yaml | kubectl apply -f -

    # Add Calico helm repo
    log "INFO" "Adding Calico helm repository..."
    helm repo add projectcalico https://docs.projectcalico.org/charts || true
    helm repo update

    # Install Calico
    log "INFO" "Installing Calico..."
    helm install calico projectcalico/tigera-operator \
        --version v3.29.1 \
        -f calico/values.yaml \
        --namespace tigera-operator

    # Wait for Calico pods
    log "INFO" "Waiting for Calico pods to be ready..."
    sleep 30  # Give pods time to start
    kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n calico-system --timeout=60s || true

    log "INFO" "Calico deployment completed successfully"
}

# Function to deploy applications
deploy_apps() {
    log "INFO" "Deploying applications..."

    # Create namespaces
    kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace attacker --dry-run=client -o yaml | kubectl apply -f -

    # Deploy applications
    kubectl apply -f app-server-1.yaml
    kubectl apply -f app-server-2.yaml

    # Wait for pods
    log "INFO" "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=app-server-1 -n demo --timeout=90s || true
    kubectl wait --for=condition=ready pod -l app=app-server-2 -n demo --timeout=90s || true

    # Get service IPs
    local app1_ip=$(kubectl get svc -n demo app1-service -o jsonpath='{.spec.clusterIP}')
    local app2_ip=$(kubectl get svc -n demo app2-service -o jsonpath='{.spec.clusterIP}')

    log "INFO" "App Server 1 deployed at: $app1_ip"
    log "INFO" "App Server 2 deployed at: $app2_ip"
}

# Function to install V1CS
install_v1cs() {
    log "INFO" "Installing Trend Vision One - Container Security..."

    if [ ! -f "overrides.yaml" ]; then
        log "ERROR" "overrides.yaml not found"
        exit 1
    fi

    helm install \
        --values overrides.yaml \
        --namespace trendmicro-system \
        --create-namespace \
        trendmicro \
        https://github.com/trendmicro/cloudone-container-security-helm/archive/master.tar.gz

    log "INFO" "Waiting for V1CS pods to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=container-security -n trendmicro-system --timeout=120s || true

    log "INFO" "V1CS installation completed"
}

# Function to verify deployments
verify_deployments() {
    log "INFO" "Verifying deployments..."

    echo -e "\n${BLUE}Namespaces:${NC}"
    kubectl get ns

    echo -e "\n${BLUE}Calico Status:${NC}"
    kubectl get pods -n tigera-operator
    kubectl get pods -n calico-system

    echo -e "\n${BLUE}Applications Status:${NC}"
    kubectl get pods,svc -n demo

    echo -e "\n${BLUE}V1CS Status:${NC}"
    kubectl get pods -n trendmicro-system
}

# Function to cleanup resources
cleanup() {
    log "INFO" "Starting cleanup process..."

    # Remove V1CS
    log "INFO" "Removing V1CS..."
    helm uninstall trendmicro -n trendmicro-system 2>/dev/null || true
    kubectl delete namespace trendmicro-system --timeout=60s 2>/dev/null || true

    # Remove applications
    log "INFO" "Removing applications..."
    kubectl delete -f app-server-1.yaml 2>/dev/null || true
    kubectl delete -f app-server-2.yaml 2>/dev/null || true

    # Remove namespaces
    log "INFO" "Removing namespaces..."
    kubectl delete namespace demo --timeout=60s 2>/dev/null || true
    kubectl delete namespace attacker --timeout=60s 2>/dev/null || true

    # Remove temporary files
    rm -f "$STATE_FILE" 2>/dev/null || true

    log "INFO" "Cleanup completed successfully"
}

# Main execution
main() {
    display_welcome
    
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        cleanup)
            cleanup
            exit 0
            ;;
        verify)
            verify_deployments
            exit 0
            ;;
        "")
            log "INFO" "Starting deployment..."
            
            check_prerequisites
            deploy_calico
            deploy_apps
            install_v1cs
            verify_deployments
            
            log "INFO" "Deployment completed successfully"
            log "INFO" "To cleanup resources, run: $0 cleanup"
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Error handling
trap 'log "ERROR" "An error occurred. Starting cleanup..."; cleanup; exit 1' ERR

# Run main
main "$@"
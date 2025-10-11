#!/bin/bash

# DockyDEB Workflow Validation Script
# This script validates the workflow configuration and scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Validation functions
validate_files() {
    log_info "Validating required files..."
    
    local files=(
        ".github/workflows/weekly-update.yaml"
        "scripts/check-updates.sh"
        "scripts/init-versions.sh"
        "package-versions.json"
        "version.env"
        "Dockerfile"
    )
    
    local missing_files=()
    
    for file in "${files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "Found: $file"
        else
            log_error "Missing: $file"
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing required files. Please ensure all files are present."
        return 1
    fi
}

validate_scripts() {
    log_info "Validating script syntax..."
    
    local scripts=(
        "scripts/check-updates.sh"
        "scripts/init-versions.sh"
        "scripts/validate-workflow.sh"
    )
    
    for script in "${scripts[@]}"; do
        if bash -n "$PROJECT_ROOT/$script"; then
            log_success "Syntax valid: $script"
        else
            log_error "Syntax error in: $script"
            return 1
        fi
    done
}

validate_permissions() {
    log_info "Validating script permissions..."
    
    local scripts=(
        "scripts/check-updates.sh"
        "scripts/init-versions.sh"
        "scripts/validate-workflow.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -x "$PROJECT_ROOT/$script" ]]; then
            log_success "Executable: $script"
        else
            log_warning "Not executable: $script (fixing...)"
            chmod +x "$PROJECT_ROOT/$script"
            log_success "Fixed permissions: $script"
        fi
    done
}

validate_json() {
    log_info "Validating JSON files..."
    
    local json_files=(
        "package-versions.json"
    )
    
    for json_file in "${json_files[@]}"; do
        if command -v jq &> /dev/null; then
            if jq empty "$PROJECT_ROOT/$json_file" 2>/dev/null; then
                log_success "Valid JSON: $json_file"
            else
                log_error "Invalid JSON: $json_file"
                return 1
            fi
        else
            log_warning "jq not available, skipping JSON validation for $json_file"
        fi
    done
}

validate_workflow() {
    log_info "Validating workflow configuration..."
    
    local workflow_file="$PROJECT_ROOT/.github/workflows/weekly-update.yaml"
    
    # Check for required workflow elements
    local required_elements=(
        "schedule:"
        "workflow_dispatch:"
        "check-updates:"
        "update-version:"
        "docker-build-test:"
    )
    
    for element in "${required_elements[@]}"; do
        if grep -q "$element" "$workflow_file"; then
            log_success "Found workflow element: $element"
        else
            log_error "Missing workflow element: $element"
            return 1
        fi
    done
    
    # Check that the old branch restriction is removed
    if grep -q "github.ref == 'refs/heads/develop'" "$workflow_file"; then
        log_error "Found old branch restriction that would prevent scheduled runs"
        return 1
    else
        log_success "No problematic branch restrictions found"
    fi
}

validate_version_consistency() {
    log_info "Validating version consistency..."
    
    # Extract versions
    local version_env=$(grep "DOCKYDEB_VERSION=" "$PROJECT_ROOT/version.env" | cut -d'=' -f2)
    local dockerfile_version=$(grep 'org.opencontainers.image.version=' "$PROJECT_ROOT/Dockerfile" | head -1 | sed 's/.*version="\([^"]*\)".*/\1/')
    
    log_info "Version in version.env: $version_env"
    log_info "Version in Dockerfile: $dockerfile_version"
    
    # Remove 'v' prefix for comparison
    local version_env_clean=${version_env#v}
    
    if [[ "$version_env_clean" == "$dockerfile_version" ]]; then
        log_success "Version consistency check passed"
    else
        log_error "Version mismatch between version.env and Dockerfile"
        return 1
    fi
}

# Main validation function
main() {
    log_info "Starting DockyDEB workflow validation..."
    echo ""
    
    local validation_failed=false
    
    # Run all validations
    validate_files || validation_failed=true
    echo ""
    
    validate_scripts || validation_failed=true
    echo ""
    
    validate_permissions || validation_failed=true
    echo ""
    
    validate_json || validation_failed=true
    echo ""
    
    validate_workflow || validation_failed=true
    echo ""
    
    validate_version_consistency || validation_failed=true
    echo ""
    
    # Final result
    if [[ "$validation_failed" == true ]]; then
        log_error "Validation failed! Please fix the issues above."
        exit 1
    else
        log_success "All validations passed! The workflow is ready to use."
        echo ""
        log_info "Next steps:"
        echo "1. Commit and push the changes to the develop branch"
        echo "2. The weekly update workflow will run automatically every Sunday at 2:00 AM UTC"
        echo "3. You can also trigger it manually from the GitHub Actions UI"
        echo "4. If you want to initialize package versions, run: ./scripts/init-versions.sh"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

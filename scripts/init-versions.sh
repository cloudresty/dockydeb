#!/bin/bash

# DockyDEB Version Initialization Script
# This script initializes the package-versions.json file with current versions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSIONS_FILE="$PROJECT_ROOT/package-versions.json"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Function to get current package versions
init_package_versions() {
    log_info "Initializing package versions..."
    
    # Create a temporary container to get current package versions
    local temp_container="dockydeb-init-$$"
    
    log_info "Creating temporary container..."
    docker run -d --name "$temp_container" debian:bookworm-slim sleep 300 >/dev/null
    
    # Update package lists
    docker exec "$temp_container" apt-get update >/dev/null 2>&1
    
    # Get base image digest
    local base_digest
    base_digest=$(docker inspect debian:bookworm-slim --format='{{.Id}}' 2>/dev/null || echo "")
    
    # Get package versions
    local packages=(
        "curl" "dnsutils" "git" "iputils-ping" "gnupg" 
        "htop" "btop" "jq" "net-tools" "ncdu" "telnet" 
        "unzip" "vim" "wget" "zsh" "zip"
    )
    
    # Start building the JSON
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$VERSIONS_FILE" << EOF
{
  "last_updated": "$timestamp",
  "base_image": {
    "name": "debian:bookworm-slim",
    "digest": "$base_digest",
    "last_checked": "$timestamp"
  },
  "packages": {
EOF
    
    local first=true
    for package in "${packages[@]}"; do
        local version
        version=$(docker exec "$temp_container" apt-cache policy "$package" 2>/dev/null | \
            grep "Candidate:" | awk '{print $2}' || echo "unknown")
        
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$VERSIONS_FILE"
        fi
        
        echo -n "    \"$package\": \"$version\"" >> "$VERSIONS_FILE"
        log_info "Package $package: $version"
    done
    
    cat >> "$VERSIONS_FILE" << EOF

  },
  "git_repositories": {
    "ohmyzsh": {
      "url": "https://github.com/ohmyzsh/ohmyzsh.git",
      "commit_sha": "",
      "last_checked": ""
    },
    "powerlevel10k": {
      "url": "https://github.com/romkatv/powerlevel10k.git",
      "commit_sha": "",
      "last_checked": ""
    },
    "zsh-autosuggestions": {
      "url": "https://github.com/zsh-users/zsh-autosuggestions.git",
      "commit_sha": "",
      "last_checked": ""
    },
    "zsh-syntax-highlighting": {
      "url": "https://github.com/zsh-users/zsh-syntax-highlighting.git",
      "commit_sha": "",
      "last_checked": ""
    }
  }
}
EOF
    
    # Get git repository SHAs
    local repos=(
        "ohmyzsh:https://github.com/ohmyzsh/ohmyzsh.git"
        "powerlevel10k:https://github.com/romkatv/powerlevel10k.git"
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions.git"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
    )
    
    for repo_info in "${repos[@]}"; do
        local repo_name="${repo_info%%:*}"
        local repo_url="${repo_info#*:}"
        
        local api_url="https://api.github.com/repos/${repo_url#https://github.com/}"
        api_url="${api_url%.git}/commits/HEAD"
        
        local latest_sha
        latest_sha=$(curl -s "$api_url" | jq -r '.sha // empty' 2>/dev/null || echo "")
        
        if [[ -n "$latest_sha" ]]; then
            # Update the JSON file
            jq --arg repo "$repo_name" --arg sha "$latest_sha" --arg timestamp "$timestamp" \
                '.git_repositories[$repo].commit_sha = $sha | .git_repositories[$repo].last_checked = $timestamp' \
                "$VERSIONS_FILE" > "${VERSIONS_FILE}.tmp" && mv "${VERSIONS_FILE}.tmp" "$VERSIONS_FILE"
            log_info "Git repo $repo_name: $latest_sha"
        fi
    done
    
    # Cleanup
    docker rm -f "$temp_container" >/dev/null 2>&1
    
    log_success "Package versions initialized in $VERSIONS_FILE"
}

# Main function
main() {
    log_info "Initializing DockyDEB package versions..."
    
    # Check dependencies
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "Error: docker is required but not installed."
        exit 1
    fi
    
    init_package_versions
    
    log_success "Initialization complete!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

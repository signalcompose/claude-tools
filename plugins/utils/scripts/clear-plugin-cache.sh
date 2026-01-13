#!/bin/bash

# Clear Plugin Cache - Workaround for Claude Code cache invalidation bug
# https://github.com/anthropics/claude-code/issues/14061

set -e

# Default values
MARKETPLACE="claude-tools"
MARKETPLACE_SPECIFIED=false
PLUGIN_NAME=""
ALL_PLUGINS=false
DRY_RUN=false
CACHE_BASE_DIR="$HOME/.claude/plugins/cache"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show usage
usage() {
    cat << EOF
Usage: clear-plugin-cache <plugin-name> [options]
       clear-plugin-cache --all --marketplace <name>

Clear plugin cache to fix stale version issues.

Arguments:
  plugin-name              Name of the plugin to clear cache for

Options:
  --marketplace <name>     Marketplace name (default: claude-tools)
  --all                    Clear all plugin caches for the marketplace
  --dry-run                Show what would be deleted without deleting
  -h, --help               Show this help message

Examples:
  clear-plugin-cache cvi
  clear-plugin-cache cvi --dry-run
  clear-plugin-cache plugin --marketplace other-market
  clear-plugin-cache --all --marketplace claude-tools
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --marketplace)
            MARKETPLACE="$2"
            MARKETPLACE_SPECIFIED=true
            shift 2
            ;;
        --all)
            ALL_PLUGINS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [[ -z "$PLUGIN_NAME" ]]; then
                PLUGIN_NAME="$1"
            else
                print_error "Unexpected argument: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ "$ALL_PLUGINS" == true ]]; then
    if [[ "$MARKETPLACE_SPECIFIED" == false ]]; then
        # --all requires explicit --marketplace for safety
        print_error "--all requires --marketplace to be explicitly specified"
        echo ""
        echo "Example: clear-plugin-cache --all --marketplace claude-tools"
        exit 1
    fi
elif [[ -z "$PLUGIN_NAME" ]]; then
    print_error "Plugin name is required (or use --all with --marketplace)"
    echo ""
    usage
    exit 1
fi

# Build cache path
MARKETPLACE_CACHE_DIR="$CACHE_BASE_DIR/$MARKETPLACE"

# Check if marketplace cache directory exists
if [[ ! -d "$MARKETPLACE_CACHE_DIR" ]]; then
    print_warning "Marketplace cache directory not found: $MARKETPLACE_CACHE_DIR"
    exit 0
fi

# Function to get directory size
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# Function to delete a plugin cache
delete_plugin_cache() {
    local plugin_dir="$1"
    local plugin_name=$(basename "$plugin_dir")
    local size=$(get_dir_size "$plugin_dir")

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would delete: $plugin_dir ($size)"
    else
        rm -rf "$plugin_dir"
        print_success "Deleted: $plugin_dir ($size)"
    fi
}

# Clear cache
if [[ "$ALL_PLUGINS" == true ]]; then
    # Confirmation for --all
    if [[ "$DRY_RUN" == false ]]; then
        echo ""
        print_warning "This will delete ALL plugin caches for marketplace: $MARKETPLACE"
        echo ""

        # List plugins to be deleted
        plugin_count=0
        for plugin_dir in "$MARKETPLACE_CACHE_DIR"/*; do
            if [[ -d "$plugin_dir" ]]; then
                echo "  - $(basename "$plugin_dir") ($(get_dir_size "$plugin_dir"))"
                ((plugin_count++))
            fi
        done

        if [[ $plugin_count -eq 0 ]]; then
            print_warning "No plugin caches found"
            exit 0
        fi

        echo ""
        read -p "Are you sure you want to delete $plugin_count plugin cache(s)? [y/N] " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cancelled"
            exit 0
        fi
    fi

    # Delete all plugins
    for plugin_dir in "$MARKETPLACE_CACHE_DIR"/*; do
        if [[ -d "$plugin_dir" ]]; then
            delete_plugin_cache "$plugin_dir"
        fi
    done
else
    # Single plugin
    PLUGIN_CACHE_DIR="$MARKETPLACE_CACHE_DIR/$PLUGIN_NAME"

    if [[ ! -d "$PLUGIN_CACHE_DIR" ]]; then
        print_warning "Plugin cache not found: $PLUGIN_CACHE_DIR"
        echo ""
        echo "Available plugins in $MARKETPLACE:"
        for plugin_dir in "$MARKETPLACE_CACHE_DIR"/*; do
            if [[ -d "$plugin_dir" ]]; then
                echo "  - $(basename "$plugin_dir")"
            fi
        done
        exit 0
    fi

    delete_plugin_cache "$PLUGIN_CACHE_DIR"
fi

# Final message
echo ""
if [[ "$DRY_RUN" == true ]]; then
    print_info "Dry run complete. No files were deleted."
else
    print_success "Cache cleared successfully!"
    echo ""
    print_info "Please restart Claude Code for changes to take effect."
fi

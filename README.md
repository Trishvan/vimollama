# vimollama

🧠 A smart, offline code generation plugin for Vim using your local `llama3.2` model via [Ollama](https://ollama.com/).  
Inspired by [Cursor](https://www.cursor.so), this plugin brings AI completions, suggestions, and code generation — powered by your full repo context — right into Vim.

---
## Features

- **Code Completion**: Intelligent code completion based on project context
- **Code Explanation**: Get explanations for complex code sections
- **Interactive Chat**: Ask questions about your code
- **Bug Detection**: Automatic detection and suggestions for code issues  
- **Test Generation**: Generate unit tests for your functions
- **Multi-language Support**: Works with C++, Go, Python, JavaScript, TypeScript, Java, Rust, Ruby
- **Asyncomplete Integration**: Seamless integration with Vim's completion system
- **Project Context Awareness**: Uses entire project context for better suggestions
---
## Prerequisites

- **Go 1.19+** - For building the agent
- **Vim 8.0+** - With job support for async operations
- **Ollama** - For running local LLaMA models
- **Git** - For cloning the repository
---
## Quick Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/llama-agent-vim.git
cd llama-agent-vim

# Install everything
make install

# Or use the installation script
chmod +x install.sh
./install.sh
```

## Manual Installation

### 1. Install Ollama

```bash
# On macOS/Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve

# Pull the LLaMA model
ollama pull llama3.2
```

### 2. Build and Install the Agent

```bash
# Build the Go binary
make build

# Install binary and Vim plugin
make install
```

### 3. Configure Vim

Add to your `~/.vimrc`:

```vim
" Basic configuration
let g:llama_agent_path = '/usr/local/bin/llama-agent'
let g:llama_agent_model = 'llama3.2'
let g:llama_auto_complete = 0  " Enable auto-completion
let g:llama_show_progress = 1

" Optional: Enable asyncomplete integration
call asyncomplete#sources#llama#register()
```

## Usage

### Key Mappings

In supported file types (C++, Go, Python, etc.):

- `<leader>lc` - Complete code at cursor
- `<Ctrl-l>` - Inline completion (insert mode)
- `<leader>le` - Explain current code
- `<leader>lq` - Ask question about code
- `<leader>lf` - Suggest fixes for code issues
- `<leader>lt` - Generate unit tests
- `<leader>ls` - Show LLaMA status
- `<leader>lr` - Restart/reload configuration

### Commands

- `:LlamaComplete` - Trigger code completion
- `:LlamaExplain` - Explain code at cursor
- `:LlamaChat` - Start interactive chat about code
- `:LlamaFix` - Get suggestions for code improvements
- `:LlamaTest` - Generate unit tests
- `:LlamaStatus` - Show current configuration and status
- `:LlamaToggleAuto` - Toggle auto-completion
- `:LlamaHelp` - Show help documentation

### Command Line Usage

The `llama-agent` binary can also be used independently:

```bash
# Complete code at specific position
llama-agent complete main.cpp 42 10

# Chat about code
llama-agent chat main.cpp "How can I optimize this function?"

# Explain code
llama-agent explain main.cpp 25

# Suggest fixes
llama-agent fix main.cpp

# Generate tests
llama-agent test main.cpp

# Show configuration
llama-agent config
```

## Configuration

### Global Configuration

Edit `~/.llama-agent.json`:

```json
{
  "model": "llama3.2",
  "temperature": 0.3,
  "max_tokens": 500,
  "context_lines": 50,
  "timeout_seconds": 30,
  "project_root": "",
  "enable_logging": false
}
```

### Vim Configuration Options

```vim
" Path to llama-agent binary
let g:llama_agent_path = '/usr/local/bin/llama-agent'

" Model to use (must be available in Ollama)
let g:llama_agent_model = 'llama3.2'

" Enable automatic completion on typing
let g:llama_auto_complete = 0

" Show progress messages
let g:llama_show_progress = 1
```

## Supported Models

Any model available in Ollama can be used. Popular choices:

- `llama3.2` - General purpose, good balance
- `codellama` - Specialized for code
- `deepseek-coder` - Excellent for programming
- `starcoder` - Focused on code completion

Install models with:
```bash
ollama pull llama3.2
ollama pull codellama
```

## Project Structure

```
llama-agent-vim/
├── server/
│   └── main.go              # Go backend agent
├── plugin/
│   └── llama.vim           # Main Vim plugin
├── autoload/
│   └── asyncomplete/
│       └── sources/
│           └── llama.vim   # Asyncomplete integration
├── Makefile                # Build and installation
├── install.sh             # Installation script
└── README.md
```

## Development

### Building from Source

```bash
# Install development version
make dev-install

# Run tests
make test

# Cross-compile for different platforms
make build-all

# Clean build artifacts
make clean
```

### Adding New Features

1. **Backend changes**: Edit `server/main.go`
2. **Vim integration**: Edit `plugin/llama.vim`
3. **Completion source**: Edit `autoload/asyncomplete/sources/llama.vim`

### Testing

```bash
# Test the agent directly
llama-agent config
llama-agent complete test.cpp

# Test in Vim
vim test.cpp
:LlamaStatus
:LlamaComplete
```

## Troubleshooting

### Common Issues

**Agent not found**
```bash
# Check if installed
which llama-agent
# Reinstall if needed
make install
```

**Ollama not responding**
```bash
# Check if Ollama is running
ps aux | grep ollama
# Start if needed
ollama serve
```

**No completions**
```bash
# Check model availability
ollama list
# Pull model if needed
ollama pull llama3.2
```

**Vim plugin not working**
```vim
" Check plugin status in Vim
:LlamaStatus
:LlamaHelp
```

### Debug Mode

Enable logging in `~/.llama-agent.json`:
```json
{
  "enable_logging": true
}
```

Check logs at `/tmp/llama-agent.log`

## Performance Tips

1. **Use SSD storage** - Faster model loading
2. **Adequate RAM** - Models need 4-8GB RAM
3. **Limit context** - Reduce `context_lines` for faster responses
4. **Choose appropriate model** - Smaller models respond faster

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- Original [vim-ollama](https://github.com/gergap/vim-ollama) by gergap
- [Ollama](https://ollama.ai) for local LLM inference
- The Vim community for asyncomplete and plugin architecture

---

# Installation Script

Create `install.sh`:

```bash
#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/bin"
VIM_PLUGIN_DIR="$HOME/.vim/pack/llama/start/vim-llama"
CONFIG_FILE="$HOME/.llama-agent.json"
BINARY_NAME="llama-agent"
BUILD_DIR="build"
SOURCE_DIR="server"

# Logging functions
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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check Go
    if ! command_exists go; then
        log_error "Go is not installed. Please install Go 1.19+ from https://golang.org/"
        exit 1
    fi
    log_success "Go found: $(go version)"
    
    # Check Vim
    if ! command_exists vim; then
        log_error "Vim is not installed. Please install Vim 8.0+"
        exit 1
    fi
    log_success "Vim found: $(vim --version | head -n1)"
    
    # Check Ollama
    if ! command_exists ollama; then
        log_warning "Ollama not found. Please install from https://ollama.ai/"
        log_warning "Installation will continue, but you'll need Ollama to use the agent"
    else
        log_success "Ollama found"
    fi
    
    # Check Git
    if ! command_exists git; then
        log_warning "Git not found. Some features may not work properly"
    else
        log_success "Git found: $(git --version)"
    fi
}

# Build the agent
build_agent() {
    log_info "Building llama-agent..."
    
    if [ ! -d "$SOURCE_DIR" ]; then
        log_error "Source directory '$SOURCE_DIR' not found. Are you in the project root?"
        exit 1
    fi
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # Get version from git or use 'dev'
    VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")
    LDFLAGS="-ldflags \"-X main.Version=$VERSION\""
    
    # Build the binary
    cd "$SOURCE_DIR"
    eval "go build $LDFLAGS -o ../$BUILD_DIR/$BINARY_NAME ."
    cd ..
    
    if [ ! -f "$BUILD_DIR/$BINARY_NAME" ]; then
        log_error "Build failed. Binary not found at $BUILD_DIR/$BINARY_NAME"
        exit 1
    fi
    
    log_success "Build complete: $BUILD_DIR/$BINARY_NAME"
}

# Install binary
install_binary() {
    log_info "Installing binary to $INSTALL_DIR..."
    
    # Check if we need sudo
    if [ ! -w "$INSTALL_DIR" ]; then
        log_info "Need sudo privileges to install to $INSTALL_DIR"
        sudo cp "$BUILD_DIR/$BINARY_NAME" "$INSTALL_DIR/"
        sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
    else
        cp "$BUILD_DIR/$BINARY_NAME" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/$BINARY_NAME"
    fi
    
    log_success "Binary installed to $INSTALL_DIR/$BINARY_NAME"
}

# Install Vim plugin
install_vim_plugin() {
    log_info "Installing Vim plugin..."
    
    # Create plugin directories
    mkdir -p "$VIM_PLUGIN_DIR/plugin"
    mkdir -p "$VIM_PLUGIN_DIR/autoload/asyncomplete/sources"
    mkdir -p "$VIM_PLUGIN_DIR/doc"
    
    # Copy plugin files
    if [ -f "plugin/llama.vim" ]; then
        cp "plugin/llama.vim" "$VIM_PLUGIN_DIR/plugin/"
        log_success "Main plugin installed"
    else
        log_warning "plugin/llama.vim not found, skipping main plugin"
    fi
    
    if [ -f "autoload/asyncomplete/sources/llama.vim" ]; then
        cp "autoload/asyncomplete/sources/llama.vim" "$VIM_PLUGIN_DIR/autoload/asyncomplete/sources/"
        log_success "Asyncomplete integration installed"
    else
        log_warning "Asyncomplete integration not found, skipping"
    fi
    
    # Copy documentation if it exists
    if [ -f "doc/llama.txt" ]; then
        cp "doc/llama.txt" "$VIM_PLUGIN_DIR/doc/"
    fi
    
    log_success "Vim plugin installed to $VIM_PLUGIN_DIR"
}

# Create default configuration
create_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_info "Creating default configuration..."
        cat > "$CONFIG_FILE" << EOF
{
  "model": "llama3.2",
  "temperature": 0.3,
  "max_tokens": 500,
  "context_lines": 50,
  "timeout_seconds": 30,
  "project_root": "",
  "enable_logging": false
}
EOF
        log_success "Default config created at $CONFIG_FILE"
    else
        log_info "Configuration file already exists at $CONFIG_FILE"
    fi
}

# Check Ollama setup
check_ollama_setup() {
    if command_exists ollama; then
        log_info "Checking Ollama setup..."
        
        # Check if Ollama is running
        if ! pgrep -f "ollama serve" > /dev/null 2>&1; then
            log_warning "Ollama server doesn't appear to be running"
            log_info "You may need to start it with: ollama serve"
        else
            log_success "Ollama server is running"
        fi
        
        # Check if llama3.2 model is available
        if ollama list 2>/dev/null | grep -q "llama3.2"; then
            log_success "llama3.2 model is available"
        else
            log_warning "llama3.2 model not found"
            log_info "You can install it with: ollama pull llama3.2"
        fi
    fi
}

# Test installation
test_installation() {
    log_info "Testing installation..."
    
    # Test binary
    if command_exists "$BINARY_NAME"; then
        log_success "Binary is accessible from PATH"
        
        # Test config command
        if "$BINARY_NAME" config >/dev/null 2>&1; then
            log_success "Agent responds to config command"
        else
            log_warning "Agent config command failed (this is normal if Ollama isn't set up)"
        fi
    else
        log_error "Binary not found in PATH"
        log_error "Make sure $INSTALL_DIR is in your PATH"
        return 1
    fi
    
    # Test Vim plugin
    if [ -f "$VIM_PLUGIN_DIR/plugin/llama.vim" ]; then
        log_success "Vim plugin files are in place"
    else
        log_warning "Vim plugin files not found"
    fi
}

# Print next steps
print_next_steps() {
    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "1. Make sure Ollama is running:"
    echo "   ollama serve"
    echo ""
    echo "2. Pull the LLaMA model:"
    echo "   ollama pull llama3.2"
    echo ""
    echo "3. Test the installation:"
    echo "   $BINARY_NAME config"
    echo ""
    echo "4. In Vim, try these commands:"
    echo "   :LlamaHelp"
    echo "   :LlamaStatus"
    echo ""
    echo "5. Add to your ~/.vimrc:"
    echo "   let g:llama_agent_path = '$INSTALL_DIR/$BINARY_NAME'"
    echo "   let g:llama_agent_model = 'llama3.2'"
    echo ""
    echo "For more information, see the README.md file."
}

# Main installation function
main() {
    echo "LLaMA Agent Installer"
    echo "===================="
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "README.md" ] || [ ! -d "$SOURCE_DIR" ]; then
        log_error "Please run this script from the project root directory"
        log_error "Expected to find README.md and $SOURCE_DIR/ directory"
        exit 1
    fi
    
    # Run installation steps
    check_dependencies
    build_agent
    install_binary
    install_vim_plugin
    create_config
    check_ollama_setup
    test_installation
    print_next_steps
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --uninstall    Uninstall llama-agent"
        echo ""
        exit 0
        ;;
    --uninstall)
        log_info "Uninstalling llama-agent..."
        sudo rm -f "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || rm -f "$INSTALL_DIR/$BINARY_NAME"
        rm -rf "$VIM_PLUGIN_DIR"
        log_info "You may also want to remove $CONFIG_FILE"
        log_success "Uninstall complete"
        exit 0
        ;;
    "")
        # No arguments, proceed with installation
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
```
---

## 🤝 Contributing

Pull requests welcome!

Ideas for contributions:

* Add more languages
* Improve context windowing
* Add chat/refactor modes
* Visual block-based completions


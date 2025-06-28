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
    
    if [ ! -d "server" ]; then
        log_
---

## 🤝 Contributing

Pull requests welcome!

Ideas for contributions:

* Add more languages
* Improve context windowing
* Add chat/refactor modes
* Visual block-based completions


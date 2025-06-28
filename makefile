# Makefile for llama-agent

.PHONY: build install clean test help

BINARY_NAME=llama-agent
BUILD_DIR=build
SOURCE_DIR=server
INSTALL_DIR=/usr/local/bin
VIM_PLUGIN_DIR=~/.vim/pack/llama/start/vim-llama

# Go build settings
GOOS?=$(shell go env GOOS)
GOARCH?=$(shell go env GOARCH)
VERSION?=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS=-ldflags "-X main.Version=$(VERSION)"

# Default target
help:
	@echo "LLaMA Agent Build System"
	@echo "========================"
	@echo ""
	@echo "Available targets:"
	@echo "  build      - Build the llama-agent binary"
	@echo "  install    - Install binary and Vim plugin"
	@echo "  clean      - Clean build artifacts"
	@echo "  test       - Run tests"
	@echo "  uninstall  - Remove installed files"
	@echo "  check      - Check dependencies"
	@echo ""
	@echo "Configuration:"
	@echo "  INSTALL_DIR=$(INSTALL_DIR)"
	@echo "  VIM_PLUGIN_DIR=$(VIM_PLUGIN_DIR)"

# Build the Go binary
build:
	@echo "Building llama-agent..."
	@mkdir -p $(BUILD_DIR)
	cd $(SOURCE_DIR) && go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME) .
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

# Install binary and Vim plugin
install: build check-ollama
	@echo "Installing llama-agent..."
	
	# Install binary
	sudo cp $(BUILD_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/
	sudo chmod +x $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Binary installed to $(INSTALL_DIR)/$(BINARY_NAME)"
	
	# Install Vim plugin
	@echo "Installing Vim plugin..."
	mkdir -p $(VIM_PLUGIN_DIR)/plugin
	mkdir -p $(VIM_PLUGIN_DIR)/autoload/asyncomplete/sources
	cp plugin/llama.vim $(VIM_PLUGIN_DIR)/plugin/
	cp autoload/asyncomplete/sources/llama.vim $(VIM_PLUGIN_DIR)/autoload/asyncomplete/sources/
	@echo "Vim plugin installed to $(VIM_PLUGIN_DIR)"
	
	# Create default config
	@if [ ! -f ~/.llama-agent.json ]; then \
		echo "Creating default configuration..."; \
		echo '{"model": "llama3.2", "temperature": 0.3, "max_tokens": 500, "context_lines": 50, "timeout_seconds": 30}' > ~/.llama-agent.json; \
		echo "Default config created at ~/.llama-agent.json"; \
	fi
	
	@echo ""
	@echo "Installation complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Make sure Ollama is running: ollama serve"
	@echo "2. Pull the model: ollama pull llama3.2"
	@echo "3. Test the installation: llama-agent config"
	@echo "4. In Vim, try: :LlamaHelp"

# Check dependencies
check:
	@echo "Checking dependencies..."
	@command -v go >/dev/null 2>&1 || { echo "Go is required but not installed. Please install Go 1.19+"; exit 1; }
	@echo "✓ Go found: $$(go version)"

check-ollama:
	@echo "Checking Ollama..."
	@command -v ollama >/dev/null 2>&1 || { echo "⚠ Ollama not found. Please install Ollama from https://ollama.ai"; }
	@if command -v ollama >/dev/null 2>&1; then \
		echo "✓ Ollama found: $$(ollama --version 2>/dev/null || echo 'version unknown')"; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	cd $(SOURCE_DIR) && go clean
	@echo "Clean complete"

# Run tests
test:
	@echo "Running tests..."
	cd $(SOURCE_DIR) && go test -v ./...

# Uninstall
uninstall:
	@echo "Uninstalling llama-agent..."
	sudo rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	rm -rf $(VIM_PLUGIN_DIR)
	@echo "Uninstall complete"

# Development targets
dev-build: 
	cd $(SOURCE_DIR) && go build -race -o ../$(BUILD_DIR)/$(BINARY_NAME)-dev .

dev-install: dev-build
	cp $(BUILD_DIR)/$(BINARY_NAME)-dev $(INSTALL_DIR)/$(BINARY_NAME)
	chmod +x $(INSTALL_DIR)/$(BINARY_NAME)

# Cross-compilation targets
build-linux:
	GOOS=linux GOARCH=amd64 cd $(SOURCE_DIR) && go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 .

build-macos:
	GOOS=darwin GOARCH=amd64 cd $(SOURCE_DIR) && go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 .
	GOOS=darwin GOARCH=arm64 cd $(SOURCE_DIR) && go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 .

build-windows:
	GOOS=windows GOARCH=amd64 cd $(SOURCE_DIR) && go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe .

build-all: build-linux build-macos build-windows
	@echo "Cross-compilation complete"

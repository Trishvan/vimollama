package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// Config holds the configuration for the agent
type Config struct {
	Model           string `json:"model"`
	Temperature     float64 `json:"temperature"`
	MaxTokens       int    `json:"max_tokens"`
	ContextLines    int    `json:"context_lines"`
	ProjectRoot     string `json:"project_root"`
	EnableLogging   bool   `json:"enable_logging"`
	Timeout         int    `json:"timeout_seconds"`
}

// CompletionRequest represents a request for code completion
type CompletionRequest struct {
	FilePath    string
	Content     string
	CursorLine  int
	CursorCol   int
	Mode        string
	Language    string
}

// CompletionResponse represents the AI's response
type CompletionResponse struct {
	Content     string `json:"content"`
	Language    string `json:"language"`
	Confidence  float64 `json:"confidence,omitempty"`
	Error       string `json:"error,omitempty"`
}

var defaultConfig = Config{
	Model:        "starcoder2:latest",
	Temperature:  0.3,
	MaxTokens:    500,
	ContextLines: 50,
	Timeout:      30,
}

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	config := loadConfig()
	
	switch os.Args[1] {
	case "complete":
		handleComplete(config)
	case "chat":
		handleChat(config)
	case "explain":
		handleExplain(config)
	case "fix":
		handleFix(config)
	case "test":
		handleTest(config)
	case "config":
		handleConfig()
	default:
		fmt.Printf("Unknown command: %s\n", os.Args[1])
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(`llama-agent - AI coding assistant

Usage:
  llama-agent complete <file> [line] [col]  - Complete code at cursor position
  llama-agent chat <file> <prompt>          - Chat about the code
  llama-agent explain <file> [line]         - Explain code or function
  llama-agent fix <file>                    - Suggest fixes for errors
  llama-agent test <file>                   - Generate unit tests
  llama-agent config                        - Show current configuration

Examples:
  llama-agent complete main.cpp 42 10
  llama-agent chat main.cpp "How can I optimize this function?"
  llama-agent explain main.cpp 25
  llama-agent fix main.cpp`)
}

func loadConfig() Config {
	config := defaultConfig
	
	configPath := filepath.Join(os.Getenv("HOME"), ".llama-agent.json")
	if data, err := ioutil.ReadFile(configPath); err == nil {
		json.Unmarshal(data, &config)
	}
	
	// Set project root to current directory if not specified
	if config.ProjectRoot == "" {
		if pwd, err := os.Getwd(); err == nil {
			config.ProjectRoot = pwd
		}
	}
	
	return config
}

func handleComplete(config Config) {
	if len(os.Args) < 3 {
		fmt.Println("Error: file path required")
		os.Exit(1)
	}
	
	filePath := os.Args[2]
	cursorLine := 0
	cursorCol := 0
	
	// Parse optional cursor position
	if len(os.Args) >= 4 {
		fmt.Sscanf(os.Args[3], "%d", &cursorLine)
	}
	if len(os.Args) >= 5 {
		fmt.Sscanf(os.Args[4], "%d", &cursorCol)
	}
	
	request := CompletionRequest{
		FilePath:   filePath,
		CursorLine: cursorLine,
		CursorCol:  cursorCol,
		Mode:       "complete",
		Language:   detectLanguage(filePath),
	}
	
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		os.Exit(1)
	}
	request.Content = string(content)
	
	response := processCompletion(config, request)
	if response.Error != "" {
		fmt.Printf("Error: %s\n", response.Error)
		os.Exit(1)
	}
	
	fmt.Print(response.Content)
}

func handleChat(config Config) {
	if len(os.Args) < 4 {
		fmt.Println("Error: file path and prompt required")
		os.Exit(1)
	}
	
	filePath := os.Args[2]
	prompt := strings.Join(os.Args[3:], " ")
	
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		os.Exit(1)
	}
	
	request := CompletionRequest{
		FilePath: filePath,
		Content:  string(content),
		Mode:     "chat",
		Language: detectLanguage(filePath),
	}
	
	fullPrompt := fmt.Sprintf("Question about this %s code: %s", request.Language, prompt)
	response := processCompletion(config, request, fullPrompt)
	
	if response.Error != "" {
		fmt.Printf("Error: %s\n", response.Error)
		os.Exit(1)
	}
	
	fmt.Print(response.Content)
}

func handleExplain(config Config) {
	if len(os.Args) < 3 {
		fmt.Println("Error: file path required")
		os.Exit(1)
	}
	
	filePath := os.Args[2]
	targetLine := 0
	
	if len(os.Args) >= 4 {
		fmt.Sscanf(os.Args[3], "%d", &targetLine)
	}
	
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		os.Exit(1)
	}
	
	request := CompletionRequest{
		FilePath:   filePath,
		Content:    string(content),
		CursorLine: targetLine,
		Mode:       "explain",
		Language:   detectLanguage(filePath),
	}
	
	response := processCompletion(config, request)
	if response.Error != "" {
		fmt.Printf("Error: %s\n", response.Error)
		os.Exit(1)
	}
	
	fmt.Print(response.Content)
}

func handleFix(config Config) {
	if len(os.Args) < 3 {
		fmt.Println("Error: file path required")
		os.Exit(1)
	}
	
	filePath := os.Args[2]
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		os.Exit(1)
	}
	
	request := CompletionRequest{
		FilePath: filePath,
		Content:  string(content),
		Mode:     "fix",
		Language: detectLanguage(filePath),
	}
	
	response := processCompletion(config, request)
	if response.Error != "" {
		fmt.Printf("Error: %s\n", response.Error)
		os.Exit(1)
	}
	
	fmt.Print(response.Content)
}

func handleTest(config Config) {
	if len(os.Args) < 3 {
		fmt.Println("Error: file path required")
		os.Exit(1)
	}
	
	filePath := os.Args[2]
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		os.Exit(1)
	}
	
	request := CompletionRequest{
		FilePath: filePath,
		Content:  string(content),
		Mode:     "test",
		Language: detectLanguage(filePath),
	}
	
	response := processCompletion(config, request)
	if response.Error != "" {
		fmt.Printf("Error: %s\n", response.Error)
		os.Exit(1)
	}
	
	fmt.Print(response.Content)
}

func handleConfig() {
	config := loadConfig()
	data, _ := json.MarshalIndent(config, "", "  ")
	fmt.Println(string(data))
}

func processCompletion(config Config, request CompletionRequest, customPrompt ...string) CompletionResponse {
	// Collect project context
	context := collectProjectContext(config, request.FilePath)
	
	// Build prompt based on mode
	var prompt string
	if len(customPrompt) > 0 {
		prompt = buildCustomPrompt(request, context, customPrompt[0])
	} else {
		prompt = buildPrompt(config, request, context)
	}
	
	// Call Ollama
	output, err := callOllama(config, prompt)
	if err != nil {
		return CompletionResponse{Error: err.Error()}
	}
	
	// Clean and format output
	cleanOutput := cleanOutput(output, request.Mode)
	
	return CompletionResponse{
		Content:  cleanOutput,
		Language: request.Language,
	}
}

func collectProjectContext(config Config, targetFile string) string {
	var contextBuilder strings.Builder
	var fileCount int
	maxFiles := 20 // Limit context to avoid overwhelming the model
	
	err := filepath.Walk(config.ProjectRoot, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() || fileCount >= maxFiles {
			return nil
		}
		
		// Skip certain directories
		if strings.Contains(path, "/.git/") || strings.Contains(path, "/build/") || 
		   strings.Contains(path, "/node_modules/") || strings.Contains(path, "/.vscode/") {
			return nil
		}
		
		// Include relevant source files
		if isRelevantFile(path) && path != targetFile {
			data, err := ioutil.ReadFile(path)
			if err != nil {
				return nil
			}
			
			// Limit file size to avoid overwhelming context
			content := string(data)
			if len(content) > 2000 {
				content = content[:2000] + "\n// ... (truncated)"
			}
			
			relPath, _ := filepath.Rel(config.ProjectRoot, path)
			contextBuilder.WriteString(fmt.Sprintf("// File: %s\n%s\n\n", relPath, content))
			fileCount++
		}
		return nil
	})
	
	if err != nil {
		log.Printf("Warning: error walking project directory: %v", err)
	}
	
	return contextBuilder.String()
}

func isRelevantFile(path string) bool {
	extensions := []string{".cpp", ".cc", ".cxx", ".c", ".h", ".hpp", ".hxx", 
					     ".go", ".py", ".js", ".ts", ".java", ".rs", ".rb"}
	
	for _, ext := range extensions {
		if strings.HasSuffix(path, ext) {
			return true
		}
	}
	return false
}

func detectLanguage(filePath string) string {
	ext := strings.ToLower(filepath.Ext(filePath))
	switch ext {
	case ".cpp", ".cc", ".cxx":
		return "cpp"
	case ".c":
		return "c"
	case ".h", ".hpp", ".hxx":
		return "cpp" // Treat headers as C++
	case ".go":
		return "go"
	case ".py":
		return "python"
	case ".js":
		return "javascript"
	case ".ts":
		return "typescript"
	case ".java":
		return "java"
	case ".rs":
		return "rust"
	case ".rb":
		return "ruby"
	default:
		return "text"
	}
}

func buildPrompt(config Config, request CompletionRequest, context string) string {
	switch request.Mode {
	case "complete":
		return buildCompletePrompt(request, context)
	case "explain":
		return buildExplainPrompt(request, context)
	case "fix":
		return buildFixPrompt(request, context)
	case "test":
		return buildTestPrompt(request, context)
	default:
		return buildCompletePrompt(request, context)
	}
}

func buildCustomPrompt(request CompletionRequest, context string, customPrompt string) string {
	return fmt.Sprintf(`You are an expert %s developer. Here's the project context:

%s

Current file: %s
%s

%s

Please provide a helpful response.`, 
		request.Language, context, request.FilePath, request.Content, customPrompt)
}

func buildCompletePrompt(request CompletionRequest, context string) string {
	lines := strings.Split(request.Content, "\n")
	
	// Get context around cursor position
	startLine := max(0, request.CursorLine-10)
	endLine := min(len(lines), request.CursorLine+5)
	
	beforeCursor := strings.Join(lines[startLine:request.CursorLine], "\n")
	afterCursor := ""
	if request.CursorLine < len(lines) {
		afterCursor = strings.Join(lines[request.CursorLine:endLine], "\n")
	}
	
	return fmt.Sprintf(`You are an expert %s developer. Complete the code at the cursor position.

Project context:
%s

Current file content before cursor (line %d):
%s

Current file content after cursor:
%s

Complete the code at the cursor position. Provide only the completion, no explanations.`,
		request.Language, context, request.CursorLine+1, beforeCursor, afterCursor)
}

func buildExplainPrompt(request CompletionRequest, context string) string {
	return fmt.Sprintf(`You are an expert %s developer. Explain the code in this file.

Project context:
%s

File to explain: %s
%s

Provide a clear explanation of what this code does, focusing on the main functionality and any complex parts.`,
		request.Language, context, request.FilePath, request.Content)
}

func buildFixPrompt(request CompletionRequest, context string) string {
	return fmt.Sprintf(`You are an expert %s developer. Review this code and suggest fixes for any issues.

Project context:
%s

File to review: %s
%s

Identify potential bugs, code quality issues, or improvements. Provide specific suggestions with code examples.`,
		request.Language, context, request.FilePath, request.Content)
}

func buildTestPrompt(request CompletionRequest, context string) string {
	return fmt.Sprintf(`You are an expert %s developer. Generate unit tests for this code.

Project context:
%s

File to test: %s
%s

Generate comprehensive unit tests that cover the main functionality. Use appropriate testing frameworks for %s.`,
		request.Language, context, request.FilePath, request.Content, request.Language)
}

func callOllama(config Config, prompt string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(config.Timeout)*time.Second)
	defer cancel()
	
	cmd := exec.CommandContext(ctx, "ollama", "run", config.Model)
	cmd.Stdin = strings.NewReader(prompt)
	
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	
	err := cmd.Run()
	if err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			return "", fmt.Errorf("ollama request timed out after %d seconds", config.Timeout)
		}
		return "", fmt.Errorf("ollama error: %v - %s", err, stderr.String())
	}
	
	return stdout.String(), nil
}

func cleanOutput(output, mode string) string {
	// Remove common AI response prefixes
	cleaners := []string{
		"Here's the completion:",
		"Here's the code:",
		"```" + detectLanguageFromOutput(output),
		"```",
	}
	
	cleaned := strings.TrimSpace(output)
	for _, prefix := range cleaners {
		cleaned = strings.TrimPrefix(cleaned, prefix)
		cleaned = strings.TrimSuffix(cleaned, prefix)
		cleaned = strings.TrimSpace(cleaned)
	}
	
	// For completion mode, try to extract just the code
	if mode == "complete" {
		cleaned = extractCodeFromResponse(cleaned)
	}
	
	return cleaned
}

func detectLanguageFromOutput(output string) string {
	// Simple detection based on common patterns
	if strings.Contains(output, "```cpp") || strings.Contains(output, "```c++") {
		return "cpp"
	}
	if strings.Contains(output, "```go") {
		return "go"
	}
	if strings.Contains(output, "```python") {
		return "python"
	}
	return ""
}

func extractCodeFromResponse(response string) string {
	// Try to extract code block
	codeBlockRegex := regexp.MustCompile("```[a-zA-Z]*\n(.*?)\n```")
	if matches := codeBlockRegex.FindStringSubmatch(response); len(matches) > 1 {
		return matches[1]
	}
	
	// If no code block, return the response as-is
	return response
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

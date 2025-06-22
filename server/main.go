// main.go - llama-agent for vimollama
package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Usage: llama-agent <command> <file>")
		os.Exit(1)
	}

	command := os.Args[1]
	filePath := os.Args[2]

	// Load current file content
	currentContent, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading target file: %s\n", err)
		os.Exit(1)
	}

	// Collect context from project
	context := collectProjectContext(filePath)

	// Build the prompt
	prompt := buildPrompt(command, context, string(currentContent))

	// Send prompt to Ollama and print result
	output := callOllama(prompt)
	fmt.Println(output)
}

// collectProjectContext walks the current repo and gathers relevant C++ headers/sources
func collectProjectContext(targetFile string) string {
	var contextBuilder strings.Builder
	_ = filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return nil
		}
		if strings.HasSuffix(path, ".cpp") || strings.HasSuffix(path, ".h") {
			// Skip the target file to avoid duplication
			if path == targetFile {
				return nil
			}
			data, err := ioutil.ReadFile(path)
			if err != nil {
				return nil
			}
			contextBuilder.WriteString(fmt.Sprintf("// File: %s\n%s\n\n", path, string(data)))
		}
		return nil
	})
	return contextBuilder.String()
}

// buildPrompt constructs the full prompt to send to LLaMA
func buildPrompt(mode, context, fileContent string) string {
	switch mode {
	case "complete":
		return fmt.Sprintf(
			"You are a C++ coding assistant. Based on the following project files and current buffer, complete the next logical code:\n\n%s\n\n// Current File:\n%s",
			context,
			fileContent,
		)
	case "generate":
		return fmt.Sprintf(
			"You are a C++ expert. Based on the project code and this file, write the missing functions or implement TODOs:\n\n%s\n\n// Current File:\n%s",
			context,
			fileContent,
		)
	default:
		return "Invalid command."
	}
}

// callOllama pipes the prompt into `ollama run llama3.2` and returns the output
func callOllama(prompt string) string {
	cmd := exec.Command("ollama", "run", "llama3.2")
	cmd.Stdin = bytes.NewBufferString(prompt)

	var out bytes.Buffer
	cmd.Stdout = &out

	err := cmd.Run()
	if err != nil {
		return fmt.Sprintf("Error running Ollama: %v", err)
	}

	return out.String()
}


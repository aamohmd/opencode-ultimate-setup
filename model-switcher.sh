#!/usr/bin/env bash
# Model Switcher — quickly swap the active opencode model

CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

echo -e "${BOLD}Select a model:${RESET}"
echo ""
echo "  1) claude-sonnet-4-5     (OpenRouter) — best balance"
echo "  2) claude-opus-4         (OpenRouter) — max intelligence"
echo "  3) gemini-2.5-pro        (Google Pro) — long context"
echo "  4) gpt-4o                (Copilot)    — fast & reliable"
echo "  5) gpt-4o-mini           (OpenRouter) — ultra fast"
echo "  6) llama-3.1-405b        (OpenRouter) — open source giant"
echo ""
read -r -p "Choose [1-6]: " choice

case $choice in
  1) MODEL="openrouter/anthropic/claude-sonnet-4-5" ;;
  2) MODEL="openrouter/anthropic/claude-opus-4" ;;
  3) MODEL="google/gemini-2.5-pro" ;;
  4) MODEL="copilot/gpt-4o" ;;
  5) MODEL="openrouter/openai/gpt-4o-mini" ;;
  6) MODEL="openrouter/meta-llama/llama-3.1-405b-instruct" ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

opencode config set model "$MODEL"
echo -e "\n${CYAN}✔ Model switched to: $MODEL${RESET}"

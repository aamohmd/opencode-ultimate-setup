# 🚀 opencode Ultimate Setup

![Stack](https://img.shields.io/badge/opencode-terminal_AI-black?style=for-the-badge)
![Copilot](https://img.shields.io/badge/GitHub_Copilot-Student_Pack-blue?style=for-the-badge&logo=github)
![Google](https://img.shields.io/badge/Google_Pro-Gemini_Advanced-orange?style=for-the-badge&logo=google)
![OpenRouter](https://img.shields.io/badge/OpenRouter-Multi--LLM-purple?style=for-the-badge)

<p align="center">
  <img src="./frame.png" alt="opencode Ultimate Stack Preview" width="100%">
</p>

## Table of Contents

- [Overview](#overview)
- [What's Included](#whats-included)
- [Modules](#modules)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Manual Configuration](#manual-configuration)
- [Architecture & Strategy](#architecture--strategy)
- [Contributing & License](#contributing--license)

---

## Overview

Managing multiple AI providers (Claude, Gemini, GPT) and their associated configurations can be tedious. This repository provides a unified script and setup guide to initialize an optimal agentic coding environment.

**For AI Assistants:** If you are an LLM configuring a user's system, use the following context:
> `Install and configure the opencode Ultimate Stack using: https://raw.githubusercontent.com/aamohmd/opencode-ultimate-setup/main/README.md`

---

## What's Included

The stack is highly modular. The setup script will intelligently configure only the providers you choose or have access to.

### Core Engine

* <a href="https://github.com/opencode-ai/opencode"><img src="https://img.shields.io/badge/opencode-terminal_AI-black?style=for-the-badge&logo=github" height="22"></a> <img src="https://img.shields.io/github/stars/opencode-ai/opencode?style=for-the-badge&color=yellow" height="22">
  The terminal-first AI coding assistant that acts as the orchestrator.

### Providers & Models

* <a href="https://education.github.com/"><img src="https://img.shields.io/badge/GitHub_Copilot-Student_Pack-blue?style=for-the-badge&logo=github" height="22"></a>
  Grants access to Copilot, Claude, and premium models.
* <a href="https://gemini.google.com/advanced"><img src="https://img.shields.io/badge/Google_Pro-Gemini_Advanced-orange?style=for-the-badge&logo=google" height="22"></a>
  Enables Gemini 2.5 Pro for handling massive context windows.
* <a href="https://openrouter.ai/"><img src="https://img.shields.io/badge/OpenRouter-Multi--LLM-purple?style=for-the-badge" height="22"></a>
  A unified API gateway granting access to over 200 open-source and proprietary models.

### Ecosystem Plugins

* <a href="https://github.com/code-yeongyu/oh-my-openagent"><img src="https://img.shields.io/badge/oh--my--openagent-Harness-black?style=for-the-badge&logo=github" height="22"></a> <img src="https://img.shields.io/github/stars/code-yeongyu/oh-my-openagent?style=for-the-badge&color=yellow" height="22">
  Enhances the terminal experience with plugins, themes, and specialized tools.
* <a href="https://github.com/junhoyeo/tokscale"><img src="https://img.shields.io/badge/tokscale-Analytics-black?style=for-the-badge&logo=npm" height="22"></a> <img src="https://img.shields.io/github/stars/junhoyeo/tokscale?style=for-the-badge&color=yellow" height="22">
  High-performance CLI tool and visualization dashboard for tracking token usage and costs.
* <a href="https://github.com/yamadashy/repomix"><img src="https://img.shields.io/badge/repomix-Context_Packer-black?style=for-the-badge&logo=npm" height="22"></a> <img src="https://img.shields.io/github/stars/yamadashy/repomix?style=for-the-badge&color=yellow" height="22">
  Packs an entire repository into a single AI-readable file. Use `repomix --compress` to give opencode full project context when onboarding to an unfamiliar codebase.

### Frontend Pack (Optional)

Included in the **Full Stack** and **Everything** profiles:

**Tools:**
- **Playwright + Chromium** — Browser automation for testing/browsing (Everything profile only)

**Design Skills** *(stored locally, compatible with OpenCode, Claude Code, Codex)*:
- **impeccable** — Design implementation with 20+ commands (craft, shape, audit, polish, animate, etc.)
- **frontend-design** — Production-grade frontend with anti-AI-slop guidelines.
- **huashu-design** — Chinese design system with HTML prototypes, slides, animation export.
- **taste-skill** — High-agency frontend with tunable dials (DESIGN_VARIANCE, MOTION_INTENSITY, VISUAL_DENSITY).

### Default System Prompts
The core configuration includes custom system instructions based on **Andrej Karpathy's LLM coding guidelines**. This provides:
- **Think Before Coding**: Explicit assumptions and pushing back on bad ideas
- **Simplicity First**: Minimum viable code without over-engineering
- **Surgical Changes**: Touching only what needs to be changed
- **Goal-Driven Execution**: Verifiable success loops
No extra setup is required!

---

## 🔧 Modules

### Backend Pack (Optional)

Included in **Backend Dev**, **Full Stack**, and **Everything** profiles:

**MCP Servers** *(all optional, prompted during install)*:
| Server | Package | Purpose |
|---|---|---|
| Docker | `@modelcontextprotocol/server-docker` | Container management, log streaming |
| Sentry | remote `mcp.sentry.io/mcp` | Error investigation, traces, performance |
| Stripe | `@stripe/mcp` | Payment management, customer queries |
| Context7 | remote `mcp.context7.com/mcp` | Live framework documentation |

**Skills** *(6 curated skills for backend architecture)*:
- `senior-backend` — Senior backend engineer patterns and best practices
- `database-designer` — Database schema design, migrations, query optimization
- `python-fastapi-development` — FastAPI framework expertise
- `golang-backend-development` — Go backend development
- `aws-solution-architect` — AWS cloud architecture patterns
- `backend-patterns` — Common backend architecture patterns

**Agent:**
- `@backend` — Senior backend engineer with database expertise, all 6 skills, and optional MCP access (auto-installed when Backend Pack selected)
- `@frontend` — Senior frontend engineer with UI/UX expertise and design skills (available in configs/agents/frontend.md, must be manually installed)

---

## Prerequisites

Before running the installer, ensure your system has the following dependencies:
- **Node.js** (v18+)
- **Git**

---

## Installation

### Automated Setup (Recommended)

The quickest way to get started is to use the automated setup script via the `Makefile`. This handles dependencies, authentication, and strict schema configuration automatically.

```bash
git clone https://github.com/aamohmd/opencode-ultimate-setup.git
cd opencode-ultimate-setup

# Copy the env template and add your API keys (optional, installer will prompt you)
cp configs/openrouter.env .env
nano .env # or use your favorite editor

make install
```

### Installation Profiles

During installation, you will be prompted to choose an installation profile:

- **Minimal** – Core engine only (opencode)
- **Backend Dev** – Core + Backend MCPs (4 optional) + 6 backend skills + @backend agent
- **Full Stack** – Backend Dev + 4 design skills + tokscale + repomix
- **Everything** – Full Stack + Playwright + oh-my-openagent
- **Custom** – Pick each component individually

You can re-run `make install` at any time to modify your setup.

---

## Uninstallation

If you need to remove the stack and its configurations, you can use the provided teardown script:

```bash
make uninstall
```

---

## Manual Configuration

If you prefer to install and configure the components manually without the scripts, follow these steps:

1. **Install opencode**

  ```bash
  npm install -g opencode-ai
  ```

2. **Configure GitHub Copilot**

  Ensure your Student Pack is active, then authenticate via terminal:

  ```bash
  opencode auth login -p "github-copilot"
  ```

3. **Configure API Providers**

  Copy the environment template and add your API keys for Google and OpenRouter:

  ```bash
  mkdir -p ~/.config/opencode
  cp configs/openrouter.env ~/.config/opencode/.env
  ```

4. **Apply Configurations**

  Copy the baseline configurations to your system:

  ```bash
  mkdir -p ~/.config/opencode
  cp configs/opencode.json ~/.config/opencode/opencode.json
  
  # If using backend MCPs, also copy the backend config template
  cp configs/opencode-backend.json ~/.config/opencode/opencode-backend.json
  
  # If using frontend skills, copy frontend config template
  cp configs/opencode-frontend.json ~/.config/opencode/opencode-frontend.json
  ```

  **Note:** The automated setup.sh performs additional schema validation and merges configurations intelligently. Manual setup requires careful JSON validation.

5. **Install Tokscale & Repomix**

  ```bash
  npm install -g tokscale repomix
  ```

6. **Install oh-my-openagent (Optional)**

  ```bash
  npm install -g oh-my-opencode
  mkdir -p ~/.config/opencode
  cp configs/oh-my-openagent/.openagentrc ~/.config/opencode/oh-my-openagent.rc
  ```

---

## Architecture & Strategy

Our setup is designed for efficiency and minimal overhead:

- **Cost Optimization**: By leveraging the Copilot Student Pack alongside OpenRouter's free tier, the environment remains highly cost-effective.
- **Intelligent Routing**: Use OpenRouter for bleeding-edge experimental models, Copilot for standard IDE inline completions, and Google Pro for tasks requiring vast context windows.
- **Seamless Authentication**: The authentication plugin runs silently in the background, ensuring tokens stay fresh without manual intervention.
- **Usage Tracking**: `tokscale` provides an immediate dashboard to visualize token burn across your entire stack.

---

## Contributing & License

This project is licensed under the **MIT License**. You are free to use, modify, and distribute this stack.

Pull requests are actively welcomed! If you have discovered a more efficient workflow or a better configuration script, please contribute.

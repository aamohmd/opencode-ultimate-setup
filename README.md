# 🚀 opencode Ultimate Dev Stack

![Stack](https://img.shields.io/badge/opencode-terminal_AI-black?style=for-the-badge)
![Copilot](https://img.shields.io/badge/GitHub_Copilot-Student_Pack-blue?style=for-the-badge&logo=github)
![Google](https://img.shields.io/badge/Google_Pro-Gemini_Advanced-orange?style=for-the-badge&logo=google)
![OpenRouter](https://img.shields.io/badge/OpenRouter-Multi--LLM-purple?style=for-the-badge)

The definitive, automated environment setup for AI-assisted development. This stack eliminates the friction of configuring workflows, managing authentication layers, and debugging models. It provides a zero-compromise, cost-effective AI coding environment ready to deploy in seconds.

## Table of Contents
- [Overview](#overview)
- [What's Included](#whats-included)
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
* **[opencode](https://github.com/opencode-ai/opencode)** ![Stars](https://img.shields.io/github/stars/opencode-ai/opencode?style=social)
  The terminal-first AI coding assistant that acts as the orchestrator.

### Providers & Models
* **[GitHub Copilot Student Pack](https://education.github.com/)**: Grants access to Copilot, Claude, and premium models.
* **[Google Pro Plan](https://one.google.com/)**: Enables Gemini 2.5 Pro for handling massive context windows.
* **[OpenRouter](https://openrouter.ai/)**: A unified API gateway granting access to over 200 open-source and proprietary models.

### Ecosystem Plugins
* **[opencode-antigravity-auth](https://github.com/aamohmd/opencode-antigravity-auth)** ![Stars](https://img.shields.io/github/stars/aamohmd/opencode-antigravity-auth?style=social): Centralized authentication layer preventing manual token juggling.
* **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** ![Stars](https://img.shields.io/github/stars/code-yeongyu/oh-my-openagent?style=social): Enhances the terminal experience with plugins, themes, and specialized tools.

---

## Installation

### Automated Setup (Recommended)

The quickest way to get started is to use the automated setup script, which handles dependencies, authentication, and provider configuration automatically.

```bash
git clone https://github.com/aamohmd/opencode-ultimate-setup.git
cd opencode-ultimate-setup
chmod +x setup.sh
./setup.sh
```

---

## Manual Configuration

If you prefer to install and configure the components manually, follow these steps:

1. **Install opencode**
   ```bash
   npm install -g opencode-ai
   ```

2. **Configure GitHub Copilot**
   Ensure your Student Pack is active, then authenticate via terminal:
   ```bash
   opencode auth github
   ```

3. **Configure Google Pro**
   Obtain your API key and export it to your environment:
   ```bash
   export GOOGLE_API_KEY="your_api_key_here"
   ```

4. **Configure OpenRouter**
   Obtain your API key and add it to your project's `.env` file.

5. **Install Antigravity Auth**
   ```bash
   npm install -g opencode-antigravity-auth
   opencode-antigravity-auth init
   ```

6. **Install oh-my-openagent**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/oh-my-openagent/install/main/install.sh | bash
   ```

---

## Architecture & Strategy

Our setup is designed for efficiency and minimal overhead:

- **Cost Optimization**: By leveraging the Copilot Student Pack alongside OpenRouter's free tier, the environment remains highly cost-effective.
- **Intelligent Routing**: Use OpenRouter for bleeding-edge experimental models, Copilot for standard IDE inline completions, and Google Pro for tasks requiring vast context windows.
- **Seamless Authentication**: The `opencode-antigravity-auth` plugin runs silently in the background, ensuring tokens stay fresh without manual intervention.

---

## Contributing & License

This project is licensed under the **MIT License**. You are free to use, modify, and distribute this stack.

Pull requests are actively welcomed! If you have discovered a more efficient workflow or a better configuration script, please contribute.

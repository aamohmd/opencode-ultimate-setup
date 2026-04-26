# 🚀 opencode Ultimate Dev Stack

> The definitive agent setup. We did the work. Tested every model. Handled the auth.
> You just run it.

![Stack](https://img.shields.io/badge/opencode-terminal_AI-black?style=for-the-badge)
![Copilot](https://img.shields.io/badge/GitHub_Copilot-Student_Pack-blue?style=for-the-badge&logo=github)
![Google](https://img.shields.io/badge/Google_Pro-Gemini_Advanced-orange?style=for-the-badge&logo=google)
![OpenRouter](https://img.shields.io/badge/OpenRouter-Multi--LLM-purple?style=for-the-badge)

You're juggling Claude, Gemini, and GPT. Configuring workflows. Setting up auth layers. Debugging models.
We fixed that. This is a zero-compromise, almost-free AI coding environment that actually ships. 
Install the stack. Run `opencode`. Done.

### For LLM Agents
Feed this prompt to your AI assistant (Claude, ChatGPT, Cursor, etc.):
```text
Install and configure the opencode Ultimate Stack by following the instructions here: https://raw.githubusercontent.com/aamohmd/opencode-ultimate-setup/main/README.md
```

### For Humans
Run these commands in your terminal to set everything up:
```bash
git clone https://github.com/aamohmd/opencode-ultimate-setup.git
cd opencode-ultimate-setup
chmod +x setup.sh
./setup.sh
```

---

## 📦 The Arsenal

> **Note:** The stack is entirely modular. You don't need all of these! Pick the providers you have access to, and the setup script will gracefully skip the rest.

We don't do lock-in here. We ride every model.  

### 🧠 The Core Engine
- **[opencode](https://github.com/opencode-ai/opencode)** ![Stars](https://img.shields.io/github/stars/opencode-ai/opencode?style=social) — Terminal-first AI coding assistant. The orchestrator that runs the show.

### 🔌 Models & Providers
- **[GitHub Copilot Student Pack](https://education.github.com/)** — Free access to Copilot, Claude, and premium models.
- **[Google Pro Plan](https://one.google.com/)** — Gemini 2.5 Pro for massive context windows.
- **[OpenRouter](https://openrouter.ai/)** — Unified API gateway for 200+ open-source and proprietary models.

### 🛠️ Plugins & Ecosystem
- **[opencode-antigravity-auth](https://github.com/aamohmd/opencode-antigravity-auth)** ![Stars](https://img.shields.io/github/stars/aamohmd/opencode-antigravity-auth?style=social) — One auth layer to rule them all. No more manual token juggling.
- **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** ![Stars](https://img.shields.io/github/stars/code-yeongyu/oh-my-openagent?style=social) — The ultimate agent harness. Plugins, themes, and tools that make the terminal feel alive.

---

## ⚡ Quick Start (Automated)

We're past the era of reading docs.

```bash
git clone https://github.com/aamohmd/opencode-ultimate-setup.git
cd opencode-ultimate-setup
./setup.sh
```

> The script installs dependencies, sets up auth, and configures all providers. You touch nothing.

---

## 🔧 Manual Setup (For the bold)

Want to do it yourself? Fine.

1. **Install opencode**
   ```bash
   npm install -g opencode-ai
   ```
2. **GitHub Copilot**
   Activate Student Pack. Run `opencode auth github`. Done.
3. **Google Pro**
   Get API key. Export `GOOGLE_API_KEY`.
4. **OpenRouter**
   Get API key. Fill `.env`.
5. **Antigravity Auth**
   ```bash
   npm install -g opencode-antigravity-auth
   opencode-antigravity-auth init
   ```
6. **oh-my-openagent**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/oh-my-openagent/install/main/install.sh | bash
   ```

---

## 💡 The Strategy

- **Free credit stacking**: Copilot Student Pack + OpenRouter free tier = almost zero cost.
- **Model routing**: OpenRouter for bleeding-edge models, Copilot for IDE completions, Google Pro for huge context.
- **Antigravity token refresh**: Runs silently. No manual re-auth needed.

Stop agonizing over dev environments. Take this stack and go build something incredible.

---

## 📄 License & Contributing
MIT — use freely. PRs welcome if you find a better workflow.

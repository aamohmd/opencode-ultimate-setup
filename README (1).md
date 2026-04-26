# 🚀 opencode Ultimate Dev Stack

> The definitive agent setup. Tested every model. Handled the auth. You just run it.

[![opencode](https://img.shields.io/badge/opencode-terminal_AI-black?style=for-the-badge)](https://github.com/opencode-ai/opencode)
[![Copilot](https://img.shields.io/badge/GitHub_Copilot-Student_Pack-blue?style=for-the-badge&logo=github)](https://education.github.com/pack)
[![Google](https://img.shields.io/badge/Google_Pro-Gemini_2.5-orange?style=for-the-badge&logo=google)](https://one.google.com)
[![OpenRouter](https://img.shields.io/badge/OpenRouter-200%2B_Models-purple?style=for-the-badge)](https://openrouter.ai)

---

You're juggling Claude, Gemini, and GPT. Configuring auth layers. Debugging provider tokens at 2am.

**We fixed that.**

This is a zero-compromise, almost-free AI coding environment — modular, battle-tested, and ready to ship. Pick the providers you have. Run the script. Get back to building.

---

## 🚀 Install

**For humans:**
```bash
git clone https://github.com/aamohmd/opencode-ultimate-setup.git
cd opencode-ultimate-setup
chmod +x setup.sh
./setup.sh
```

**For LLM agents** — paste this into Claude, Cursor, or ChatGPT:
```
Install and configure the opencode Ultimate Stack by following: 
https://raw.githubusercontent.com/aamohmd/opencode-ultimate-setup/main/README.md
```

> The script installs dependencies, sets up auth, and configures all providers. You touch nothing.

---

## 📦 The Arsenal

The stack is fully modular — you don't need everything. The setup script gracefully skips what you don't have.

### 🧠 Core Engine

| Tool | Role |
|------|------|
| **[opencode](https://github.com/opencode-ai/opencode)** ![Stars](https://img.shields.io/github/stars/opencode-ai/opencode?style=social) | Terminal-first AI coding assistant. The orchestrator. |

### 🔌 Providers

| Provider | What you get |
|----------|-------------|
| **[GitHub Copilot Student Pack](https://education.github.com/pack)** | Free Copilot + Claude + GPT-4o. Zero cost if you're a student. |
| **[Google Pro Plan](https://one.google.com)** | Gemini 2.5 Pro — 1M token context window. |
| **[OpenRouter](https://openrouter.ai)** | Single API key. 200+ models. No lock-in. |

### 🛠️ Ecosystem

| Plugin | Role |
|--------|------|
| **[opencode-antigravity-auth](https://github.com/aamohmd/opencode-antigravity-auth)** ![Stars](https://img.shields.io/github/stars/aamohmd/opencode-antigravity-auth?style=social) | One auth layer for all providers. Auto-refreshes tokens silently. |
| **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** ![Stars](https://img.shields.io/github/stars/code-yeongyu/oh-my-openagent?style=social) | Plugin + theme framework. Makes the terminal feel like a proper IDE. |

---

## 🔧 Manual Setup

Want full control? Here's the order that works.

**1. opencode**
```bash
npm install -g opencode-ai
opencode --version  # verify
```

**2. GitHub Copilot** — [activate the Student Pack](https://education.github.com/pack), then:
```bash
opencode auth github
```

**3. Google Pro** — [get an API key](https://aistudio.google.com/apikey), then:
```bash
export GOOGLE_API_KEY="your_key_here"
```

**4. OpenRouter** — [get an API key](https://openrouter.ai/keys), then:
```bash
cp configs/openrouter.env .env
# fill in OPENROUTER_API_KEY
```

**5. antigravity-auth** — links all providers into one session:
```bash
npm install -g opencode-antigravity-auth
opencode-antigravity-auth init
opencode-antigravity-auth status  # should show ✔ for each provider
```

**6. oh-my-openagent**
```bash
curl -fsSL https://raw.githubusercontent.com/oh-my-openagent/install/main/install.sh | bash
cp configs/oh-my-openagent/.openagentrc ~/.openagentrc
source ~/.openagentrc
```

---

## 💡 The Strategy

**Free credit stacking**  
Copilot Student Pack + OpenRouter free tier covers most daily usage. Google Pro adds the long-context firepower. The cost floor is essentially zero if you're a student.

**Smart model routing**  
- OpenRouter → bleeding-edge and open-source models  
- Copilot → fast IDE-native completions  
- Google Pro → anything that needs 500k+ tokens of context  

**Switch models in seconds**
```bash
./scripts/model-switcher.sh
```

**Silent auth refresh**  
antigravity-auth handles token expiry in the background. You'll never get a mid-session auth error again.

---

## 🗂️ Repo Structure

```
opencode-ultimate-setup/
├── setup.sh                        # One-shot automated setup
├── configs/
│   ├── opencode.json               # Main opencode config
│   ├── openrouter.env              # API key template
│   └── oh-my-openagent/
│       ├── .openagentrc            # Plugin + theme config
│       └── themes/antigravity.theme
└── scripts/
    ├── auth-check.sh               # Verify all providers
    └── model-switcher.sh           # Interactive model switcher
```

---

## 🤝 Contributing

Found a better config? A plugin worth adding? PRs are welcome.

MIT — use freely, build loudly.

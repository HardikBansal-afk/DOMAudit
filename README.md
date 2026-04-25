# DOMAudit-AI // Engineering Agentic Intelligence ⚡

**DOMAudit-AI** is a high-performance, AI-powered web accessibility auditor engineered for the Google Solution Challenge 2026.  
It leverages Large Language Models to analyze raw HTML, detect **WCAG 2.1 AA violations**, and generate **agentic, production-ready code patches** in real time.

---

## 🚀 The Vision

Accessibility shouldn’t be a compliance checkbox—it should be **built into the development workflow**.

DOMAudit-AI transforms accessibility auditing from:
> ❌ Static reports →  
> ✅ Intelligent, actionable code fixes

Instead of telling developers *what’s wrong*, it shows them:
> **Exactly where the issue is and how to fix it instantly.**

---

## 🧠 System Architecture

```
[ Flutter Frontend ]
        ↓
[ FastAPI Backend ]
        ↓
[ Gemini AI Engine ]
        ↓
[ DOM Parsing + Patch Generation ]
```

---

## ⚙️ Tech Stack

| Layer        | Technology |
|-------------|-----------|
| **Frontend** | Flutter (Dart), Glassmorphism UI, Bento Grid |
| **Backend**  | FastAPI (Python), Async Processing |
| **AI Engine**| Google Gemini 2.5 Flash-Lite |
| **Parsing**  | BeautifulSoup4 (DOM Analysis) |

---

## 🧬 Project Astra Integration

This system is built upon the **Project Astra** framework, focusing on:

- 🧠 Reasoning-first AI systems  
- 🔁 Knowledge distillation (Teacher → Student models)  
- ⚡ Latency-optimized inference pipelines  

Instead of naïve prompting, DOMAudit-AI uses:
> **Structured reasoning + constraint-guided outputs**  
to ensure patches are **valid, minimal, and production-safe**

---

## ✨ Core Features

### 🔍 Semantic DOM Auditing
- Detects:
  - Missing `alt` attributes  
  - Improper form labels  
  - Button accessibility issues  
  - Weak semantic structure  
- Aligns with **WCAG 2.1 AA compliance**

---

### 🤖 Agentic Code Patching

Generates **exact HTML fixes** while preserving structure.

```html
<!-- Before -->
<img src="hero.png">

<!-- After -->
<img src="hero.png" alt="Homepage banner showing product features">
```

---

### ⏱️ Rate-Limit Intelligence
- Smart retry system for Gemini APIs  
- "Cyberpunk Countdown" UI feedback loop  
- Prevents hard failures during audits  

---

### 🎨 Production-Grade UI
- **Typography:** Space Grotesk + JetBrains Mono  
- **Design:** Glassmorphism + Bento Layout  
- **UX Philosophy:** Minimal friction, maximum clarity  

---

## 📊 Performance Characteristics

- ⚡ Sub-second response (optimized prompts)  
- 🔄 Async request handling (FastAPI)  
- 📉 Reduced token usage via distilled prompts  
- 🧩 Modular architecture (easy scaling)  

---

## 🛠️ Local Setup

### 1️⃣ Backend (Python)

```bash
cd model_training
pip install fastapi uvicorn google-genai beautifulsoup4 python-dotenv
```

Create `.env` file:

```env
GEMINI_API_KEY=your_api_key_here
```

Run server:

```bash
python main.py
```

---

### 2️⃣ Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## 📁 Project Structure

```
DOMAudit-AI/
│
├── frontend/           # Flutter UI
├── model_training/     # FastAPI + AI logic
│   ├── main.py
│   ├── audit_engine.py
│   ├── patch_generator.py
│
├── assets/             # UI assets
└── README.md
```

---

## 🧪 Example Workflow

1. Paste raw HTML into dashboard  
2. AI scans DOM structure  
3. Violations are detected  
4. Agent generates fixes  
5. Developer copies patch → Done  

---

## 🏆 Why This Matters

- 🌍 Supports inclusive web development  
- ⚡ Saves hours of manual auditing  
- 🧠 Demonstrates agentic AI engineering  
- 🛠️ Bridges gap between AI & real dev workflows  

---

## 👨‍💻 Author & Leadership

**Hardik Bansal**  
B.Tech Computer Science Engineering  

- 🧠 Lead Researcher – Project Astra  
- ⚙️ Backend & AI Systems Architect  
- 🎯 Solution Design & Execution  

---

## 🔮 Future Roadmap

- 🌐 Live website crawling (URL-based audits)  
- 📦 VS Code Extension  
- 🧪 CI/CD Integration (GitHub Actions)  
- 🧠 Fine-tuned lightweight model (Astra Student)  

---

## ⭐ Final Note

This isn’t just an accessibility checker.

> It’s a step toward **autonomous developer tools**—  
> where AI doesn’t just assist, but **acts**.

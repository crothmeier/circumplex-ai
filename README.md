# 🌐 circumplex-ai

**circumplex-ai** is an offline-first, modular AI therapy assistant that uses local and hybrid LLMs (Mistral 7B, Claude, GPT-4.5) to provide real-time emotional analysis, reflection prompts, and therapeutic guidance based on Russell’s Circumplex Model of Affect.

It is privacy-focused, modular, and designed for on-premise use without cloud APIs.

---

## 🧠 Features

- **Streamlit UI** for journaling, reflection, and emotional analytics
- **Multi-agent orchestration** with fallback and fusion (Claude, GPT, Mistral)
- **Emotion zone classification** using valence/arousal/energy
- **Therapeutic prompt generation** via zone-based JSON templates
- **PostgreSQL + pgvector** backend with semantic + emotional similarity search
- **QLoRA fine-tuning pipeline** for adapting LLMs to user data

---

## 🏗️ Architecture


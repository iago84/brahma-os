# BRAHMA CORE 0.1

Local-first knowledge and reasoning platform by Naira Studio.

## Components
- `backend/`: FastAPI modular monolith
- `frontend/`: Next.js + TypeScript interface
- `scripts/`: Windows PowerShell setup helpers
- PostgreSQL: structured source of truth
- Qdrant: vector retrieval
- Neo4j: knowledge graph
- Ollama: local LLM and embeddings

## Prerequisites
Windows 10/11, Python 3.12, Node.js 22 LTS, Git, Ollama, PostgreSQL 17,
Qdrant and Neo4j Community/desktop. For local inference, 16 GB RAM is a
practical minimum for small quantized models; 32 GB+ is preferable.

## Quick start
1. Install the prerequisites listed in `docs/WINDOWS_SETUP.md`.
2. Copy `backend/.env.example` to `backend/.env` and adjust credentials.
3. In PowerShell:
   ```powershell
   .\scripts\setup-backend.ps1
   .\scripts\start-backend.ps1
   ```
4. In another PowerShell:
   ```powershell
   .\scripts\setup-frontend.ps1
   .\scripts\start-frontend.ps1
   ```
5. Open http://localhost:3000 and API docs at http://127.0.0.1:8000/docs.

This scaffold intentionally starts with SQLite-compatible SQLAlchemy defaults
for a frictionless first boot. Set `DATABASE_URL` to PostgreSQL before using
the persistent local installation. The Qdrant and Neo4j adapters are
configuration-ready; integration tests should be enabled after those services
are installed and running.

## Initial Ollama models
```powershell
ollama pull qwen3:1.7b
ollama pull bge-m3
```
For the 16 GB RAM / 1 GB VRAM profile, the default chat model is `qwen3:1.7b`. See `docs/HARDWARE_PROFILE.md`. The chat model is configurable through `BRAHMA_CHAT_MODEL`; embeddings are
configured separately. Confirm model availability with `ollama list`.

## API
- `GET /health`
- `GET /api/v1/system/status`
- `POST /api/v1/chat`
- `POST /api/v1/knowledge/documents` (metadata ingestion stub in 0.1)

## Security
The initial server binds to localhost only. Do not expose it to the public
internet without authentication, authorization, rate limiting, audit logging,
and TLS termination.

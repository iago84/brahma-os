# BRAHMA hardware profile — 16 GB RAM / NVIDIA 1 GB VRAM / Windows 10

## Profile decision
- Primary chat model: `qwen3:1.7b`
- Embeddings: `bge-m3` (multilingual; run as a separate, short-lived task)
- Context: 4096 tokens
- Output cap: 512 tokens for interactive chat
- One Ollama model loaded at a time
- One concurrent inference request
- No fine-tuning or model training on this machine

A 1 GB GPU cannot hold these models. Ollama should be treated as CPU-first with
possible minimal GPU offload. Actual speed depends heavily on the unknown CPU.
The Qwen3 1.7B model is a starting point, not a quality guarantee; evaluate it
against Spanish technical questions and upgrade to a 3B model only if memory
and latency tests permit.

## Service schedule
### Always-on during initial development
- Ollama
- BRAHMA FastAPI
- BRAHMA Next.js

### Start only when needed
- PostgreSQL: when persistence/migrations are implemented
- Qdrant: when semantic indexing is implemented
- Neo4j: defer; use PostgreSQL relation tables for the first graph iteration

Do not run PostgreSQL, Qdrant and Neo4j together by default on 16 GB RAM.
The graph can start in PostgreSQL and later be projected into Neo4j if query
patterns justify the additional service.

## Ollama environment variables
Set these in the Windows user environment, then quit Ollama from the tray and
launch it again:

```powershell
[Environment]::SetEnvironmentVariable("OLLAMA_MAX_LOADED_MODELS", "1", "User")
[Environment]::SetEnvironmentVariable("OLLAMA_NUM_PARALLEL", "1", "User")
[Environment]::SetEnvironmentVariable("OLLAMA_KEEP_ALIVE", "2m", "User")
```

Do not force CUDA layers or set a GPU-specific override. Let Ollama detect
whether any layer can safely use the NVIDIA GPU.

## Model commands
```powershell
ollama pull qwen3:1.7b
ollama pull bge-m3
ollama list
ollama run qwen3:1.7b
```

Run embeddings only during ingestion. Once embedding work is complete, unload
the embedding model if necessary:
```powershell
ollama stop bge-m3
```

Check actual placement and memory:
```powershell
ollama ps
nvidia-smi
```

## Windows 10 security
Windows 10 Home/Pro support ended on 2025-10-14. Prefer upgrading to Windows 11
if compatible, or enrolling in the applicable Extended Security Updates
program. Until then, keep BRAHMA bound to localhost, firewall inbound access,
and do not expose Ollama's port 11434 to a network.

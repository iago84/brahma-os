# BRAHMA CORE 0.1 — Architecture

## Design principles
1. Local-first and provider-independent.
2. Modular monolith first; split services only when operational evidence justifies it.
3. PostgreSQL is the canonical store for users, sessions, messages, documents,
   claims, provenance and job state.
4. Qdrant stores derived embeddings keyed by stable application IDs.
5. Neo4j stores typed entities and relations; it is a projection, not the only
   source of truth.
6. Every extracted claim should retain source and location metadata.
7. LLM output is untrusted until validated; confidence is not proof.

## Modules
- `core`: settings, lifecycle, dependency wiring
- `api`: versioned HTTP routes and schemas
- `mind`: reasoning and orchestration
- `memory`: episodic/session memory
- `knowledge`: document and claim lifecycle
- `rekha`: graph relationships and provenance
- `models`: Ollama adapter
- `workers`: asynchronous ingestion jobs (later milestone)

## Data flow
Document -> extraction -> chunking -> embedding -> Qdrant
         -> entities/relations -> Neo4j
         -> source, chunks, claims, provenance -> PostgreSQL

Query -> retrieve -> assemble context -> local model -> validate/cite -> answer

## 0.1 scope
- Health/status endpoints
- Local Ollama chat adapter
- Minimal web chat shell
- Document metadata endpoint
- Configuration and service health checks

Not in 0.1: autonomous self-modification, unrestricted tool execution,
multi-user internet deployment, model training, or claims of consciousness.

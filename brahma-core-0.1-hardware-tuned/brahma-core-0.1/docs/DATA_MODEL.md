# Data model (logical)

## PostgreSQL tables
- `users`: id, username, password_hash, created_at
- `workspaces`: id, owner_id, name, created_at
- `conversations`: id, workspace_id, title, created_at, updated_at
- `messages`: id, conversation_id, role, content, model, created_at
- `documents`: id, workspace_id, filename, mime_type, sha256, status,
  source_uri, created_at
- `document_chunks`: id, document_id, chunk_index, text, token_count,
  page_number, metadata_json
- `claims`: id, workspace_id, subject, predicate, object, epistemic_status,
  confidence, created_at
- `evidence`: id, claim_id, document_id, chunk_id, quote, locator,
  created_at
- `jobs`: id, kind, status, payload_json, error, created_at, updated_at
- `audit_events`: id, actor_id, action, resource_type, resource_id,
  metadata_json, created_at

## Qdrant
Collection: `brahma_knowledge_v1`
Payload: `workspace_id`, `document_id`, `chunk_id`, `source`, `page_number`,
`content_hash`, `created_at`.

## Neo4j
Nodes: `Entity`, `Concept`, `Claim`, `Source`.
Relationships: `RELATES_TO`, `SUPPORTS`, `CONTRADICTS`, `DERIVED_FROM`,
`MENTIONS`.
Every edge should carry provenance and timestamps where applicable.

## Rules
- UUIDs for application-level identifiers.
- Store original source text and derived text separately.
- Do not treat model-generated confidence as calibrated probability.
- Preserve source locators (page, URL, section, timestamp).
- Workspace isolation must be enforced in every query.

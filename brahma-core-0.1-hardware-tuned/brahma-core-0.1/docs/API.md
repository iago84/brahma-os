# API v1

Base URL: `http://127.0.0.1:8000`

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness |
| GET | `/api/v1/system/status` | Local dependency status |
| POST | `/api/v1/chat` | Chat with configured local model |
| POST | `/api/v1/knowledge/documents` | Register document metadata |

## POST /api/v1/chat
Request:
```json
{"message":"Explain the relationship between RAG and knowledge graphs"}
```
Response:
```json
{"answer":"...","model":"llama3.2:3b"}
```

## Planned next endpoints
- POST `/api/v1/knowledge/ingest` — upload and process files
- GET `/api/v1/knowledge/documents`
- GET `/api/v1/knowledge/graph`
- POST `/api/v1/reasoning/tasks`
- GET `/api/v1/conversations/{id}`
- POST `/api/v1/memory/search`

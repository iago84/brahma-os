from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from app.core.config import settings
from app.models.ollama import generate, OllamaUnavailable

router = APIRouter()

class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=20000)

class ChatResponse(BaseModel):
    answer: str
    model: str

class DocumentRegistration(BaseModel):
    filename: str
    mime_type: str | None = None
    source_uri: str | None = None

@router.get("/system/status")
async def system_status():
    return {
        "name": settings.app_name,
        "environment": settings.app_env,
        "llm": settings.brahma_chat_model,
        "context_tokens": settings.brahma_num_ctx,
        "max_output_tokens": settings.brahma_num_predict,
        "ollama": settings.ollama_base_url,
        "vector_store": settings.qdrant_url,
        "graph_store": settings.neo4j_uri,
    }

@router.post("/chat", response_model=ChatResponse)
async def chat(body: ChatRequest):
    try:
        answer = await generate(body.message)
        return ChatResponse(answer=answer, model=settings.brahma_chat_model)
    except OllamaUnavailable as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

@router.post("/knowledge/documents", status_code=202)
async def register_document(body: DocumentRegistration):
    # 0.1 scaffold: registration only. File parsing, chunking and indexing
    # are implemented in the next milestone.
    return {"status": "accepted", "filename": body.filename,
            "message": "Metadata registration scaffold; ingestion pipeline pending."}

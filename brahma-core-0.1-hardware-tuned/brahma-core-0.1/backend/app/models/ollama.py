import httpx
from app.core.config import settings

class OllamaUnavailable(RuntimeError):
    pass

async def generate(prompt: str) -> str:
    url = f"{settings.ollama_base_url.rstrip('/')}/api/chat"
    payload = {
        "model": settings.brahma_chat_model,
        "messages": [{"role": "user", "content": prompt}],
        "stream": False,
        "options": {
            "num_ctx": settings.brahma_num_ctx,
            "num_predict": settings.brahma_num_predict,
            "temperature": 0.3,
        },
        "keep_alive": "2m",
    }
    try:
        async with httpx.AsyncClient(timeout=300) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            return data.get("message", {}).get("content", "")
    except httpx.HTTPError as exc:
        raise OllamaUnavailable(
            "Ollama is unavailable. Start Ollama and pull the configured model."
        ) from exc

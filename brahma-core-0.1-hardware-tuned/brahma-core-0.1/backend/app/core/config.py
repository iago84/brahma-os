from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    app_name: str = "BRAHMA CORE"
    app_env: str = "development"
    api_v1_prefix: str = "/api/v1"
    host: str = "127.0.0.1"
    port: int = 8000
    database_url: str = "sqlite+aiosqlite:///./brahma.db"
    ollama_base_url: str = "http://127.0.0.1:11434"
    brahma_chat_model: str = "qwen3:1.7b"
    brahma_embedding_model: str = "bge-m3"
    brahma_num_ctx: int = 4096
    brahma_num_predict: int = 512
    qdrant_url: str = "http://127.0.0.1:6333"
    qdrant_collection: str = "brahma_knowledge_v1"
    neo4j_uri: str = "bolt://127.0.0.1:7687"
    neo4j_user: str = "neo4j"
    neo4j_password: str = "CHANGE_ME"

settings = Settings()

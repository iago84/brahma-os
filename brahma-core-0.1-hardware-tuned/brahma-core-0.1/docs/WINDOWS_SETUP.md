# Windows setup (no Docker)

Install:
1. Python 3.12 x64
2. Node.js 22 LTS
3. Git for Windows
4. Ollama for Windows
5. PostgreSQL 17 (Stack Builder is not required)
6. Qdrant Windows binary or run it as a Windows service
7. Neo4j Desktop / Community Edition

Create PostgreSQL database:
```sql
CREATE USER brahma WITH PASSWORD 'CHANGE_THIS_PASSWORD';
CREATE DATABASE brahma OWNER brahma;
```

Start Qdrant (if using the standalone binary):
```powershell
qdrant.exe
```
Default REST endpoint: `http://127.0.0.1:6333`.

Start Neo4j using Neo4j Desktop or the installed service. Default Bolt endpoint:
`bolt://127.0.0.1:7687`.

Ollama:
```powershell
ollama serve
ollama pull llama3.2:3b
ollama pull bge-m3
ollama list
```

Backend:
```powershell
cd backend
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -e .
Copy-Item .env.example .env
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

If PowerShell blocks activation for the current user:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Frontend:
```powershell
cd frontend
npm install
Copy-Item .env.local.example .env.local
npm run dev
```

Do not bind to `0.0.0.0` or create a public tunnel during the prototype stage.

# Fase 8 — Node/npm (Windows host, doc)

Detectado en host Windows: `node v24.22.1`, `npm 11.19.1` (OK para Vite 7/React 19).

## Ejecutar scaffold web (host) apuntando a CORE en WSL
1. CORE en WSL: `cd /home/yago/BRAHMA && .venv/bin/uvicorn core.brahma_core.main:app --host 0.0.0.0 --port 8000` (solo si necesitas acceso desde host; por defecto localhost WSL). Alternativa: usar proxy o ejecutar UI desde WSL cuando Node esté listo.
2. En PowerShell (host), desde copia del scaffold o ruta accesible:
```powershell
cd F:\BRAHMA\interface\web   # si se sincroniza; canónico WSL: /home/yago/BRAHMA/interface/web
npm install
npm run dev
```
3. Proxy Vite ya apunta a `http://127.0.0.1:8000` (ajustar si CORE corre en WSL con otra IP).
4. No exponer públicamente; sin credenciales/acciones privilegiadas en UI.

## Nota
Canónico: `/home/yago/BRAHMA/interface/web` (WSL). Para host, sincronizar carpeta o trabajar en copia controlada.

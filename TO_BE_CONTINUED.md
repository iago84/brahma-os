# BRAHMA — TO BE CONTINUED

> Creado: 2026-11-09 · Contexto: sesión autorizada (Fase 5/5b/8, recuperación WSL).  
> Canónico: `/home/yago/BRAHMA` (WSL `Ubuntu-24.04-F`). Copia de referencia: `F:\BRAHMA`.

## Estado al pausar

| Área | Estado | Evidencia |
|---|---|---|
| WSL | Recuperado y operativo | `wsl --shutdown` ejecutado; `Ubuntu-24.04-F` responde. |
| Tests BRAHMA CORE | **OK** | `cd /home/yago/BRAHMA && .venv/bin/python -m pytest -q` → `15 passed, 19 warnings`. |
| Arranque uvicorn | Corregido/documentado | **No usar** `--app-dir core`. Correcto: `uvicorn core.brahma_core.main:app` desde raíz. |
| Separación proyectos | Hecha | `docs/PROJECTS_SCOPE.md`, ADR 0006/0007, `ROADMAP.md`, `CHECKLIST.md`. |
| Ollama | Instalado + serve manual | `ollama 0.40.15` en `/usr/local/bin/ollama`. Serve en `127.0.0.1:11434` con `OLLAMA_MAX_LOADED_MODELS=1 OLLAMA_NUM_PARALLEL=1 OLLAMA_KEEP_ALIVE=2m` (`nohup ... >/tmp/ollama-serve.log`). **Sin unit systemd instalada.** |
| Modelo `qwen3:1.7b` | **OK (descargado)** | `ollama list`: `qwen3:1.7b 8f68893c685c 1.4 GB`. |
| Modelo `bge-m3` | **OK (descargado)** | `ollama list`: `bge-m3 790764642607 1.2 GB` (pull separado). |
| Prueba AI real BRAHMA | **Parcial/bloqueada por generación CPU** | Ollama reinstalado (autorizado); `/usr/local/lib/ollama/llama-server` presente. Serve reiniciado (yago, CPU limits). `ollama list` OK (qwen3+bge-m3). Adapter BRAHMA seleccionó `ollama` con `BRAHMA_AI_ENABLED=true` solo en proceso puntual → `provider ollama available True` (OK). Generación: POST `/api/generate` produjo 500/cancelación (`slot init_sampler` luego `stop/cancel task` ~1m50s en log) — probable timeout/carga CPU en WSL/FX-6300 o estado del serve tras reinicios. Default verificado: `BRAHMA_AI_ENABLED=False`. **Reintentar:** serve limpio, prompt mínimo, `num_ctx=2048`, timeout mayor, sin cargas paralelas; revisar logs/`/api/ps`. |
| Fase 5b free-claude-code | Evaluación local aislada (parcial) | `external/free-claude-code`: uv 0.13.7, Python 3.14.10, `.venv` aislado, deps sync. OK: `fcc-doctor --help`, imports, `create_app`. Smoke HTTP/TestClient/ASGI completo **no cerrado** (firma `create_app(services)`/arranque). **AGPL-3.0-only**: no integrar/redistribuir/ofrecer como servicio de red sin revisión legal/TOS. |
| Desktop `interface/web` | Scaffold + npm parcial | WSL: Node 20.20.2/npm 11.19.1 instalados; scaffold presente (`/home/yago/BRAHMA/interface/web`). npm install en WSL tuvo error (log npm). **Windows host:** Node 24.22.1/npm 11.19.1; copia en `F:\BRAHMA\interface\web`; `npm install --no-audit --no-fund --ignore-scripts` completó (“added 66 packages”). **`npm run build` / `npm run dev` / Playwright no verificados.** esbuild puede requerir scripts/binarios correctos en Windows — si falla, ejecutar `npm rebuild esbuild` o `npm install` sin `--ignore-scripts` en entorno limpio. |

## Continuar por orden (recomendado)

### 1) Fase 5 — Completar Ollama/modelos/prueba controlada
```bash
# WSL
wsl -d Ubuntu-24.04-F
# Si ollama no responde:
OLLAMA_HOST=127.0.0.1:11434 OLLAMA_MAX_LOADED_MODELS=1 OLLAMA_NUM_PARALLEL=1 OLLAMA_KEEP_ALIVE=2m nohup /usr/local/bin/ollama serve >/tmp/ollama-serve.log 2>&1 &
curl -s http://127.0.0.1:11434/api/tags

# 1a. Esperar/verificar qwen3
OLLAMA_HOST=127.0.0.1:11434 /usr/local/bin/ollama pull qwen3:1.7b   # retoma si parcial
OLLAMA_HOST=127.0.0.1:11434 /usr/local/bin/ollama list                 # confirmar qwen3:1.7b

# 1b. bge-m3 SOLO después, separado
OLLAMA_HOST=127.0.0.1:11434 /usr/local/bin/ollama pull bge-m3
OLLAMA_HOST=127.0.0.1:11434 /usr/local/bin/ollama list
```
Prueba real BRAHMA (puntual, **restaurar false**):
```bash
cd /home/yago/BRAHMA
BRAHMA_AI_ENABLED=true BRAHMA_AI_PROVIDER=ollama BRAHMA_OLLAMA_MODEL=qwen3:1.7b \
  .venv/bin/python -c "
from core.brahma_core.config import get_settings; get_settings.cache_clear()
from ai_engine.brahma_ai.registry import get_adapter
a=get_adapter(); print(a.name, a.is_available())
print(a.generate('Responde en una frase: ¿qué es 2+2?', options={'num_predict':64}))
" 
# Confirmar BRAHMA_AI_ENABLED vuelve a false por defecto en .env/config normal.
.venv/bin/python -m pytest -q
```
- [ ] Añadir test integración Ollama **opt-in** (marcado, ej. `BRAHMA_RUN_OLLAMA_TESTS=1`), mocks por defecto.
- [ ] Decidir/autorizar si crear unit systemd (usuario o sistema) para Ollama; **no instalada**.

### 2) Fase 5b — Smoke aislado (opcional, sin integración)
```bash
cd /home/yago/BRAHMA/external/free-claude-code
/home/yago/.local/bin/uv run python -c "from free_claude_code.runtime.bootstrap import build_asgi_app; print(type(build_asgi_app()))"
# Si cuelga, inspeccionar dependencias/estado requerido; no añadir credenciales externas.
```
- [ ] Documentar resultado. **No** copiar código a CORE ni exponer servicio. Revisión AGPL/TOS antes de cualquier redistribución.

### 3) Fase 8 — BRAHMA DESKTOP (scaffold → MVP)
Windows host (Node 24 presente):
```powershell
cd F:\BRAHMA\interface\web
npm rebuild esbuild   # si npm run build/dev falla por esbuild
npm run build         # verificar
npm run dev           # proxy /api,/health -> 127.0.0.1:8000
```
WSL (si se prefiere canónico): arreglar `npm install` en `/home/yago/BRAHMA/interface/web` y verificar `npm run build`.
- [ ] MVP UI: estado `/health` + `/api/v1/system/status`, chat contra `/api/v1/mind/reason`, búsqueda KNOWLEDGE, REKHA read-only, consola OBSERVER.
- [ ] Mostrar procedencia/evidencia/etiquetas epistémicas. Sin acciones privilegiadas.
- [ ] Playwright smoke (localhost). Doc: `docs/Fase8-Node-Windows.md`.

### 4) Fase 6 — MIND con evidencia
- [ ] Incorporar REKHA+KNOWLEDGE en respuesta (citas/IDs/procedencia/contradicciones).
- [ ] Verificación y etiquetas epistémicas; tests deterministas + adapter mock.

### 5) Fase 7 — MODES funcionales
- [ ] Prioridad `TEXT`, `KNOWLEDGE`, `DEV` (DEV sin ejecución arbitraria). `SYSTEM` read-only.

### 6) Fases 9–10 — BRAHMA SYSTEM / OS (**requieren autorización explícita por acción**)
- [ ] No ejecutar sin autorización: instalar units systemd, D-Bus/Polkit, toolchain ISO, cambios privilegiados.
- [ ] SYSTEM: catálogo allowlisted read-only, dry-run, confirmación, auditoría.
- [ ] OS: perfil paquetes, branding, ISO reproducible, SBOM/licencias (revisar AGPL si aplica).

## Mejoras pendientes (ver `CHECKLIST.md`)
- Migrar FastAPI `on_event` → lifespan. Scripts/make (`test,lint,run,migrate`). CI local. Backup/remoto git. Telemetría AI segura. Límites ingesta/rate/timeout. OpenAPI estable.

## Riesgos / recordatorios
- **Credenciales:** no guardar contraseñas en docs/logs/chat. Instalar paquetes privilegiados solo con autorización explícita.
- **AGPL-3.0 (free-claude-code):** aislado; no integrar/distribuir sin revisión legal/TOS.
- **CPU/recursos:** 1 modelo, no simultáneo, keep-alive corto, timeouts.
- **WSL I/O:** si reaparece `getpwnam/getpwuid/util I/O`, `wsl --shutdown` (interrumpe procesos) y revalidar.

## Verificación rápida
```bash
cd /home/yago/BRAHMA
.venv/bin/python -m pytest -q
.venv/bin/uvicorn core.brahma_core.main:app --host 127.0.0.15 --port 8000 --reload
curl -s http://127.0.0.1:11434/api/tags
/home/yago/.local/bin/uv --version
```


## Actualización — 2026-11-09 (sesión continuada)
- **qwen3:1.7b:** descargado y listado en `ollama list` (`8f68893c685c`, 1.4 GB). OK.
- **bge-m3:** descargado y listado (`790764642607`, 1.2 GB). OK (pull separado, no simultáneo).
- **Prueba BRAHMA AI puntual (controlada):** `BRAHMA_AI_ENABLED=true BRAHMA_AI_PROVIDER=ollama` en proceso aislado seleccionó `provider ollama available True` y envió generación — **falló por backend Ollama**: `HTTP 500 /api/generate` porque Ollama 0.40.15 no encuentra `llama-server` (CPU runner). Log: `error starting llama-server: llama-server binary not found (checked /usr/local/lib/ollama/llama-server, ...). Run 'cmake -S llama/server --preset cpu && cmake --build --preset cpu' first`. `/usr/local/lib/ollama` está vacío. **Causa:** instalación de Ollama quedó incompleta (primer intento sin `zstd`; reinstalación posterior interrumpida en la salida capturada). **Acción requerida (autorizada, necesita sudo):** reinstalar Ollama correctamente: `sudo /bin/sh /tmp/ollama-install.sh` (script presente, `zstd` ya instalado), luego verificar `/usr/local/lib/ollama/llama-server` (o binarios equivalentes), reiniciar `ollama serve` con límites CPU, y repetir prueba puntual. Tras prueba, confirmar `BRAHMA_AI_ENABLED` default sigue `false` (verificado: `get_settings().ai_enabled` = `False` sin override). Tests BRAHMA: **15 passed**.
- **No se almacenó ninguna credencial.**


## Actualización — 2026-11-09 (cierre Fase 5 parcial)
- Ollama reinstalado con sudo autorizado: `llama-server` presente en `/usr/local/lib/ollama/llama-server`. Servicio systemd `ollama` **deshabilitado/detenido** para evitar conflicto de puerto con serve manual CPU-limitado (`127.0.0.1:11434`, usuario yago, modelos en `/home/yago/.ollama`).
- `ollama list`: `bge-m3:latest` (1.2 GB) + `qwen3:1.7b` (1.4 GB) — **verificados**.
- Prueba BRAHMA (proceso puntual): `BRAHMA_AI_ENABLED=true BRAHMA_AI_PROVIDER=ollama BRAHMA_OLLAMA_MODEL=qwen3:1.7b` → **`provider ollama available True`**. Generación no completó con salida útil (500/cancelación en Ollama durante inferencia CPU); requiere reintento controlado con serve estable.
- **Confirmado:** `get_settings().ai_enabled == False` por defecto (sin override). No se habilitó AI por defecto.
- **Tests:** `15 passed, 19 warnings`.

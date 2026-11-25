# BRAHMA — Roadmap y Checklist (CORE + OS)

> **Organización:** Naira Studio · **Identidad:** Supreme Intelligence Architecture  
> **Lema:** *Un solo cerebro. Ocho modos. Una arquitectura.*  
> **Objetivo:** construir una **nueva distribución Linux AI-native** (no un chatbot), con **nueva interfaz de escritorio**, núcleo unificado, memoria/conocimiento persistentes (REKHA), razonamiento con evidencia y ejecución Linux **segura y auditable**.

## 1) Separación de proyectos (obligatoria)

| Proyecto | Qué es | Canónico | Estado |
|---|---|---|---|
| **BRAHMA CORE** | Cerebro/API: orquestación, config `BRAHMA_*`, logging, errores, seguridad base, MEMORY, KNOWLEDGE, REKHA, AI ENGINE (adaptadores), MIND, contratos de MODES. | `/home/yago/BRAHMA` (WSL `Ubuntu-24.04-F`, `core/brahma_core` + subsistemas) | Fases 0–4 base completada; 5/5b/6/7 en progreso controlado. |
| **BRAHMA DESKTOP** | Nueva interfaz de usuario (web local + shell nativo) consumiendo CORE por API. | `interface/` (spec + `interface/web` scaffold React+Vite+TS) | Fase 8 diseño/scaffold. |
| **BRAHMA OS** | Nueva distro Linux AI instalable: base KDE/Kubuntu candidata, integración SYSTEM (systemd/D-Bus/Polkit), hardening, ISO/instalador, repos/licencias. Consume CORE+DESKTOP. | `infrastructure/`, `docs/DISTRO_PLAN.md` | Fases 9–10 diseño/plan. |

- **Reglas:** no mezclar alcances; no duplicar cerebros; CORE es la fuente de verdad funcional. OS/DESKTOP añaden interfaz/sistema/distribución sobre CORE.
- **Prototipo histórico (no canónico):** `F:\BRAHMA\brahma-core-0.1-hardware-tuned\brahma-core-0.1` (Windows, `backend/app`, SQLite, Next.js). Solo referencia de perfil/config.
- **Origen/registro:** `F:\BRAHMA\prompt_inicial.txt`. Ver `docs/PROJECTS_SCOPE.md`, ADR `0006`, ADR `0007`.

## 2) Estado actual (evidencia 2026-11-09)

| Área | Estado | Evidencia |
|---|---|---|
| WSL workspace | OK | `Ubuntu-24.04-F`, `/home/yago/BRAHMA`, Python 3.12.3, `.venv`, 7.8Gi RAM/4Gi swap. |
| **BRAHMA CORE 0.2** | Completado | API v1, config, logging, `X-Request-ID`, errores; `/health`, `/api/v1/system/status`. |
| PostgreSQL | Operativo | `brahma` / `brahma_memory`, `brahma_memory_test`; migraciones `2d75ae1013ea`, `563a1ea70555`, `b71b8e0c6fc4`. |
| MEMORY 0.1 | Completado | Conversaciones/mensajes/episódica/semántica + contexto; `/api/v1/memory/*`. |
| KNOWLEDGE 0.1 | Completado (CPU-light) | Ingesta TXT/MD, chunks, procedencia/evidencia, búsqueda hash+coseno; `/api/v1/knowledge/*`. PDF/BGE-M3 real diferidos. |
| REKHA 0.1 | Completado (relacional) | Entidades/relaciones/contradicciones, procedencia/evidencia, detección heurística; `/api/v1/rekha/*`. Neo4j diferido. |
| AI ENGINE 0.1 | En progreso | `NullAdapter`+`OllamaAdapter` (CPU, desactivado por defecto). Defaults: `qwen3:1.7b`, `bge-m3`, `ctx=4096`, `predict=512`, 1 modelo/1 petición. **Ollama 0.40.15 instalado** (`/usr/local/bin/ollama`); `ollama serve` operativo en `127.0.0.1:11434` (arranque manual con límites CPU). **Modelo pulls en progreso/verificar** (`ollama list`); `BRAHMA_AI_ENABLED=false`. |
| free-claude-code 5b | Evaluación local aislada | Repo en `external/free-claude-code`; **uv 0.13.7 + Python 3.14.10 + `.venv` aislado**; deps sincronizadas; smoke: `fcc-doctor --help` OK, imports/`create_app` OK. **AGPL-3.0-only**: no integrar/redistribuir/ofrecer como servicio de red sin revisión legal/TOS. |
| MIND 0.1 | Fundación operativa | Planner + `/api/v1/mind/reason` (MEMORY/KNOWLEDGE/adapters, sin LLM por defecto). Falta verificación con evidencia/LLM real. |
| MODES 7 | Scaffold | Contratos `ModeRequest/Result` + 8 modos + test. Falta implementación funcional por modo. |
| **DESKTOP/INTERFACE 8** | Scaffold | `interface/NEW_INTERFACE_SPEC.md` + `interface/web` (React+Vite+TS, proxy a CORE). **Node/npm no disponible en WSL** → `npm install/build/Playwright` pendiente. |
| **SYSTEM 9** | Diseño/ejemplo | `infrastructure/systemd/brahma-core.service.example` (**no instalado**). Privilegios `OBSERVER/ASSISTANT/OPERATOR` definidos. |
| **OS/distro 10** | Diseño/plan | `docs/DISTRO_PLAN.md`; base Kubuntu/KDE candidata. Sin ISO/toolchain privilegiada. |
| **Tests** | OK | `cd /home/yago/BRAHMA && .venv/bin/python -m pytest -q` → **`15 passed, 19 warnings`**. |

> **Corrección operativa (importante):** no usar `--app-dir core`. Las importaciones son `core.brahma_core.*`; con `--app-dir core` Python busca `brahma_core.*` y falla con `ModuleNotFoundError: No module named 'core'`.  
> Comando correcto (desde raíz):  
> `cd /home/yago/BRAHMA && .venv/bin/uvicorn core.brahma_core.main:app --host 127.0.0.15 --port 8000 --reload`

## 3) Perfil hardware y restricciones
- Host referencia (diagnóstico): Win10 Pro 19045, 24 GB RAM, AMD FX-6300 (3c/6t), GPU sin driver identificado (`nvidia-smi` ausente), F: con espacio. Lab actual: WSL2 `Ubuntu-24.04-F` ~7.8Gi.
- CPU-first: 1 modelo local, 1 petición, carga perezosa, timeouts, servicios bajo demanda, pool DB pequeño.
- Baseline AI: `qwen3:1.7b` chat; `bge-m3` embeddings **solo en tarea separada**; `num_ctx=4096`, `num_predict=512` (`BRAHMA_OLLAMA_*`). Subir modelo solo si cabe y se mide.

## 4) Arquitectura
```text
BRAHMA OS (distro Linux AI)  ← Fases 9–10
└─ BRAHMA DESKTOP / nueva interfaz (React+Vite+TS; Qt6/QML nativo futuro)  ← Fase 8
   └─ BRAHMA CORE (API / seguridad / auditoría)  ← Fases 0–7
      ├─ MIND · MEMORY · KNOWLEDGE · REKHA · AI ENGINE · MODES · (SENSE/LOGIC/CREATE/SYSTEM)
Datos: PostgreSQL fuente de verdad; Qdrant solo si escala; Neo4j diferido.
AI: Ollama local CPU-first, 1 modelo; runtimes externos evaluados con aislamiento/auditoría/licencia.
```

## 5) Roadmap por hitos

| Hito | Contenido | Salida verificable |
|---|---|---|
| **H1 — CORE estable** | Cerrar 0–4 + hardening API/tests/docs | suite verde, migraciones, endpoints documentados |
| **H2 — AI local controlada** | Fase 5: Ollama + modelos + prueba real gated + mocks en tests | `ollama list` con modelos, prueba controlada, `AI_ENABLED=false` default, tests verdes |
| **H3 — Razonamiento con evidencia** | Fase 6: MIND usa REKHA/KNOWLEDGE/MEMORY y etiquetas epistémicas | tests de planificación/verificación con evidencia |
| **H4 — Modos funcionales** | Fase 7: `TEXT/KNOWLEDGE/DEV` primero | endpoints/contratos + tests por modo |
| **H5 — Desktop usable** | Fase 8: web UI conectada a CORE + estado/auth local | build UI, proxy API, Playwright básico, sin secretos/acciones privilegiadas |
| **H6 — System seguro** | Fase 9: operaciones allowlisted auditadas; systemd opt-in | pruebas de allowlist/dry-run/audit; instalación solo autorizada |
| **H7 — Distro instalable** | Fase 10: imagen base + branding + ISO/recovery + cumplimiento licencias | artefacto reproducible + checklist legal/técnico aprobado |

## 6) Checklist por fase (resumen; detalle en `CHECKLIST.md`)

### 0–1 CORE base — completadas
- [x] Auditoría, ADRs, separación CORE/OS (ADR 0006/0007), CORE 0.2, tests.

### 2–4 Datos/cognición base — completadas (CPU-light)
- [x] MEMORY/KNOWLEDGE/REKHA + migraciones + APIs + tests.  
- [ ] PDF/imágenes, embeddings reales, grafo avanzado (controlado).

### 5 AI ENGINE — en progreso
- [x] Adapters/defaults/flags. [x] Ollama 0.40.15 instalado y `serve` local. [ ] Confirmar pulls `qwen3:1.7b`+`bge-m3` (separados). [ ] Prueba real controlada (`AI_ENABLED` puntual) con prompt corto y timeout; restaurar `false`. [ ] Unit systemd/arranque de Ollama (opcional, autorizado). [ ] Telemetría carga/tiempos.

### 5b free-claude-code — evaluación local (aislada)
- [x] uv/py3.14.10/venv aislado, sync, smoke CLI/import. [ ] Smoke HTTP local controlado (sin credenciales externas) si aplica. [ ] Decisión: **no integrar** por defecto (AGPL). Revisión legal/TOS antes de cualquier redistribución/servicio.

### 6 MIND — en progreso
- [x] Planner/endpoint base. [ ] Enriquecer con REKHA+evidencia, verificación, tests.

### 7 MODES — scaffold
- [x] Contratos/8 modos. [ ] Implementar `TEXT/KNOWLEDGE/DEV`; permisos por modo; tests.

### 8 BRAHMA DESKTOP (nueva interfaz) — scaffold
- [x] Spec + scaffold `interface/web` (React+Vite+TS, proxy `/api`,`/health`). [ ] Node 20+ en WSL/host → `npm install/build`. [ ] Pantallas MVP: estado CORE, chat MIND, búsqueda KNOWLEDGE, REKHA view (solo lectura), consola SYSTEM mock/OBSERVER. [ ] Manejo de errores/epistemic labels/procedencia en UI. [ ] Playwright smoke (localhost). [ ] Qt 6/QML shell nativo (fase posterior, autorizada).

### 9 BRAHMA SYSTEM — diseño
- [x] Modelo de privilegios + unit ejemplo. [ ] Allowlist de operaciones (read-only primero), `dry-run`, confirmación, auditoría JSON, rate/timeout. [ ] D-Bus/Polkit solo si necesario. [ ] Instalar/activar unit **solo con autorización explícita**.

### 10 BRAHMA OS (distro) — diseño
- [x] Plan base Kubuntu/KDE. [ ] Perfil de paquetes mínimo, usuario/servicios, branding, first-boot, recovery. [ ] Pipeline ISO reproducible (herramienta a validar). [ ] SBOM/licencias (incl. revisión AGPL). [ ] Pruebas en VM/hardware.

## 7) Criterios de “hecho”
Código funcional; **tests ejecutados y pasando**; config reproducible; seguridad (sin ejecución arbitraria/escalado silencioso); CPU-first/1 modelo; integración CORE verificada; docs+ADR; backup antes de cambios importantes.

## 8) Riesgos y mitigaciones
- **Licencia AGPL (free-claude-code):** aislar, no integrar/distribuir sin revisión legal.
- **Recursos CPU/7–8Gi WSL:** modelos pequeños, no simultáneos, timeouts, keep-alive corto.
- **Privilegios OS:** allowlist+dry-run+auditoría; systemd/D-Bus/Polkit solo autorizado.
- **Deriva WSL/F:** código canónico WSL; sincronizar docs controladamente.

## 9) Registro de sesiones (resumen)
- **2026-11-08/09:** CORE/MEMORY/KNOWLEDGE/REKHA/AI/MIND/MODES fundaciones; tests `15 passed`.
- **2026-11-09 (autorizada):** corrección `--app-dir`; separación CORE/OS; defaults `qwen3.1.7b`/`bge-m3`; uv+Ollama instalados; Fase 5b runtime aislado py3.14.10 + smoke; scaffold `interface/web`; ADR 0007; changelog actualizado.

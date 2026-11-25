# BRAHMA — CHECKLIST (tareas, mejoras, verificación)

> Derivado de `ROADMAP.md`. Marcar `[x]` solo con evidencia (test/log/comando). Respetar autorización para installs de sistema, modelos pesados, servicios privilegiados, ISO, y revisión legal.

## A. Operativa / calidad (continuo)
- [x] Comando arranque correcto documentado: `uvicorn core.brahma_core.main:app` desde raíz (sin `--app-dir core`).
- [x] Suite verde actual: `15 passed, 19 warnings` (`.venv/bin/python -m pytest -q`).
- [ ] Resolver warnings FastAPI `on_event` (migrar a lifespan) cuando sea seguro.
- [ ] Añadir `make`/scripts de tareas (`test`, `lint`, `run`, `migrate`) y pre-commit opcional.
- [ ] CI local reproducible (script) + pin de deps/lock coherente.
- [ ] Backup/remoto git y snapshot antes de cambios mayores.
- [ ] Sincronizar docs WSL↔F: (código solo WSL canónico).

## B. BRAHMA CORE — Fase 5 (AI ENGINE, autorizada)
- [x] Defaults CPU-first: `qwen3:1.7b`, `bge-m3` separado, `ctx=4096`, `predict=512`, 1 modelo.
- [x] `BRAHMA_AI_ENABLED=false` por defecto; `core/.env.example`.
- [x] Ollama 0.40.15 instalado; `ollama serve` responde en `127.0.0.1:11434` (CPU).
- [ ] Completar `ollama pull qwen3:1.7b` y verificar `ollama list`.
- [ ] Completar `ollama pull bge-m3` **en tarea separada** (no simultáneo) y verificar.
- [ ] Prueba real controlada: habilitar `BRAHMA_AI_ENABLED=true` solo para una invocación/test puntual (prompt corto, timeout, CPU), capturar resultado/tiempo, restaurar `false`.
- [ ] Test de integración Ollama con **mock por defecto** + test real marcado/opt-in (`BRAHMA_RUN_OLLAMA_TESTS=1`).
- [ ] Endpoint/health de estado AI (modelo, disponible, cargado, último error) sin exponer secretos.
- [ ] Telemetría: latencia, timeouts, modelo usado, sin contenido sensible en logs prod.
- [ ] (Opcional, autorizado) unit systemd para Ollama o script de arranque controlado; no habilitar por defecto sin decisión.
- [ ] Embeddings reales `bge-m3` vía Ollama para KNOWLEDGE (pipeline separado, batch, bajo demanda).

## C. BRAHMA CORE — Fase 5b (free-claude-code, aislado)
- [x] uv + Python 3.14.10 + `.venv` aislado en `external/free-claude-code`; deps sync.
- [x] Smoke: `fcc-doctor --help`, imports, `create_app`.
- [ ] Smoke localhost HTTP/TestClient solo si seguro y sin credenciales externas.
- [ ] Mantener **aislado** de `.venv` CORE y del API público.
- [ ] Revisión legal/TOS AGPL-3.0-only antes de: integrar, modificar distribuido, bundle en ISO, o exponer como servicio de red.
- [ ] Si se decide integrar: adapter detrás de AI ENGINE + allowlist + auditoría + dependencia aislada + cumplimiento licencia.

## D. BRAHMA CORE — Fase 6 (MIND)
- [x] Planner + `/api/v1/mind/reason` base.
- [ ] Incorporar evidencia REKHA/KNOWLEDGE (procedencia, contradicciones) en el plan/respuesta.
- [ ] Etiquetado epistémico en salida (hecho/evidencia/inferencia/hipótesis/desconocido/contradicción).
- [ ] Verificación: checks de consistencia y citas a fuentes/IDs.
- [ ] Tests: casos con memoria, conocimiento, contradicción detectada, sin LLM (determinista) y con adapter mock.
- [ ] Integración LLM real solo cuando Fase 5 prueba controlada OK.

## E. BRAHMA CORE — Fase 7 (MODES)
- [x] Contratos + 8 modos scaffold.
- [ ] Implementar `TEXT` (chat/mind), `KNOWLEDGE` (ingesta/búsqueda/citas), `DEV` (asistencia código **sin ejecución arbitraria**).
- [ ] `SYSTEM`/`AUTOMATION`: solo OBSERVER/read-only inicialmente; mutaciones vía Fase 9 allowlist.
- [ ] `VOICE/VISION/CREATIVE`: interfaces/feature flags, implementación diferida CPU.
- [ ] Pruebas por modo (input/permiso/contexto/salida).

## F. BRAHMA DESKTOP — Fase 8 (nueva interfaz)
- [x] Spec `interface/NEW_INTERFACE_SPEC.md`.
- [x] Scaffold `interface/web` (React+Vite+TS, proxy `/api`,`/health`).
- [ ] Instalar Node 20+ (WSL o estrategia documentada) y ejecutar `npm install`, `npm run build`.
- [ ] MVP UI: System/health, chat (MIND), ingesta+búsqueda KNOWLEDGE, vista REKHA (read-only), consola OBSERVER.
- [ ] Mostrar procedencia/evidencia y etiquetas epistémicas; nunca ejecutar acciones privilegiadas desde UI.
- [ ] Manejo de estados: offline/degradado, AI disabled, DB down.
- [ ] Tests Playwright smoke (localhost). Accesibilidad básica.
- [ ] Diseño visual “nueva interfaz BRAHMA” (tema) + i18n base.
- [ ] Qt 6/QML shell/panel KDE (posterior, autorizado; toolchain).

## G. BRAHMA SYSTEM — Fase 9 (seguridad/OS, solo autorizado)
- [x] Modelo `OBSERVER/ASSISTANT/OPERATOR`; `allow_system_exec=false`.
- [x] `infrastructure/systemd/brahma-core.service.example` (no instalado).
- [ ] Catálogo de operaciones allowlisted (read-only primero: estado servicios, disco, logs BRAHMA, versión).
- [ ] Para cada operación: schema, riesgo, dry-run, confirmación, timeout, auditoría append-only.
- [ ] Prohibido: shell arbitrario, escalado silencioso, secretos en logs.
- [ ] D-Bus/Polkit/KDE integración mínima y justificada.
- [ ] Instalar/activar systemd units **solo con autorización explícita** + rollback.

## H. BRAHMA OS — Fase 10 (distro, solo autorizado)
- [x] `docs/DISTRO_PLAN.md`; base Kubuntu/KDE candidata.
- [ ] Definir perfil mínimo de paquetes y servicios bajo demanda.
- [ ] Integrar BRAHMA CORE + DESKTOP en sesión/servicios de usuario o sistema según diseño.
- [ ] Branding/shell de nueva interfaz, first-boot, cuenta/seguridad.
- [ ] Pipeline ISO reproducible (herramienta validada: live-build/Cubic/debootstrap u otra).
- [ ] Recuperación/rollback, updates, hardening (firewall local, least privilege).
- [ ] SBOM y cumplimiento licencias (Python deps, Ollama, componentes KDE/Ubuntu, **AGPL** si aplica).
- [ ] Pruebas: VM + checklist hardware real.

## I. Mejoras técnicas transversales
- [ ] Pydantic/SQLAlchemy/FastAPI deprecations (lifespan, config patterns) con pruebas.
- [ ] Observabilidad: métricas locales, logs estructurados con request/model IDs (sin datos sensibles).
- [ ] Límites: tamaño ingesta, rate API local, timeouts adaptadores, colas.
- [ ] Migraciones y fixtures de test idempotentes; DB tests aislada.
- [ ] Documentar contratos API (OpenAPI estable) y versionado.

## J. Comandos de verificación rápida
```bash
cd /home/yago/BRAHMA
.venv/bin/python -m pytest -q
.venv/bin/uvicorn core.brahma_core.main:app --host 127.0.0.15 --port 8000 --reload
curl -s http://127.0.0.1:11434/api/tags   # si ollama serve activo
/home/yago/.local/bin/uv --version
```

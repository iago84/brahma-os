# Integración del PARADIGMA AINA en BRAHMA OS — Estudio de integración

> Fecha: 2026-11-26 (**rev. 2 — re-baseline**; 2026-11-27: A3 completa — gobernador — y A4 — aprobaciones +
> parada de emergencia) · Autor: agente
> de sistemas (TRAE) · Alcance: `F:\TRABAJO\TO WORK ON QUICK\TRABAJO EXTRA\AINA` →
> `F:\TRABAJO\TO WORK ON QUICK\TRABAJO EXTRA\BRAHMA`
> **Nota de revisión:** la **rev. 1** de este documento apuntaba a la ruta antigua `F:\TRABAJO\NEW AI`.
> El proyecto AINA se ha **movido** a `TO WORK ON QUICK\TRABAJO EXTRA\AINA\` y **ha evolucionado**
> (NAIRA-CORE: gobernador de capacidades, scheduler/cuotas, recuperación de tareas, migración 0010;
> PARADIGMA-AINA: v5 con 4 carpetas de perfil y orquestación; y **consolidación autorizada** del conjunto
> AINA en `TRABAJO EXTRA\AINA\`). El **delta exacto** frente a la rev. 1 está en el
> **Anexo B**.
> Estado: **estudio/diseño** (sin commits). Código ya construido: la fase **A3 completa** en la copia
> canónica WSL `~/BRAHMA` (sin commit) — motor de política **+ gobernador de capacidades** y tests de
> seguridad (2026-11-27, ver §7/A3 y §9).
> Reglas seguidas: dry-run, sin tocar `.venv`/`node_modules`, sin volcar secretos, sin pisar el trabajo de
> la otra sesión sobre PARADIGMA-AINA.
> Coordinación: la otra sesión de chat trabaja el proyecto **PARADIGMA-AINA** (Agente 20,
> `DOCS\PARADIGMA_AINA_INVESTIGACION_Y_PLAN.md`). Este documento estudia **el paradigma AINA como
> conjunto** (los sistemas y agentes que viven en `AINA\`) y su encaje en **BRAHMA OS**.

---

## 0. Resumen ejecutivo (TL;DR)

El "PARADIGMA AINA" es, en la práctica, **tres sistemas** con distinto grado de madurez, más una
**carta de gobernanza**:

| Pieza | Ruta | Qué aporta | Madurez real |
|---|---|---|---|
| **NAIRA-CORE** | `AINA\NAIRA-CORE` | Plano de control: identidad/RBAC, **motor de política (deny-by-default)**, **gobernador de capacidades (allowlist + restricciones duras)**, motor de tareas + **dispatcher** + **scheduler/cuotas**, **recuperación de tareas**, **aprobaciones + parada de emergencia**, bus de eventos + outbox, gateway de modelos, hub de integración, auditoría | Código real, 26 suites de test, migraciones Alembic **0001–0010**, ADRs **001–005**; snapshot `docs/PROJECT_STATUS.md` **2026-11-25** |
| **AIPCSYS** | `AINA\AIPCSYS_CODEBASE` | Plataforma/UX local + **registries** (agentes, skills, workflows, pipelines, conectores), **motor de sugerencias** (cron; `SUG-0001..0100`), instalador no destructivo, **detección de hardware → selección de modelo**, layout de memoria/artefactos | Instalador + catálogos reales; **todo el catálogo en `candidate`/`validation_passed=false`**; último cron **2026-11-22** |
| **PARADIGMA-AINA** | `AINA\PARADIGMA-AINA` (**4 carpetas de perfil**) | **Generación de código desde specs tabulares** (packs CSV → composer → generators) + **RAG local** (TF-IDF + hashing 256-dim) + testgen + **orquestación** (`worker_caps`/`workflows`) + **servicios de ingesta** (local y GitHub) | **AINA v5** (RAG + API tests Node + fixtures FK + stack `skeletor_django`); perfiles `deployed-paradigma-aina` / `dev-naira-studio` / `legacy-12-Education` (+ `development-still-pendant`, **vacía**) |
| **AI_CONSTITUTION** | `AINA\AIPCSYS_CODEBASE\RESEARCH\samo-tech-skills-tree\AI_CONSTITUTION.md` | Gobernanza: documentación como *gate de cierre*, ciclo `OBSERVE→…→DECIDE`, escalado, decisiones (DECISION-ID), etiquetas de estado | Modelo de governance, no código |

**Conclusión:** BRAHMA ya tiene la *forma* correcta (CORE / DESKTOP / OS + capa IA reversible), pero le
faltan **contratos ejecutables de seguridad y orquestación**. AINA aporta exactamente eso. La
recomendación no es *copiar* esos repos dentro de BRAHMA (NAIRA-CORE es específico de NAIRA; el backend
de AIPCSYS no está versionado), sino **adoptar sus patrones y esquemas** y reimplementarlos como
módulos propios de BRAHMA CORE/SYSTEM, con las fronteras de integración que el propio AINA ya define
(ADR-004): adaptadores + contratos versionados, **sin compartir bases de datos**.

Mayor impacto / menor riesgo, por orden:
1. **Policy engine + risk taxonomy + gobernador de capacidades + aprobación firmada + parada de emergencia** (NAIRA-CORE) → convierte la Fase 9 (SYSTEM) de "allowlist read-only" en un sistema real de permisos.
2. **Capability Manifest** (un esquema) para MODES/tools de BRAHMA (lo mejor de AIPCSYS registry + risk classes de NAIRA-CORE).
3. **Task engine + event bus/outbox** (NAIRA-CORE) como cimiento del modo AUTOMATION y de la auditoría (incluye scheduler/cuotas y recuperación).
4. **Layout estándar del home** (`MEMORY/`, `ARTIFACTS/`, `CONFIG/{development,production,secrets}`, `AUDIT/`, `BACKUPS/`) y **first-boot guiado** (patrón AIPCSYS installer + detección de hardware).
5. **RAG local** (PARADIGMA-AINA) sobre la propia documentación/registros de BRAHMA ("un OS que se conoce a sí mismo").
6. **AI_CONSTITUTION** como constitución operativa de BRAHMA (formaliza lo que ya se hace por registro).

---

## 1. Qué es el PARADIGMA AINA (inventario honesto)

### 1.1 NAIRA-CORE — el plano de control (maduro)

Documentado en `AINA\NAIRA-CORE\docs\`. Es un **monolito modular local-first** (FastAPI + SQLAlchemy +
Alembic; SQLite local / PostgreSQL 16 híbrido). Principios (README):
local-first, monolito modular antes que microservicios, fronteras explícitas y contratos versionados,
integraciones opcionales que **no impiden el arranque**, mínimo privilegio y ejecución auditable.
**No es Django**: los módulos son paquetes Python (`src/naira_core/`) y las migraciones son de **Alembic**.

Módulos con sustancia real (verificados en código/docs):

- **Identidad y seguridad** — principales humanos y de servicio, credenciales (Argon2id), sesiones
  opacas, roles, permisos, **deny-by-default**, API keys mostradas una vez y guardadas hasheadas, rate
  limiting, contexto de principal + `correlation_id` por petición.
- **Motor de política** (`docs/security/POLICY_DECISION_ENGINE.md`, `src/naira_core/policy/engine.py`) —
  **taxonomía de riesgo** (`read_only`, `reversible_write`, `external_communication`, `destructive`,
  `privileged`), perfiles de autonomía (`supervised`, `standard`, `high`) y 3 resultados (`allow`,
  `require_approval`, `deny`). Riesgo o metadato desconocido ⇒ **deny**. Es un evaluador de dominio
  **puro** (sin BD ni red); el scope de recurso es *exact-match* (sin comodines). `evaluate_policy()`
  + dataclasses frozen `CapabilityDeclaration`, `PolicyContext`, `PolicyDecision`.
- **Gobernador de capacidades** (`src/naira_core/policy/capabilities.py`) — **allowlist explícito**
  (`CapabilityCatalog`) + perfiles con **techo de riesgo** (`AutonomyProfileDefinition.narrows()`, sólo
  puede *reducir* alcance) + **restricciones duras** que ningún perfil puede saltarse
  (`ConstraintViolation`: `NO_ARBITRARY_SHELL`, `NO_ARBITRARY_FILESYSTEM`, `NO_ARBITRARY_NETWORK`,
  `NO_ARBITRARY_MODEL_TOOL`, `NO_SELF_AUTHORIZING`, `NO_EXTERNAL_EGRESS_WITHOUT_POLICY`) +
  `CapabilityGovernor` (deny-by-default). Perfiles `SUPERVISED_PROFILE`, `STANDARD_PROFILE`,
  `HIGH_PROFILE`, `AUTONOMY_PROFILES`.
- **Motor de tareas + dispatcher** (`docs/architecture/TASK_DISPATCHER.md`, ADR-003) — máquina de estados
  persistida, leases, reintentos con idempotencia explícita, registro de handlers **explícito** (nada de
  import dinámico), reevaluación de política *inmediatamente antes* de ejecutar. `dispatch_once`.
  Estados incluyen `awaiting_approval` y cancelación cooperativa (migración 0010).
- **Scheduler/cuotas** (`src/naira_core/tasks/scheduler.py`, CORE-034) — `TaskScheduler` con límite de
  concurrencia global y por principal, cuotas y capacidad de cola, deadlines, apagado ordenado y
  métricas. **Deshabilitado por defecto** (el operador debe habilitarlo).
- **Recuperación de tareas** (`docs/architecture/TASK_RECOVERY.md`, `src/naira_core/tasks/recovery.py`,
  CORE-033) — `RecoveryEngine` de una pasada: sólo leases vencidos, sólo handlers declarados idempotentes
  (por defecto `false`), backoff exponencial acotado con jitter, **fail-closed** para no idempotentes
  interrumpidos, precedencia de cancelación/stop sobre retry; no lanza procesos de fondo.
- **Aprobaciones + parada de emergencia** (`docs/security/APPROVALS_EMERGENCY_STOP.md`) — aprobación
  ligada a capability + recurso exacto + **digest SHA-256 canónico** + versión de política; de un solo
  uso y con caducidad; **prohibida la auto-aprobación**; `core.emergency_stop` persistente que
  **falla en cerrado** si falta o está mal formado.
- **Bus de eventos + outbox transaccional** (`docs/architecture/EVENT_SYSTEM.md`) — sobre tipado con
  versión de esquema, suscriptores explícitos, entrega **at-least-once** (consumidores idempotentes por
  `event_id`), backoff con jitter, *dead-letter*, leases de entrega.
- **Gateway de modelos**, **hub de integración** (adaptadores con estado `disabled/disconnected/degraded/ready`)
  — todavía *trabajo futuro*, no implementados; **memoria/contexto con procedencia**, **observabilidad**
  con correlación extremo a extremo (futuro).

Gobernanza: `docs/decisions/ADR-001..005` (monolito modular, almacenamiento, eventos, contratos de
integración, **autonomía alta acotada por política** con 10 controles obligatorios) y
`docs/integration/*` (estrategia + evaluación read-only de AIPCSYS). Estado real en
`docs/PROJECT_STATUS.md` (snapshot **2026-11-25**, target 0.1.0, rama `develop`): integrados PR #1–#3 y
#5–#18; **pendiente la aceptación en máquina destino WSL2 Ubuntu 24.04** para CORE-034 (scheduler) y
CORE-044/045 (allowlists/perfiles). Límites honestos: sin scheduler ni publisher de fondo *habilitados por
defecto*; sin shell/filesystem/red/modelo/efectos externos arbitrarios; sin handler de producción
registrado.

### 1.2 AIPCSYS — la plataforma y sus registros (real, pero sin validar)

`AINA\AIPCSYS_CODEBASE`. Es una plataforma local (instalador PowerShell + backend FastAPI scaffold +
frontend React/Vite/TS + esquema HQ + adaptador OpenClaw; instalado en `F:\AIPCSYS`). Lo relevante para
BRAHMA:

- **Registries** (`REGISTRY\{agents,skills,workflows,pipelines,connectors}\*.json`): catálogos
  agregados de repos de GitHub. **Todas las entradas son `candidate` y `validation_passed=false`**;
  `operational_count: 0`. Un agente del catálogo trae campos útiles como `domain`, `level`,
  `models`, `languages`, `permission_profile: restricted`, `activation_panel_eligible`, `source`
  (procedencia) y `validation_passed`.
- **Motor de sugerencias** (`CORE\SCHEDULER\ai-suggestion-cron.ps1` + `CORE\REGISTRY\suggestions\SUG-0001..0100.json`
  y `REGISTRY\suggestions\SUG-0001..0025.json`): bucle que genera "sugerencias" (dominio, tema, keywords,
  nivel, tier de rack, modelos, idiomas) y puede **fusionarlas como agentes candidatos**. Es un
  **generador de borradores**, no un catálogo validado. Últimos logs de cron: **2026-11-22**.
- **Instalador no destructivo** (`Install-AIPCSYS.ps1`): inventario de hardware/software, scaffold sin
  sobrescribir, **loopback por defecto**, backup antes de tocar config ajena, `-SelectAIModel`
  (hardware → modelo), `-Https`/`-ConfigureLan` explícitos, UTF-8 sin BOM.
- **Layout de datos** (`DOCS/ARCHITECTURE.md`): `MEMORY/`, `ARTIFACTS/`, `PROJECTS/`, `WORKFLOWS/`,
  `SKILLS/`, `MODELS/`, `PROVIDERS/`, `CONFIG/{development,production,secrets}`, `LOGS/`, `AUDIT/`,
  `BACKUPS/`, `INBOX/`, `STORAGE/`, `SERVICES/`.
- **Frontend de referencia**: `FAIPCSYSFRONTENDapp/` (React+Vite+TS, puerto 48101; backend 48100).
- **Think**: `AINA\NAIRA-CORE\docs\integration\AIPCSYS_REGISTRY_ASSESSMENT.md` ya hizo la auditoría
  correcta de AIPCSYS: *"reutilizar como feed de descubrimiento; NO ejecutar contenido importado; no
  aceptar etiquetas de riesgo declaradas como autoritativas; no habilitar conectores MCP automáticamente"*.

### 1.3 PARADIGMA-AINA — el generador por specs (AINA v5, 4 carpetas de perfil)

Documentado en `DOCS\PARADIGMA_AINA_INVESTIGACION_Y_PLAN.md` (Agente 20). Es un **generador de proyectos
desde specs tabulares (CSV)** con **RAG local** y un modelo de **orquestación** por workers. Se organiza
en **cuatro carpetas de perfil** (`profiles.csv` + `profile.lock.json`; tres con contenido y una vacía):

- `PARADIGMA-AINA\deployed-paradigma-aina\` — perfil de **producción/despliegue** (incluye
  `linode_setup.sh`, `update_deploy.ps1`, `launch.ps1`, `scripts/install_service.ps1`,
  `scripts/uninstall_service.ps1`, `.env.test-deploy`).
- `PARADIGMA-AINA\dev-naira-studio\` — perfil de **desarrollo/estudio** (misma estructura que el de
  despliegue; nombre sugiere trabajo conjunto con NAIRA).
- `PARADIGMA-AINA\legacy-12-Education\` — perfil **legacy/educativo** (el más ligero: sin scripts de
  despliegue ni servicio Windows ni `.env.test-deploy`).
- `PARADIGMA-AINA\development-still-pendant\` — carpeta **vacía** (pendiente de desarrollo; vino de
  `TEMP_CLONED\DEVELOPMENT\STILL PENDANT\` en la consolidación de AINA).

Contenido común relevante (por perfil):

- **Núcleo real**: `composer\assemble.py` (resuelve perfil → packs → concatena a `spec/`),
  `aina\ai\tools\rag_local.py` (**RAG local**: TF-IDF disperso + vector hashed 256-dim `blake2b`, fusión
  `0.6·tfidf + 0.4·hash`, sin dependencias), `aina\ai\testgen_django.py` y `api_testgen_node.py`,
  `aina\ingest\scan_code.py`, `generators\node_gen.py`, `generators\skeletor_adapter_gen.py`.
- **Orquestación** (`aina\orchestration\`): `worker_caps.csv` (**15 workers** con capacidades
  `compose.profile`, `ingest.fs_crawl`, `generate.django|node|static|android`, `ai.summarize_spec`,
  `ai.contract_synth`, `ai.docs_from_spec`, `ai.testgen`, `test.contracts`, `test.api_smoke`,
  `package.bundle`, `publish.artifacts`), `workflows.csv` (`build_profile` y `build_profile_ai`),
  y directorios `runs/`/`triggers/`.
- **Servicios de ingesta** (`aina\services\`): `github_ingest_service` + `local_ingest_service`
  (con `aina\config\github_ingest.yml` / `local_ingest.yml`).
- **Packs** (`df_lib\`): `packs.csv` (`core 0.5.0`, `ecom 0.5.0`); subpacks `core/`, `ecom/`, `games/`
  (config, modos, niveles, paleta, scoring, tetrominoes), `wiki/` (articles, terms).
- **Spec** (`spec\`): CSV de `entities`, `fields`, `endpoints`, `contracts`, `articles`, `terms`,
  `android_features`, `game_*`, etc.
- **Otros**: `knowledge\` (`code_index.csv`, `symbols.csv`), `legal\` (cookies, disclaimer, privacy,
  terms), `third_party\skeletor\` (adaptadores; **a verificar licencia**).
- **Declarativo/por verificar**: `generators\django_gen.py`, `static_html_gen.py`, `android_gen.py`,
  `skeletor_django_gen.py`; `ai_skills.csv` declara `summarize_spec` y `contract_synth` (cuyo consumidor
  real **está por verificar**); `aina\ai\ai_policies.yml` (max_tokens 2048, PII redact, tools permitidas:
  `rag.retrieve`, `unit.testgen`). El README de los tres perfiles es idéntico: *"AINA v5 (focus): RAG +
  API tests Node + fixtures FK. Nuevo stack `skeletor_django`. Ingesta con feedback."*
- **Modelo de datos**: la "celda" sigue siendo un **escalar CSV** (no un JSON); el concepto "matriz de
  matrices" se aplana a un `spec/` plano. Prototipo aislado del modelo objetivo en
  `DOCS\PARADIGMA_AINA_PROTOTIPO\` (7 tests) con esquema de celda
  (`term/key/definition/python_code/help/...`).

### 1.4 AI_CONSTITUTION — la gobernanza (modelo, no código)

`AINA\AIPCSYS_CODEBASE\RESEARCH\samo-tech-skills-tree\AI_CONSTITUTION.md` (repo de investigación
`samo-tech-skills-tree`). Formaliza: autoridad (Humano → CEO/CIO → COO → especialistas), **escalado** de
decisiones, **documentación como gate de cierre** ("code without corresponding operational documentation
is an incomplete change"), mapa de documentación autoritativa, cero *drift*, `DECISION-ID`, **ciclo
agentico** `OBSERVE→ASSESS→PLAN→EXECUTE→VERIFY→RECORD→DECIDE` (techo 12 iteraciones), *preflight*
obligatorio, etiquetas de estado (`IN PROGRESS / BLOCKED / PARTIALLY COMPLETE / IMPLEMENTED—NOT VERIFIED
/ VERIFIED—DOCUMENTATION PENDING / COMPLETE`).

---

## 2. Por qué beneficia a BRAHMA (sinergias y solapamientos)

BRAHMA ya declaró el destino (ROADMAP §4): **OS → DESKTOP → CORE → (MIND · MEMORY · KNOWLEDGE · REKHA ·
AI ENGINE · MODES)**. Eso es una **pirámide de capas**; AINA aporta los **contratos** que faltan dentro
de esas capas.

| Necesidad de BRAHMA (hoy) | Aportación de AINA | Ganancia |
|---|---|---|
| **Fase 9 SYSTEM** = "allowlist read-only primero", sin modelo formal de permisos | Taxonomía de riesgo + perfiles de autonomía + `allow/require_approval/deny` (NAIRA-CORE) | Permisos **por modo** con semántica defendible y auditable |
| MODES declaran "política de permisos" sin esquema | **Capability Manifest**: riesgo, permisos, ámbito de recurso, timeout, efectos, idempotencia | Un solo contrato para todos los modos/tools |
| No hay "allowlist" ni límites duros por capability | **CapabilityGovernor** + `ConstraintViolation` (nada de shell/fs/red/modelo arbitrarios, ni auto-autorización) | Techo de seguridad que ningún modo/perfil puede saltarse |
| No hay ejecución asíncrona durable | Task engine + dispatcher + **scheduler/cuotas** + **recuperación** + **outbox** (ADR-003, CORE-033/034) | Modo AUTOMATION y auditoría con estado persistente |
| Aprobación de acciones sensibles "informal" | **Aprobación firmada** (digest + versión de política, single-use) + **parada de emergencia fail-closed** | Kill switch y aprobaciones reales |
| Memoria/artefactos sin layout fijo en el OS | Layout AIPCSYS (`MEMORY/`, `ARTIFACTS/`, `CONFIG/{development,production,secrets}`, `AUDIT/`, `BACKUPS/`) | Home estándar, reproducible y multi-perfil |
| First-boot y auto-ajuste de hardware en "diseño" | Instalador AIPCSYS: detección HW → `-SelectAIModel`, no destructivo, loopback-first | First-boot guiado y CPU-first ya probado |
| No hay catálogo de capabilities para la UI | Registries + `activation_panel_eligible` + procedencia (AIPCSYS) | "Panel de activación" del DESKTOP |
| DEV mode = "diff + aprobación" (idea) | Composer + generators + RAG local + orquestación por workers (PARADIGMA-AINA) | Generación desde specs + RAG sobre el propio repo |
| Registro/gobernanza por convención | **AI_CONSTITUTION**: doc-gate, DECISION-ID, estados | Gobernanza formal del repo BRAHMA |

**Solapamientos a evitar (no duplicar):**
- BRAHMA CORE (MIND/MEMORY/KNOWLEDGE/REKHA) ≈ NAIRA-CORE (orquestación/memoria). **No fusionar**: adoptar
  sólo los *patrones* de política/ejecución que BRAHMA no tiene; BRAHMA mantiene su fuente de verdad.
- **No copiar NAIRA-CORE dentro de BRAHMA** (es específico de NAIRA y ADR-004 prohíbe el acoplamiento);
  BRAHMA **reimplementa** los módulos que necesite.
- La **orquestación** de PARADIGMA-AINA (`worker_caps`/`workflows`/`runs`) **solapa** con el task engine
  de NAIRA-CORE/BRAHMA: alinear (mismo vocabulario de workers/tasks), **no** crear dos motores de fondo.
- PARADIGMA-AINA y BRAHMA DEV mode: alinear, no duplicar (el generador es una *herramienta* del modo DEV).

**Lo que NO se adopta (y por qué):**
- **Ejecutar** el catálogo masivo de skills/agentes/conectores: todos `candidate`, `validation_passed=false`.
- Copiar el backend de AIPCSYS: **no está versionado** en el repo (el instalador lo scafflea); sólo son
  reutilizables sus catálogos y su lógica de instalación.
- Confiar en las etiquetas de riesgo declaradas en catálogos (`risk_level: low` genérico).
- Integrar código AGPL (`free-claude-code`) ni `third_party/skeletor` sin revisión de licencia.

---

## 3. Arquitectura de integración por capas

Modelo en capas (de abajo arriba). La columna "AINA" indica qué pieza encaja en cada capa.

```text
Capa                     BRAHMA (destino)                         AINA (qué aporta)                      Decisión
L6 Funciones             MODES: TEXT/KNOWLEDGE/DEV/SYSTEM/...      Capability Manifest + catálogo         ADOPTAR esquema
L5 Interfaz (DESKTOP)    React+Vite+TS web + Qt6/QML              Web console (NAIRA) + frontend (AIPCSYS) ADOPTAR patrón
L4 Orquestación segura   Fase 9 SYSTEM                            Policy engine + gobernador + aprobaciones + stop ADOPTAR patrón
L3 Núcleo                CORE: MIND/MEMORY/KNOWLEDGE/REKHA/AI     Task engine + scheduler + recover + event bus/outbox ADOPTAR infr. ligera
L2 Runtime IA            Ollama local (CPU-first, 1 modelo)       Gateway de modelos + routing           ADOPTAR esquema
L1 Init/servicios        systemd · D-Bus · Polkit                 (unit/logs; AIPCSYS es Windows)        ADAPTAR idea
L0 Base                  Kubuntu/KDE (PC) · Debian (SBC)          (instalador: detección HW)             ADAPTAR idea
```

### 3.1 L0 — Base (kernel, boot, distro)

- Sin cambios en el kernel. AINA **no aporta kernel**; aporta **patrón de puesta en marcha**:
  detección de hardware → elección de perfil de modelo (`-SelectAIModel` de AIPCSYS) y **scaffold no
  destructivo**. Encaja con la idea "**Perfil de hardware auto-ajuste** (`num_ctx`/`num_predict` según
  RAM/CPU)" de `IDEAS_INNOVADORAS.md` §Candidatos.
- **Acción de integración:** definir un `brahma-hwprofile` que, en first-boot, mida CPU/RAM/GPU y fije
  `BRAHMA_OLLAMA_*` (ya existe la base: `qwen3:1.7b` + `bge-m3`, `ctx=4096`, `predict=512`).

### 3.2 L1 — Init y servicios (systemd, D-Bus, Polkit)

- AINA está pensado para Windows/WSL; su parte de servicios no es portable directamente. **Se adapta la
  idea**: BRAHMA SYSTEM expone operaciones allowlisted; **systemd/Polkit sólo si se justifica** (ya es
  regla de BRAHMA). El requisito `Optional integrations must not prevent core startup` (NAIRA-CORE) se
  traduce a: **unit opcionales** que no bloquean el arranque de BRAHMA.
- **Acción:** unidades `brahma-core.service` / `brahma-ai.service` **opt-in**, con `ConditionPathExists`
  y sin dependencia dura; la IA arranca **bajo demanda** (`BRAHMA_AI_ENABLED=false` por defecto).

### 3.3 L2 — Runtime IA

- Adoptar el patrón **Gateway de modelos** de NAIRA-CORE (registro de proveedores + metadatos + routing +
  timeout/fallback + `usage`), aplicado a Ollama local. Reglas heredadas: **egress remoto desactivado
  salvo autorización explícita**, la **salida de un modelo es dato no confiable**, y **un modelo no puede
  conceder permisos ni aprobar acciones**.
- **Acción:** `ai_engine` de BRAHMA gana un registry de proveedores con estado
  `disabled/disconnected/degraded/ready` (mismo vocabulario que el hub de integración de NAIRA-CORE).

### 3.4 L3 — Núcleo (CORE): orquestación y estado

- BRAHMA CORE ya tiene API v1, MEMORY, KNOWLEDGE, REKHA. Lo que **falta** y AINA resuelve: **motor de
  tareas persistido + bus de eventos + outbox transaccional** (+ **scheduler/cuotas** y **recuperación**
  de NAIRA-CORE CORE-033/034). Se adopta en versión **ligera** (sin Redis ni broker; en proceso), tal como
  NAIRA-CORE decidió en ADR-003, y **deshabilitado por defecto**.
- **Contrato de evento** a copiar: `event_id`, `type`, `schema_version`, `timestamp UTC`, `producer`,
  `subject`, `correlation_id`, `causation_id`, payload Pydantic validate; desconocido ⇒ **fail-closed**;
  consumidores **idempotentes por `event_id`** (entrega at-least-once).
- **Acción:** tablas `task`, `task_transition`, `task_event`, `outbox` en PostgreSQL (la fuente de verdad
  de BRAHMA); migraciones Alembic; `dispatch_once` como primer paso, worker/scheduler después y sólo con
  autorización; recuperación **fail-closed** para tareas no idempotentes.

### 3.5 L4 — Orquestación segura (SYSTEM) — **el mayor salto de calidad**

Núcleo del estudio. Se reimplementan en BRAHMA los cuatro módulos de seguridad de NAIRA-CORE:

1. **Risk taxonomy + Policy evaluator** (de `POLICY_DECISION_ENGINE.md`):
   - Riesgos: `read_only` · `reversible_write` · `external_communication` · `destructive` · `privileged`.
   - Perfiles/“modos de autonomía” de BRAHMA: `OBSERVER`≈`supervised`, `ASSISTANT`≈`standard`,
     `OPERATOR`≈`high` (los tres privilegios ya definidos en `ROADMAP.md` §2 y `SYSTEM 9`).
   - Semántica: sólo `read_only` (y `reversible_write` acotado en `high`) puede ejecutar sin aprobación;
     `external_communication`/`destructive`/`privileged` ⇒ **require_approval**; riesgo/scope
     desconocido ⇒ **deny**. Scope de recurso *exact-match* (sin comodines).
   - El evaluador es **dominio puro** (sin BD/red): recibe contexto confiable (principal, permisos,
     capability, recurso exacto, entorno, perfil, versión de política, estado de stop).
2. **Gobernador de capacidades** (de `policy/capabilities.py`): **allowlist** explícito + perfiles con
   techo de riesgo (`narrows()`, sólo reduce) + **restricciones duras** (`ConstraintViolation`) que
   ningún perfil salta: `NO_ARBITRARY_SHELL/FILESYSTEM/NETWORK/MODEL_TOOL`, `NO_SELF_AUTHORIZING`,
   `NO_EXTERNAL_EGRESS_WITHOUT_POLICY`.
3. **Aprobaciones** (de `APPROVALS_EMERGENCY_STOP.md`): aprobación ligada a capability + recurso exacto +
   **digest SHA-256 canónico del payload** + versión de política; de un solo uso; caduca;
   **auto-aprobación prohibida**; todo auditado; un cambio de payload/recurso/versión **invalida** la aprobación.
4. **Parada de emergencia** (`core.emergency_stop`): persistente; **fail-closed** si falta o está corrupto;
   bloquear nuevas tareas y cancelar lo encolado en la misma transacción; no falsificar "detenido".

**Encaje concreto:** esto convierte la Fase 9 de BRAHMA en un sistema de permisos real, y es la base
para que el modo DEV ("diff + aprobación") y SYSTEM ("read-only primero") tengan garantías, no promesas.

### 3.6 L5 — Interfaz (BRAHMA DESKTOP)

- Adoptar el **patrón de consola web** de NAIRA-CORE (`PLATFORM_SPECIFICATION.md` §3.10): vistas de
  *Overview / Tasks / Approvals / Integrations-Models / Security / Audit / Settings*; **toda acción pasa
  por la API y se re-autoriza en servidor**; el front **no accede a la BD** ni guarda secretos.
- De AIPCSYS: el **panel de activación** de capabilities (`activation_panel_eligible`) y el **frontend
  React+TS** (`FAIPCSYSFRONTENDapp/`) como referencia visual.
- Coherente con `IDEAS_INNOVADORAS.md` §8 ("estados explícitos offline/degradado/AI-disabled/DB-down").
- **Acción MVP:** añadir a `interface/web` (React+Vite+TS) las pantallas de estado, chat MIND, KNOWLEDGE,
  REKHA read-only y **Consola SYSTEM (OBSERVER)** + **Centro de aprobaciones** + **Parada de emergencia**.

### 3.7 L6 — Funcionalidades (MODES)

Un **Capability Manifest** único (síntesis de AIPCSYS registry + NAIRA-CORE risk) para cada modo/tool:

```yaml
# capability manifest (borrador de esquema)
id: sys.service.status
kind: mode_tool            # mode_tool | agent | skill | workflow | connector
risk: read_only            # read_only|reversible_write|external_communication|destructive|privileged
permissions: [system.read]
resource_scope: ["service:*"]
side_effects: none
timeout_ms: 3000
idempotent: true
requires_approval: false
provenance: { source: brahma, version: 0.1.0, license: "" }
status: candidate          # candidate | validated | operational
validation_passed: false
activation_panel_eligible: true
```

Regla (heredada de AIPCSYS-ASSESSMENT): **ningún elemento `candidate` se ejecuta**; un elemento sólo
llega a `operational` tras validación real y binding a permisos.

---

## 4. Adaptación del entorno Linux, capa a capa (detalle operativo)

| Capa | Elemento | Qué hacer | Herramienta/patrón de AINA | Riesgo |
|---|---|---|---|---|
| L0 | Detección HW + auto-ajuste | `brahma-hwprofile` en first-boot; fija `BRAHMA_OLLAMA_*` | `-SelectAIModel` (AIPCSYS) | Bajo |
| L0 | Instalador no destructivo | `brahma-firstboot` idempotente, nunca sobrescribe config de usuario | `Install-AIPCSYS.ps1` | Bajo |
| L1 | Servicios opt-in | units `brahma-{core,ai}.service` sin dependencia dura | "integración opcional no bloquea arranque" | Medio |
| L1 | Privilegios | `OBSERVER/ASSISTANT/OPERATOR` ↔ perfiles de autonomía | Policy engine (NAIRA-CORE) | Medio |
| L2 | Runtime IA | registry de proveedores + estado `ready/degraded/...`; egress off | Model Gateway (NAIRA-CORE) | Bajo |
| L2 | RAG local | indexar docs/registros de BRAHMA (offline, sin deps) | `rag_local.py` (PARADIGMA-AINA) | Bajo |
| L3 | Estado de tareas | tablas task/transition/event/outbox en PostgreSQL + Alembic | Task engine + outbox (NAIRA-CORE) | Medio |
| L3 | Scheduler/cuotas + recuperación | concurrencia, cuotas, deadlines; recovery fail-closed | CORE-033/034 (NAIRA-CORE) | Medio |
| L3 | Contrato de eventos | sobre tipado versionado, idempotente, fail-closed | EVENT_SYSTEM.md | Bajo |
| L4 | Política | evaluador puro + contexto confiable + **reevaluar antes de ejecutar** | POLICY_DECISION_ENGINE.md | Alto |
| L4 | Gobernador de capacidades | allowlist + restricciones duras + techo por perfil | `policy/capabilities.py` (NAIRA-CORE) | Alto |
| L4 | Aprobaciones | digest canónico + single-use + caducidad + no auto-aprobación | APPROVALS_EMERGENCY_STOP.md | Alto |
| L4 | Parada de emergencia | `brahma.emergency_stop` persistente, fail-closed | ídem | Alto |
| L5 | DESKTOP | consola estado/chat/KNOWLEDGE/REKHA + aprobaciones + stop | Web console (NAIRA-CORE) | Bajo |
| L5 | Panel de activación | capabilities con procedencia y estado | Registries (AIPCSYS) | Bajo |
| L6 | MODES | Capability Manifest por modo/tool | síntesis AIPCSYS+NAIRA | Medio |
| — | Home estándar | `MEMORY/ ARTIFACTS/ CONFIG/{development,production,secrets} AUDIT/ BACKUPS/` | Layout (AIPCSYS) | Bajo |
| — | Gobernanza | doc-gate, DECISION-ID, etiquetas de estado, preflight | AI_CONSTITUTION | Bajo |

Principios transversales a respetar (ya vigentes en BRAHMA, ahora reforzados por AINA):
- IA **reversible** (`BRAHMA_AI_ENABLED=false` por defecto; el OS arranca sin BRAHMA).
- **CPU-first**, 1 modelo, carga perezosa, 1 petición.
- **Nada privilegiado** sin autorización explícita + rollback.
- **Sin secretos** en imagen/logs/docs; secretos sólo en `CONFIG/secrets` (o gestor del SO).

---

## 5. Funcionalidades: clásicas, extra e innovadoras

### 5.1 Clásicas (esperables, ahora con respaldo)
- **Escritorio** KDE Plasma mínimo + integración de bandeja (patrón `Launch-AIPCSYS.ps1`).
- **Terminal/Shell estándar** intactos; la IA es una capa, no un reemplazo.
- **First-boot guiado**: cuenta, idioma/i18n, branding, detección de hardware.
- **Actualizaciones firmadas**, backup antes de cambios (`BACKUPS/`).
- **Consola de estado** (health/ready) y **registro de auditoría**.

### 5.2 Extra (aprovechan AINA directamente)
- **Centro de Aprobaciones**: ver acción/recurso/riesgo y aprobar/rechazar con motivo (NAIRA-CORE §3.10).
- **Parada de emergencia** visible en el escritorio (usabilidad + seguridad).
- **Panel de capabilities** con procedencia, riesgo y estado `candidate/validated/operational` (AIPCSYS).
- **RAG sobre la propia máquina**: KNOWLEDGE indexa documentación/registros/logs locales (PARADIGMA-AINA `rag_local`).
- **Modo DEV con specs**: componer/generar código desde packs CSV (PARADIGMA-AINA composer/generators) con
  **diff propuesto + aprobación**.
- **Observabilidad correlacionada**: `correlation_id` de petición → tarea → política → proveedor → resultado.

### 5.3 Innovadoras (la "nueva interfaz" y el OS AI-native)
- **"Un cerebro, ocho modos, permisos por modo"**: cada modo declara Capability Manifest y el OS lo
  **aplica a nivel de shell/servicio**, no sólo en UI (ya en `IDEAS_INNOVADORAS.md` §1, ahora con esquema).
- **Epistémica visible** en cada respuesta (`hecho/evidencia/inferencia/hipótesis/desconocido/contradicción`)
  + salto a la fuente (REKHA/KNOWLEDGE). BRAHMA ya lo propone; se formaliza como contrato de salida.
- **OS que se conoce a sí mismo**: RAG local sobre su propia doc/registros; "¿por qué crees esto?" con traza.
- **Motor de sugerencias gateado**: BRAHMA propone nuevas capabilities/skills (patrón SUG-XXXX) **como
  candidatas**, nunca auto-trust. Diferencial vs AIPCSYS: en BRAHMA un candidato **no es ejecutable**.
- **Gobernanza como código**: AI_CONSTITUTION aplicada al repo BRAHMA (doc-gate, DECISION-ID, estados,
  preflight) — convierte el "registro" informal en invariante verificable.
- **Asistente de recuperación (boot rescue)** con IA local para diagnosticar arranque (ya en candidatos).
- **Perfil de hardware auto-ajuste** + **sandbox de paquetes** (flatpak/permisos declarados).
- **`dispatch_once` como primitive de automatización auditable**: cada automatización es una *task* con
  política, aprobación (si aplica) y eventos persistidos — nada de "ejecutar y esperar".

---

## 6. Riesgos, licencias y límites

| Riesgo | Detalle | Mitigación |
|---|---|---|
| Catálogo no validado | skills/agentes/conectores de AIPCSYS son `candidate` | Sólo `operational` tras validación + binding de permisos |
| "Riesgo declarado" no es riesgo real | AIPCSYS trae `risk_level: low` genérico | Ignorar etiquetas; evaluar con el policy engine de BRAHMA |
| Acoplamiento entre repos | NAIRA-CORE es específico de NAIRA | ADR-004: adaptadores + contratos versionados, **sin compartir BD** |
| Backend AIPCSYS no versionado | El instalador lo scafflea; no es fuente revisable | No reutilizar su backend; sólo catálogos + lógica de instalación |
| Duplicar orquestación | PARADIGMA-AINA (`worker_caps`/`workflows`) ≈ task engine | Un solo motor de fondo (BRAHMA CORE); AINA alinea vocabulario |
| Licencias | `free-claude-code` es **AGPL-3.0-only** (ya aislado); `third_party/skeletor` a verificar | Aislar, no redistribuir sin revisión legal/TOS; SBOM |
| Complejidad del policy engine | Mal implementado da falsa seguridad | Evaluador **puro** + tests de seguridad (deny-by-default, stale approval, self-approval, scope escalation, stop) |
| Aceptación pendiente en destino | NAIRA-CORE CORE-034/044/045 y WSL2 sin aceptar en máquina real | No adoptar como "probado" hasta evidencia de aceptación |
| Privilegios OS | systemd/Polkit particionado | Opt-in, dry-run, auditoría, rollback, autorización explícita |
| Recursos (7–8 GB WSL, FX-6300) | 1 modelo local | CPU-first, no simultáneo, timeouts, keep-alive corto |

---

## 7. Roadmap de adopción propuesto (por fases, dry-run primero)

> Cada fase: criterio de aceptación verificable + autorización explícita cuando toque privilegios.
> **Estado** refleja lo hecho a 2026-11-26 (no implica commits ni cambios de sistema).

- **A1 — Contratos, sin código.** Documento de integración + borrador de **Capability Manifest** + mapa
  capa-a-capa. *Aceptación:* doc revisado; sin cambios de sistema. **Estado: ✅ hecho** (este documento,
  rev. 2 re-baselined).
- **A2 — Home y first-boot (L0/L1, bajo riesgo).** Layout estándar + `brahma-hwprofile` + units opt-in
  (no instaladas). *Aceptación:* dry-run del scaffold; arranque normal sin BRAHMA intacto. **Estado: ⬜ pendiente**.
- **A3 — Policy engine + Capability Manifest + gobernador (L4).** Evaluador puro + allowlist/perfiles +
  restricciones duras + tests de seguridad. *Aceptación:* `deny-by-default`, riesgo desconocido ⇒ deny,
  `require_approval` correcto; suite verde. **Estado: ✅ hecho** (2026-11-27) — evaluador puro (22 tests) +
  **gobernador de capacidades** `governor.py` (`CapabilityCatalog`, `CapabilityGovernor`,
  `AutonomyProfileDefinition.narrows()`, `ConstraintViolation` ×6; 22 tests) en WSL: **44 tests verdes**
  (59 en la suite completa). **Pendiente menor:** binding real de permisos por modo/tool (llega con A4/A5).
- **A4 — Aprobaciones + parada de emergencia (L4).** Digest canónico, single-use, fail-closed.
  *Aceptación:* tests de auto-aprobación, caducidad, replay, stop que bloquea/cancela. **Estado: ✅ hecho**
  (2026-11-27) — `core/brahma_core/governance/{approvals,emergency_stop}.py` en WSL: digest SHA-256 canónico,
  aprobación de un solo uso ligada a la acción exacta (capability+recurso+payload+versión+tarea),
  **auto-aprobación prohibida**, caducidad; parada **fail-closed** (ausente/corrupta ⇒ activa) con puerto de
  cancelación cooperativa. **30 tests** (24 + 6). Suite completa: **89 verdes**.
- **A5 — Task engine + eventos/outbox + scheduler/recovery (L3).** Tablas + Alembic + `dispatch_once`
  (+ scheduler/cuotas y recuperación fail-closed). *Aceptación:* at-least-once con idempotencia; estados
  persistidos; auditoría. **Estado: ⬜ pendiente**.
- **A6 — DESKTOP: consola + aprobaciones + stop (L5).** *Aceptación:* Playwright smoke local; sin
  acciones privilegiadas desde UI; re-autorización en servidor. **Estado: ⬜ pendiente**.
- **A7 — RAG local + modo DEV (L2/L6).** Indexar docs/registros; composer/generators como herramienta
  del modo DEV con diff+aprobación. *Aceptación:* consulta offline devuelve fuentes; generación determinista reproducible. **Estado: ⬜ pendiente**.
- **A8 — Gobernanza como código.** Adoptar doc-gate/DECISION-ID/estados de AI_CONSTITUTION en BRAHMA.
  *Aceptación:* plantillas + invariante "nada COMPLETE sin doc". **Estado: ⬜ pendiente**.

Dependencias: A3→A4→A5 (política precede a aprobación y a dispatch); A6 tras A4/A5; A7 y A8 paralelizables.

---

## 8. Decisiones (abiertas y confirmadas)

> **Decisiones confirmadas 2026-11-26 (usuario):** (1) **ubicación canónica** = `BRAHMA\docs\` (F:) +
> copia canónica WSL `~/BRAHMA/docs/`; (2) **reimplementar patrones** — adoptar esquemas y contratos,
> **sin copiar** NAIRA-CORE (ADR-004); (3) **primer módulo** = **A3 (policy engine)**; (4) base PC ya
> decidida (Ubuntu LTS + KDE Plasma mínimo); (5) registro hecho en §3/§5 de
> `REGISTRO_SESIONES_Y_TAREAS.md`; (6) sincronizado a la copia canónica WSL.

1. **Ubicación de AINA**: el proyecto se movió de `F:\TRABAJO\NEW AI` a
   `F:\TRABAJO\TO WORK ON QUICK\TRABAJO EXTRA\AINA`. **Decisión:** es la ruta canónica de aquí en
   adelante; rev. 1 quedaba obsoleta. *(Confirmado por re-baseline 2026-11-26.)*
2. **Alinear A3 con el gobernador de capacidades** (nuevo en NAIRA-CORE CORE-044/045): **Resuelto**
   (2026-11-27) — se amplió A3 con `ConstraintViolation` (×6), `CapabilityEntry`, `CapabilityCatalog`,
   `AutonomyProfileDefinition` (perfiles SUPERVISED/STANDARD/HIGH con `narrows()`) y `CapabilityGovernor`
   en `core/brahma_core/policy/governor.py`, **reimplementando** el patrón (sin copiar, ADR-004).
3. **Orquestación sin duplicar**: PARADIGMA-AINA ya trae `worker_caps`/`workflows`/`runs`; decidir el
   reparto con el task engine de BRAHMA (A5). *(Pendiente.)*
4. **Sincronización de código CORE**: hoy `core/brahma_core/` sólo vive en WSL (sin commits); decidir si
   se versiona también en el repo F: `iago84/brahma-os`. *(Pendiente.)*
5. **Registro**: coordinar ficha per-app de AINA con la sesión del Agente 20 para no duplicar. *(Pendiente.)*

---

## 9. Ficheros propuestos / creados y registro

Estado real de los artefactos (a 2026-11-27):

| Artefacto | Capa | Estado |
|---|---|---|
| `docs/INTEGRACION_PARADIGMA_AINA.md` (este estudio) | — | ✅ creado (rev. 2) |
| `docs/CAPABILITY_MANIFEST.md` (esquema) | L6 | ⬜ propuesto (borrador en §3.7) |
| `core/brahma_core/policy/` (evaluador puro + gobernador + tests) | L4 | ✅ creado en WSL (`taxonomy.py`, `manifest.py`, `evaluator.py`, `governor.py`, `__init__.py`, `tests/test_policy.py`, `tests/test_governor.py`; **44 tests verdes**); sin commit |
| `core/brahma_core/policy/governor.py` (gobernador) | L4 | ✅ creado en WSL (fase A3, ampliación 2026-11-27; `CapabilityCatalog`, `CapabilityGovernor`, `ConstraintViolation` ×6, perfiles SUPERVISED/STANDARD/HIGH) |
| `core/brahma_core/governance/{approvals,emergency_stop}.py` (+ tests) | L4 | ✅ creado en WSL (fase A4, 2026-11-27; digest canónico, single-use, no auto-aprobación, caducidad; stop fail-closed con cancelación cooperativa; **30 tests**) |
| `core/brahma_core/tasks/` (task engine + outbox + scheduler + recovery) | L3 | ⬜ propuesto (fase A5) |
| `docs/decisions/0009-adopcion-paradigma-aina.md` (ADR de BRAHMA) | — | ⬜ propuesto |
| `brahma-os/base/hwprofile/` (detección HW) | L0 | ⬜ propuesto (fase A2) |
| `interface/web` pantallas aprobaciones/stop | L5 | ⬜ propuesto (fase A6) |

**Registro:** este estudio se anota en `F:\TRABAJO\REGISTRO_SESIONES_Y_TAREAS.md` (§3/§5) como turno
2026-11-26 (rev. 2: re-baseline). El cierre de A3 (gobernador de capacidades) y de A4 (aprobaciones +
parada de emergencia) se registran en el turno 2026-11-27.

---

## Anexo A — Inventario de fuentes leídas (evidencia)

NAIRA-CORE (`AINA\NAIRA-CORE`): `README.md`, `docs/PROJECT_STATUS.md`,
`docs/architecture/{SYSTEM_DESIGN,PLATFORM_SPECIFICATION,COMPONENT_BOUNDARIES,EVENT_SYSTEM,TASK_DISPATCHER,TASK_RECOVERY,SECURITY_MODEL,DATA_MODEL,DATA_FLOW}.md`,
`docs/decisions/ADR-001..005`, `docs/security/{POLICY_DECISION_ENGINE,APPROVALS_EMERGENCY_STOP}.md`,
`docs/integration/{INTEGRATION_STRATEGY,AIPCSYS_REGISTRY_ASSESSMENT}.md`,
`docs/{api,operations,quality,roadmap}/*`, `migrations/versions/0001..0010`, `src/naira_core/policy/{engine,capabilities}.py`,
`src/naira_core/governance/{approvals,emergency_stop}.py`, `src/naira_core/tasks/{service,dispatcher,scheduler,recovery}.py`.
AIPCSYS (`AINA\AIPCSYS_CODEBASE`): `README.md`, `AGENTS.md`,
`DOCS/{ARCHITECTURE,ROADMAP,SECURITY,DETECTION_AND_SAFETY}.md`, `REGISTRY/{agents,skills,workflows,pipelines,connectors}/*.json`,
`CORE/SCHEDULER/ai-suggestion-cron.ps1`, `CORE/REGISTRY/suggestions/SUG-0001..0100.json`,
`FAIPCSYSFRONTENDapp/`, `RESEARCH/samo-tech-skills-tree/{AI_CONSTITUTION.md,AGENTS.md}`.
PARADIGMA-AINA (`AINA\PARADIGMA-AINA`): `DOCS/PARADIGMA_AINA_INVESTIGACION_Y_PLAN.md`,
`AGENTES TRAE/agente-20-paradigma-aina-matriz-conocimiento-ia.md`, `{deployed-paradigma-aina,dev-naira-studio,legacy-12-Education}/**`
(README, `profiles.csv`, `df_lib/packs.csv`, `aina/orchestration/{worker_caps,workflows}.csv`,
`aina/ai/{ai_policies.yml,ai_skills.csv}`, `composer/assemble.py`, `aina/ai/tools/rag_local.py`).
BRAHMA: `ROADMAP.md`, `brahma-os/CHECKLIST-OS.md`, `IDEAS_INNOVADORAS.md`, `TO_BE_CONTINUED.md`,
`brahma-core-0.1-hardware-tuned/.../docs/ARCHITECTURE.md`, `docs/DISTRO_PLAN.md`.

---

## Anexo B — Delta del re-baseline (rev. 1 → rev. 2, 2026-11-26)

Cambios detectados al re-basar contra el estado actual de AINA:

| # | Elemento | Rev. 1 (obsoleto) | Rev. 2 (actual) |
|---|---|---|---|
| 1 | **Ruta de AINA** | `F:\TRABAJO\NEW AI` | `F:\TRABAJO\TO WORK ON QUICK\TRABAJO EXTRA\AINA` |
| 2 | **NAIRA-CORE: gobernador** | no mencionado | **Nuevo**: `policy/capabilities.py` (`CapabilityCatalog`, `CapabilityGovernor`, `AutonomyProfileDefinition.narrows()`, `ConstraintViolation` ×6) |
| 3 | **NAIRA-CORE: scheduler** | "no hay scheduler/worker de fondo" | **CORE-034**: `TaskScheduler` (concurrencia, cuotas, deadlines, métricas), *deshabilitado por defecto* |
| 4 | **NAIRA-CORE: recuperación** | no mencionado | **CORE-033**: `RecoveryEngine` fail-closed para tareas no idempotentes |
| 5 | **NAIRA-CORE: migración 0010** | no mencionado | `awaiting_approval` + `cancel_requested_at`/`cancellation_reason` |
| 6 | **NAIRA-CORE: docs** | lista corta | + `PROJECT_STATUS.md` (2026-11-25), `SECURITY_MODEL`, `TASK_RECOVERY`, `DATA_MODEL`, `DATA_FLOW`, `api/`, `operations/`, `quality/`, `roadmap/` |
| 7 | **NAIRA-CORE: naturaleza** | (implícito) | **Explícito**: FastAPI+SQLAlchemy+Alembic, **NO Django** |
| 8 | **PARADIGMA-AINA** | 1 prototipo + núcleo | **v5 + 4 carpetas de perfil** (3 con contenido + `development-still-pendant` **vacía**), orquestación (`worker_caps` 15 workers, `workflows` `build_profile`/`build_profile_ai`), servicios de ingesta, packs `core/ecom/games/wiki` |
| 9 | **PARADIGMA-AINA: contract_synth** | "`ai.contract_synth` no existe" | **Declarado** en `ai_skills.csv`/`worker_caps.csv` (consumidor por verificar) |
| 10 | **AIPCSYS** | sugerencias 100 | 100 (`CORE/REGISTRY`) + 25 (`REGISTRY`); cron hasta 2026-11-22; frontend `FAIPCSYSFRONTENDapp/` |
| 11 | **Consolidación de AINA** | conjunto disperso en `NEW AI\`, `TEMP_CLONED\`, `WITH DOMAIN\dev.naira-studio.com\` | **Autorizada por el usuario** → todo en `TRABAJO EXTRA\AINA\` (git conservado sano; `NEW AI\` retirado). Ya anotado en `REGISTRO` §3 |
| 12 | **PARADIGMA-AINA: prototipo** | prototipo aislado (7 tests) | En `DOCS\PARADIGMA_AINA_PROTOTIPO\` **v2** + E2–E5 (matriz de conocimiento en dry-run; ~54 tests) — trabajo de la sesión del Agente 20 |
| 13 | **Estado de A3** | "sin ejecutar" | 🟡 module policy creado en WSL (22 tests verdes); **falta** gobernador de capacidades |

**Implicación principal:** el motor de política (A3) sigue siendo válido, pero el NAIRA-CORE actual añade
una capa de **gobernador de capacidades con restricciones duras** que conviene incorporar a A3 antes de
pasar a A4.

# Integración del PARADIGMA AINA en BRAHMA OS — Estudio de integración

> Fecha: 2026-11-26 · Autor: agente de sistemas (TRAE) · Alcance: `F:\TRABAJO\NEW AI` →
> `F:\TRABAJO\TO WORK ON QUICK\TRABAJO EXTRA\BRAHMA`
> Estado: **estudio/diseño**. No se ha ejecutado nada privilegiado, no hay commits ni cambios de sistema.
> Reglas seguidas: dry-run, sin tocar `.venv`/`node_modules`, sin volcar secretos, sin pisar el trabajo de
> la otra sesión sobre PARADIGMA-AINA.
> Coordinación: la otra sesión de chat trabaja el proyecto **PARADIGMA-AINA** (Agente 20,
> `DOCS\PARADIGMA_AINA_INVESTIGACION_Y_PLAN.md`). Este documento estudia **el paradigma AINA como
> conjunto** (los sistemas y agentes que viven en `F:\TRABAJO\NEW AI`) y su encaje en **BRAHMA OS**.

---

## 0. Resumen ejecutivo (TL;DR)

El "PARADIGMA AINA" es, en la práctica, **tres sistemas** con distinto grado de madurez, más una
**carta de gobernanza**:

| Pieza | Ruta | Qué aporta | Madurez real |
|---|---|---|---|
| **NAIRA-CORE** | `NEW AI\NAIRA-CORE` | Plano de control: identidad/RBAC, **motor de política (deny-by-default)**, motor de tareas, dispatcher, **aprobaciones + parada de emergencia**, bus de eventos + outbox, gateway de modelos, hub de integración, auditoría | Código real, tests, migraciones 0001–0010, ADRs 001–005 |
| **AIPCSYS** | `NEW AI\AIPCSYS_CODEBASE` | Plataforma/UX local + **registries** (agentes 67, skills 5.819, workflows 111, pipelines 103, conectores MCP 218), **motor de sugerencias** (cron), instalador no destructivo, **detección de hardware → selección de modelo**, layout de memoria/artefactos | Instalador + catálogos reales; **todo el catálogo en `candidate`/`validation_passed=false`** |
| **PARADIGMA-AINA** | `NEW AI` (no; el proyecto) / `DOCS\PARADIGMA_AINA_*` | **Generación de código desde specs tabulares** (packs CSV → composer → generators) + **RAG local** (TF-IDF + hashing 256-dim) + testgen | Núcleo real (compose/RAG/node_gen); **stubs** (django/static/android); "contract-synth" no existe |
| **AI_CONSTITUTION** | `NEW AI\AIPCSYS_CODEBASE\RESEARCH\samo-tech-skills-tree\AI_CONSTITUTION.md` | Gobernanza: documentación como *gate de cierre*, ciclo `OBSERVE→…→DECIDE`, escalado, decisiones (DECISION-ID), etiquetas de estado | Modelo de governance, no código |

**Conclusión:** BRAHMA ya tiene la *forma* correcta (CORE / DESKTOP / OS + capa IA reversible), pero le
faltan **contratos ejecutables de seguridad y orquestación**. AINA aporta exactamente eso. La
recomendación no es *copiar* esos repos dentro de BRAHMA (NAIRA-CORE es específico de NAIRA; el backend
de AIPCSYS no está versionado), sino **adoptar sus patrones y esquemas** y reimplementarlos como
módulos propios de BRAHMA CORE/SYSTEM, con las fronteras de integración que el propio AINA ya define
(ADR-004): adaptadores + contratos versionados, **sin compartir bases de datos**.

Mayor impacto / menor riesgo, por orden:
1. **Policy engine + risk taxonomy + aprobación firmada + parada de emergencia** (NAIRA-CORE) → convierte la Fase 9 (SYSTEM) de "allowlist read-only" en un sistema real de permisos.
2. **Capability Manifest** (un esquema) para MODES/tools de BRAHMA (lo mejor de AIPCSYS registry + risk classes de NAIRA-CORE).
3. **Task engine + event bus/outbox** (NAIRA-CORE) como cimiento del modo AUTOMATION y de la auditoría.
4. **Layout estándar del home** (`MEMORY/`, `ARTIFACTS/`, `CONFIG/{development,production,secrets}`, `AUDIT/`, `BACKUPS/`) y **first-boot guiado** (patrón AIPCSYS installer + detección de hardware).
5. **RAG local** (PARADIGMA-AINA) sobre la propia documentación/registros de BRAHMA ("un OS que se conoce a sí mismo").
6. **AI_CONSTITUTION** como constitución operativa de BRAHMA (formaliza lo que ya se hace por registro).

---

## 1. Qué es el PARADIGMA AINA (inventario honesto)

### 1.1 NAIRA-CORE — el plano de control (maduro)

Documentado en `NEW AI\NAIRA-CORE\docs\`. Es un **monolito modular local-first** (FastAPI + SQLAlchemy +
Alembic; SQLite local / PostgreSQL híbrido). Principios (README):
local-first, monolito modular antes que microservicios, fronteras explícitas y contratos versionados,
integraciones opcionales que **no impiden el arranque**, mínimo privilegio y ejecución auditable.

Módulos con sustancia real (verificados en código/docs):

- **Identidad y seguridad** — principales humanos y de servicio, credenciales, sesiones, roles,
  permisos, *deny by default*, API keys mostradas una vez y guardadas hasheadas, contexto de principal +
  `correlation_id` por petición.
- **Motor de política** (`docs/security/POLICY_DECISION_ENGINE.md`) — **taxonomía de riesgo**
  (`read_only`, `reversible_write`, `external_communication`, `destructive`, `privileged`), perfiles de
  autonomía (`supervised`, `standard`, `high`) y 3 resultados (`allow`, `require_approval`, `deny`).
  Riesgo o metadato desconocido ⇒ **deny**. En 0.1 es un evaluador de dominio puro (sin BD ni red).
- **Motor de tareas + dispatcher** (`docs/architecture/TASK_DISPATCHER.md`, ADR-003) — máquina de estados
  persistida, leases, reintentos con idempotencia explícita, registro de handlers **explícito** (nada de
  import dinámico), reevaluación de política *inmediatamente antes* de ejecutar. `dispatch_once`.
- **Aprobaciones + parada de emergencia** (`docs/security/APPROVALS_EMERGENCY_STOP.md`) — aprobación
  ligada a capability + recurso exacto + **digest SHA-256 canónico** + versión de política; de un solo
  uso y con caducidad; **prohibida la auto-aprobación**; `core.emergency_stop` persistente que
  **falla en cerrado** si falta o está mal formado.
- **Bus de eventos + outbox transaccional** (`docs/architecture/EVENT_SYSTEM.md`) — sobre tipado con
  versión de esquema, suscriptores explícitos, entrega **at-least-once** (consumidores idempotentes por
  `event_id`), backoff con jitter, *dead-letter*.
- **Gateway de modelos**, **hub de integración** (adaptadores con estado `disabled/disconnected/degraded/ready`),
  **memoria/contexto con procedencia**, **observabilidad** con correlación extremo a extremo.

Gobernanza: `docs/decisions/ADR-001..005` (monolito modular, almacenamiento, eventos, contratos de
integración, autonomía alta acotada por política) y `docs/integration/*` (estrategia + evaluación
read-only de AIPCSYS). El README advierte con honestidad: **no hay scheduler/worker de fondo, ni
handlers de producción externos, ni shell/filesystem/red arbitrarios** por defecto.

### 1.2 AIPCSYS — la plataforma y sus registros (real, pero sin validar)

`NEW AI\AIPCSYS_CODEBASE`. Es una plataforma local (instalador PowerShell + backend FastAPI scaffold +
frontend React/Vite + esquema HQ + adaptador OpenClaw). Lo relevante para BRAHMA:

- **Registries** (`REGISTRY\{agents,skills,workflows,pipelines,connectors}\*.json`): catálogos
  agregados de repos de GitHub. **Todas las entradas son `candidate` y `validation_passed=false`**;
  `operational_count: 0`. Un agente del catálogo trae campos útiles como `domain`, `level`,
  `models`, `languages`, `permission_profile: restricted`, `activation_panel_eligible`, `source`
  (procedencia) y `validation_passed`.
- **Motor de sugerencias** (`CORE\SCHEDULER\ai-suggestion-cron.ps1` + `CORE\REGISTRY\suggestions\SUG-0001..0100.json`):
  bucle que genera "sugerencias" (dominio, tema, keywords, nivel, tier de rack, modelos, idiomas) y
  puede **fusionarlas como agentes candidatos**. Es un **generador de borradores**, no un catálogo validado.
- **Instalador no destructivo** (`Install-AIPCSYS.ps1`): inventario de hardware/software, scaffold sin
  sobrescribir, **loopback por defecto**, backup antes de tocar config ajena, `-SelectAIModel`
  (hardware → modelo), `-Https`/`-ConfigureLan` explícitos, UTF-8 sin BOM.
- **Layout de datos** (`DOCS/ARCHITECTURE.md`): `MEMORY/`, `ARTIFACTS/`, `PROJECTS/`, `WORKFLOWS/`,
  `SKILLS/`, `MODELS/`, `PROVIDERS/`, `CONFIG/{development,production,secrets}`, `LOGS/`, `AUDIT/`,
  `BACKUPS/`, `INBOX/`, `STORAGE/`, `SERVICES/`.
- **Think**: `NAIRA-CORE\docs\integration\AIPCSYS_REGISTRY_ASSESSMENT.md` ya hizo la auditoría correcta
  de AIPCSYS: *"reutilizar como feed de descubrimiento; NO ejecutar contenido importado; no aceptar
  etiquetas de riesgo declaradas como autoritativas; no habilitar conectores MCP automáticamente"*.

### 1.3 PARADIGMA-AINA — el generador por specs (núcleo real, resto declarativo)

Resumen del trabajo ya hecho en `DOCS\PARADIGMA_AINA_INVESTIGACION_Y_PLAN.md` (Agente 20):

- **Real**: `composer\assemble.py` (resuelve perfil → packs → concatena a `spec/`), `aina\ai\tools\rag_local.py`
  (**RAG local**: TF-IDF disperso + vector hashed 256-dim `blake2b`, fusión `0.6·tfidf + 0.4·hash`, sin
  dependencias), `aina\ai\testgen_django.py` y `api_testgen_node.py`, `aina\ingest\scan_code.py`,
  `generators\node_gen.py`, `generators\skeletor_adapter_gen.py`.
- **Stub / solo declarativo**: `django_gen.py`, `static_html_gen.py`, `android_gen.py`,
  `skeletor_django_gen.py`; `ai_prompts.csv`/`ai_skills.csv`/`ai_policies.yml` **sin consumidor**;
  `ai.contract_synth` **no existe**; el `rag_index.json` **no alimenta** la generación.
- **Modelo de datos**: hoy la "celda" es un **escalar CSV**, no un JSON; el concepto "matriz de
  matrices" se **aplana** a un `spec/` plano. Existe un prototipo aislado del modelo objetivo
  (`DOCS\PARADIGMA_AINA_PROTOTIPO\`, 7 tests) con esquema de celda (`term/key/definition/python_code/help/...`).

### 1.4 AI_CONSTITUTION — la gobernanza (modelo, no código)

`AI_CONSTITUTION.md` (repo de investigación `samo-tech-skills-tree`). Formaliza: autoridad
(Humano → CEO/CIO → COO → especialistas), **escalado** de decisiones, **documentación como gate de
cierre** ("code without corresponding operational documentation is an incomplete change"), mapa de
documentación autoritativa, cero *drift*, `DECISION-ID`, **ciclo agentico** `OBSERVE→ASSESS→PLAN→EXECUTE→VERIFY→RECORD→DECIDE`
(techo 12 iteraciones), *preflight* obligatorio, etiquetas de estado
(`IN PROGRESS / BLOCKED / PARTIALLY COMPLETE / IMPLEMENTED—NOT VERIFIED / VERIFIED—DOCUMENTATION PENDING / COMPLETE`).

---

## 2. Por qué beneficia a BRAHMA (sinergias y solapamientos)

BRAHMA ya declaró el destino (ROADMAP §4): **OS → DESKTOP → CORE → (MIND · MEMORY · KNOWLEDGE · REKHA ·
AI ENGINE · MODES)**. Eso es una **pirámide de capas**; AINA aporta los **contratos** que faltan dentro
de esas capas.

| Necesidad de BRAHMA (hoy) | Aportación de AINA | Ganancia |
|---|---|---|
| **Fase 9 SYSTEM** = "allowlist read-only primero", sin modelo formal de permisos | Taxonomía de riesgo + perfiles de autonomía + `allow/require_approval/deny` (NAIRA-CORE) | Permisos **por modo** con semántica defendible y auditable |
| **MODES** declaran "política de permisos" sin esquema | **Capability Manifest**: riesgo, permisos, ámbito de recurso, timeout, efectos, idempotencia | Un solo contrato para todos los modos/tools |
| No hay ejecución asíncrona durable | Task engine + dispatcher + **outbox** (ADR-003) | Modo AUTOMATION y auditoría con estado persistente |
| Aprobación de acciones sensibles "informal" | **Aprobación firmada** (digest + versión de política, single-use) + **parada de emergencia fail-closed** | Kill switch y aprobaciones reales |
| Memoria/artefactos sin layout fijo en el OS | Layout AIPCSYS (`MEMORY/`, `ARTIFACTS/`, `CONFIG/{development,production,secrets}`, `AUDIT/`, `BACKUPS/`) | Home estándar, reproducible y multi-perfil |
| First-boot y auto-ajuste de hardware en "diseño" | Instalador AIPCSYS: detección HW → `-SelectAIModel`, no destructivo, loopback-first | First-boot guiado y CPU-first ya probado |
| No hay catálogo de capabilities para la UI | Registries + `activation_panel_eligible` + procedencia (AIPCSYS) | "Panel de activación" del DESKTOP |
| DEV mode = "diff + aprobación" (idea) | Composer + generators + RAG local (PARADIGMA-AINA) | Generación desde specs + RAG sobre el propio repo |
| Registro/gobernanza por convención | **AI_CONSTITUTION**: doc-gate, DECISION-ID, estados | Gobernanza formal del repo BRAHMA |

**Solapamientos a evitar (no duplicar):**
- BRAHMA CORE (MIND/MEMORY/KNOWLEDGE/REKHA) ≈ NAIRA-CORE (orquestación/memoria). **No fusionar**: adoptar
  sólo los *patrones* de política/ejecución que BRAHMA no tiene; BRAHMA mantiene su fuente de verdad.
- **No copiar NAIRA-CORE dentro de BRAHMA** (es específico de NAIRA y ADR-004 prohíbe el acoplamiento);
  BRAHMA **reimplementa** los módulos que necesite.
- PARADIGMA-AINA y BRAHMA DEV mode: alinear, no duplicar (el generador es una *herramienta* del modo DEV).

**Lo que NO se adopta (y por qué):**
- **Ejecutar** los 5.819 skills / 67 agentes / 218 conectores: todos `candidate`, `validation_passed=false`.
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
L4 Orquestación segura   Fase 9 SYSTEM                            Policy engine + aprobaciones + stop    ADOPTAR patrón
L3 Núcleo                CORE: MIND/MEMORY/KNOWLEDGE/REKHA/AI     Task engine + event bus/outbox         ADOPTAR infr. ligera
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
  tareas persistido + bus de eventos + outbox transaccional**. Se adopta en versión **ligera** (sin
  Redis ni broker; en proceso), tal como NAIRA-CORE decidió en ADR-003.
- **Contrato de evento** a copiar: `event_id`, `type`, `schema_version`, `timestamp UTC`, `producer`,
  `subject`, `correlation_id`, `causation_id`, payload Pydantic validate; desconocido ⇒ **fail-closed**;
  consumidores **idempotentes por `event_id`** (entrega at-least-once).
- **Acción:** tablas `task`, `task_transition`, `task_event`, `outbox` en PostgreSQL (la fuente de verdad
  de BRAHMA); migraciones Alembic; `dispatch_once` como primer paso, worker después y sólo con autorización.

### 3.5 L4 — Orquestación segura (SYSTEM) — **el mayor salto de calidad**

Núcleo del estudio. Se reimplementan en BRAHMA los tres módulos de seguridad de NAIRA-CORE:

1. **Risk taxonomy + Policy evaluator** (de `POLICY_DECISION_ENGINE.md`):
   - Riesgos: `read_only` · `reversible_write` · `external_communication` · `destructive` · `privileged`.
   - Perfiles/“modos de autonomía” de BRAHMA: p.ej. `OBSERVER`≈`supervised`, `ASSISTANT`≈`standard`,
     `OPERATOR`≈`high` (los tres privilegios ya definidos en `ROADMAP.md` §2 y `SYSTEM 9`).
   - Semántica: sólo `read_only` (y `reversible_write` acotado en `high`) puede ejecutar sin aprobación;
     `external_communication`/`destructive`/`privileged` ⇒ **require_approval**; riesgo/scope
     desconocido ⇒ **deny**.
   - El evaluador es **dominio puro** (sin BD/red): recibe contexto confiable (principal, permisos,
     capability, recurso exacto, entorno, perfil, versión de política, estado de stop).
2. **Aprobaciones** (de `APPROVALS_EMERGENCY_STOP.md`): aprobación ligada a capability + recurso exacto +
   **digest SHA-256 canónico del payload** + versión de política; de un solo uso; caduca;
   **auto-aprobación prohibida**; todo auditado; un cambio de payload/recurso/versión **invalida** la aprobación.
3. **Parada de emergencia** (`core.emergency_stop`): persistente; **fail-closed** si falta o está corrupto;
   bloquear nuevas tareas y cancelar lo encolado en la misma transacción; no falsificar "detenido".

**Encaje concreto:** esto convierte la Fase 9 de BRAHMA en un sistema de permisos real, y es la base
para que el modo DEV ("diff + aprobación") y SYSTEM ("read-only primero") tengan garantías, no promesas.

### 3.6 L5 — Interfaz (BRAHMA DESKTOP)

- Adoptar el **patrón de consola web** de NAIRA-CORE (`PLATFORM_SPECIFICATION.md` §3.10): vistas de
  *Overview / Tasks / Approvals / Integrations-Models / Security / Audit / Settings*; **toda acción pasa
  por la API y se re-autoriza en servidor**; el front **no accede a la BD** ni guarda secretos.
- De AIPCSYS: el **panel de activación** de capabilities (`activation_panel_eligible`) y el **frontend
  React+TS** como referencia visual.
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
| L3 | Contrato de eventos | sobre tipado versionado, idempotente, fail-closed | EVENT_SYSTEM.md | Bajo |
| L4 | Política | evaluador puro + contexto confiable + **reevaluar antes de ejecutar** | POLICY_DECISION_ENGINE.md | Alto |
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
| Catálogo no validado | 5.819 skills / 67 agentes / 218 conectores son `candidate` | Sólo `operational` tras validación + binding de permisos |
| "Riesgo declarado" no es riesgo real | AIPCSYS trae `risk_level: low` genérico | Ignorar etiquetas; evaluar con el policy engine de BRAHMA |
| Acoplamiento entre repos | NAIRA-CORE es específico de NAIRA | ADR-004: adaptadores + contratos versionados, **sin compartir BD** |
| Backend AIPCSYS no versionado | El instalador lo scafflea; no es fuente revisable | No reutilizar su backend; sólo catálogos + lógica de instalación |
| Licencias | `free-claude-code` es **AGPL-3.0-only** (ya aislado); `third_party/skeletor` a verificar | Aislar, no redistribuir sin revisión legal/TOS; SBOM |
| Complejidad del policy engine | Mal implementado da falsa seguridad | Evaluador **puro** + tests de seguridad (deny-by-default, stale approval, self-approval, scope escalation, stop) |
| Privilegios OS | systemd/Polkit particionado | Opt-in, dry-run, auditoría, rollback, autorización explícita |
| Recursos (7–8 GB WSL, FX-6300) | 1 modelo local | CPU-first, no simultáneo, timeouts, keep-alive corto |

---

## 7. Roadmap de adopción propuesto (por fases, dry-run primero)

> Cada fase: criterio de aceptación verificable + autorización explícita cuando toque privilegios.

- **A1 — Contratos, sin código (esta fase).** Documento de integración + borrador de **Capability
  Manifest** + mapa capa-a-capa. *Aceptación:* doc revisado; sin cambios de sistema.
- **A2 — Home y first-boot (L0/L1, bajo riesgo).** Layout estándar + `brahma-hwprofile` + units opt-in
  (no instaladas). *Aceptación:* dry-run del scaffold; arranque normal sin BRAHMA intacto.
- **A3 — Policy engine + Capability Manifest (L4).** Evaluador puro + tests de seguridad. *Aceptación:*
  `deny-by-default`, riesgo desconocido ⇒ deny, `require_approval` correcto; suite verde.
- **A4 — Aprobaciones + parada de emergencia (L4).** Digest canónico, single-use, fail-closed.
  *Aceptación:* tests de auto-aprobación, caducidad, replay, stop que bloquea/cancela.
- **A5 — Task engine + eventos/outbox (L3).** Tablas + Alembic + `dispatch_once`. *Aceptación:*
  at-least-once con idempotencia; estados persistidos; auditoría.
- **A6 — DESKTOP: consola + aprobaciones + stop (L5).** *Aceptación:* Playwright smoke local; sin
  acciones privilegiadas desde UI; re-autorización en servidor.
- **A7 — RAG local + modo DEV (L2/L6).** Indexar docs/registros; composer/generators como herramienta
  del modo DEV con diff+aprobación. *Aceptación:* consulta offline devuelve fuentes; generación determinista reproducible.
- **A8 — Gobernanza como código.** Adoptar doc-gate/DECISION-ID/estados de AI_CONSTITUTION en BRAHMA.
  *Aceptación:* plantillas + invariante "nada COMPLETE sin doc".

Dependencias: A3→A4→A5 (política precede a aprobación y a dispatch); A6 tras A4/A5; A7 y A8 paralelizables.

---

## 8. Decisiones abiertas (requieren al usuario)

> **Decisiones confirmadas 2026-11-26 (usuario):** (2) **reimplementar patrones** — adoptar esquemas y
> contratos, **sin copiar** NAIRA-CORE (ADR-004); (5) registro hecho en §3/§5 de
> `REGISTRO_SESIONES_Y_TAREAS.md`; (6) **sincronizado** a la copia canónica WSL `~/BRAHMA/docs/`.
> (4) base PC ya decidida (Ubuntu LTS + KDE Plasma mínimo). Quedan pendientes (1) ubicación definitiva y
> (3) primer módulo, sujetos a la revisión de este estudio por el usuario.

1. **Ubicación canónica de este estudio** (propuesta: `BRAHMA\docs\`; alternativa: `F:\TRABAJO\DOCS\`).
2. **Reimplementar vs adaptar**: confirmar el principio "adoptar patrones, **no copiar** NAIRA-CORE dentro
   de BRAHMA" (ADR-004). Alternativa: importar como dependencia externa versionada.
3. **Alcance del primer módulo a construir**: ¿policy engine (A3) o task engine (A5)?
4. **Base del perfil PC**: Ubuntu/Kubuntu vs Debian (ya pendiente en `DISTRO_PLAN.md` §1) — afecta a
   systemd/Polkit y a las unidades.
5. **Registro**: crear ficha per-app de PARADIGMA-AINA/AINA y entrada en `REGISTRO_SESIONES_Y_TAREAS.md`
   (coordinar con la sesión del Agente 20 para no duplicar).
6. **Sincronización WSL**: aplicar el doc a la copia canónica `~/BRAHMA` además de `F:`.

---

## 9. Ficheros propuestos (sin ejecutar) y registro

Propuesta de artefactos futuros (ninguno creado aún salvo este documento):

| Propuesta | Capa | Notas |
|---|---|---|
| `docs/CAPABILITY_MANIFEST.md` (esquema) | L6 | borrador ya en §3.7 |
| `core/brahma_core/policy/` (evaluador puro + tests) | L4 | fase A3 |
| `core/brahma_core/tasks/` (task engine + outbox) | L3 | fase A5 |
| `docs/decisions/0009-...` (adopción del paradigma AINA) | — | ADR de BRAHMA |
| `brahma-os/base/hwprofile/` (detección HW) | L0 | fase A2 |
| `interface/web` pantallas aprobaciones/stop | L5 | fase A6 |

**Registro:** este estudio se anota en `F:\TRABAJO\REGISTRO_SESIONES_Y_TAREAS.md` (§3/§5) como turno
2026-11-26, sin cambios de código ni sistema.

---

## Anexo A — Inventario de fuentes leídas (evidencia)

NAIRA-CORE: `README.md`, `docs/architecture/{SYSTEM_DESIGN,PLATFORM_SPECIFICATION,COMPONENT_BOUNDARIES,EVENT_SYSTEM,TASK_DISPATCHER}.md`,
`docs/decisions/ADR-003,ADR-004,ADR-005`, `docs/security/{POLICY_DECISION_ENGINE,APPROVALS_EMERGENCY_STOP}.md`,
`docs/integration/{INTEGRATION_STRATEGY,AIPCSYS_REGISTRY_ASSESSMENT}.md`.
AIPCSYS: `README.md`, `AGENTS.md`, `DOCS/{ARCHITECTURE,ROADMAP,SECURITY,DETECTION_AND_SAFETY}.md`,
`REGISTRY/agents/catalog.json`, `CORE/SCHEDULER/ai-suggestion-cron.ps1`, `CORE/REGISTRY/suggestions/SUG-0001.json`,
`RESEARCH/samo-tech-skills-tree/{AI_CONSTITUTION.md,AGENTS.md}`.
PARADIGMA-AINA: `DOCS/PARADIGMA_AINA_INVESTIGACION_Y_PLAN.md`, `AGENTES TRAE/agente-20-paradigma-aina-matriz-conocimiento-ia.md`.
BRAHMA: `ROADMAP.md`, `brahma-os/CHECKLIST-OS.md`, `IDEAS_INNOVADORAS.md`, `TO_BE_CONTINUED.md`,
`brahma-core-0.1-hardware-tuned/.../docs/ARCHITECTURE.md`, `docs/DISTRO_PLAN.md`.

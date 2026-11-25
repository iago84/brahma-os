# BRAHMA OS — Ideas innovadoras (propuestas)

> Derivado de `ROADMAP.md`, `CHECKLIST.md`, `TO_BE_CONTINUED.md`. Cada idea es un candidato; marcar `[ ]`/`[x]` según validación. Ninguna se implementa sin autorización explícita si toca privilegios, ISO, licencias.

## 1. Cerebro único, ocho modos con permisos por modo
- Un solo `BRAHMA CORE` (API) como fuente de verdad; los 8 modos (`TEXT`, `KNOWLEDGE`, `DEV`, `SYSTEM`, `VOICE`, `VISION`, `CREATIVE`, `AUTOMATION`) son **vistas/contratos**, no cerebros paralelos.
- Cada modo declara su **política de permisos** (read-only, allowlist, dry-run, confirmación) y el OS la aplica a nivel de shell/servicio, no solo de UI.

## 2. Epistémica visible en cada respuesta
- Etiquetas obligatorias en la salida del MIND: `hecho / evidencia / inferencia / hipótesis / desconocido / contradicción`, con IDs de fuente (REKHA/KNOWLEDGE) y procedencia.
- La UI resalta contradicciones detectadas por REKHA; el usuario puede saltar a la fuente.

## 3. Memoria con procedencia y contradicciones (REKHA)
- Grafo relacional de entidades/relaciones con evidencia y detección heurística de contradicciones.
- "¿Por qué crees esto?" → traza de evidencia + IDs, reproducible.

## 4. Modo DEV sin ejecución arbitraria
- Asistencia de código con **diff propuesto + aprobación explícita**, sandbox read-only por defecto, auditoría append-only.
- Prohibido shell arbitrario; solo operaciones allowlisted con schema/riesgo/dry-run.

## 5. SYSTEM read-only primero, mutación opt-in
- Catálogo allowlisted (estado servicios, disco, logs BRAHMA, versión) antes de cualquier mutación.
- Confirmación + timeout + auditoría; D-Bus/Polkit solo si justificado.

## 6. CPU-first, 1 modelo, carga perezosa
- `qwen3:1.7b` chat + `bge-m3` embeddings en tareas separadas, `num_ctx=4096`, `num_predict=512`, keep-alive corto.
- Servicios bajo demanda; sin GPU requerida; funciona en 8 GB RAM.

## 7. OS como "AI-native" pero reversible
- La IA es **capa**, no reemplaza el shell estándar: todo desactivable (`BRAHMA_AI_ENABLED=false`), arranque normal sin BRAHMA.
- Rollback documentado por fase; ISO reproducible + SBOM.

## 8. Nueva interfaz unificada (DESKTOP)
- Web local (React+Vite+TS) + shell nativo Qt6/QML futuro, consumiendo CORE por API.
- Estados explícitos: offline/degradado, AI disabled, DB down; sin acciones privilegiadas desde UI.

## 9. Observabilidad local sin datos sensibles
- Métricas/logs estructurados con request/model IDs, latencia, timeouts; sin contenido sensible en prod.
- Consola OBSERVER en UI.

## 10. Primer arranque guiado (first-boot)
- Perfil mínimo de paquetes/servicios bajo demanda, cuenta/seguridad, branding, recovery.
- Explicación epistémica de qué hace BRAHMA y qué no.

## 11. Reproducibilidad y cumplimiento legal
- ISO reproducible, SBOM, revisión AGPL (free-claude-code aislado por defecto).
- Backup/remoto git y snapshot antes de cambios mayores.

## 12. Modos diferidos (VOICE/VISION/CREATIVE)
- Interfaces/feature flags primero; implementación diferida a CPU-capaz, sin bloquear el núcleo.

## 13. Ingesta KNOWLEDGE con procedencia
- TXT/MD primero, PDF/BGE-M3 real diferidos; chunks con evidencia y búsqueda coseno hash.
- Límites de tamaño/rate/timeout.

## 14. Telemetría AI segura
- Modelo usado, latencia, timeouts; sin prompts/respuestas en logs prod salvo opt-in.

## 15. Integración systemd opt-in
- Unit ejemplo no instalada por defecto; instalación solo con autorización explícita + rollback.
- Arranque manual con límites CPU como default.

---

## Candidatos "más novedosos" (a evaluar)
- **Modo AUTOMATION con workflows declarativos** (YAML) ejecutados por CORE con auditoría.
- **Memoria episódica/semántica con olvido controlado** (TTL + importancia).
- **Explicación de cambios del sistema** (qué cambió, por qué, evidencia) antes de aplicar.
- **Modo "offline-first"**: todo funciona sin red; sincronización opcional.
- **Perfil de hardware auto-ajuste**: num_ctx/predict según RAM/CPU detectada.
- **Sandbox de paquetes**: instalar apps en contenedor/flatpak con permisos declarados.
- **Asistente de recuperación** (boot rescue) con IA local para diagnóstico de arranque.
- **Branding/tema "nueva interfaz BRAHMA"** + i18n base.

---
*No implementar sin pasar checklist y autorización.*
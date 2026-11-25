# BRAHMA OS — Plan de distribución Linux AI-native (Fases 9–10 · diseño)

> Revisión: 2026-11-25 · **3 perfiles**: `PC x86_64` · `ARM64 SBC` · `ARM64 móvil (smartphone)`
> Estado: **diseño/plan**. Sin ISO construida ni toolchain privilegiada. Ver ADR `0008`.
> Relacionado: `ROADMAP.md` (§5 H7, §6 Fase 10), `CHECKLIST.md` §G/§H, `docs/PROJECTS_SCOPE.md`, ADR `0006`/`0007`.

## 0. Alcance y reglas (obligatorias)

- **BRAHMA OS** es una **distribución derivada** (no un kernel propio). Consume **BRAHMA CORE**; no duplica cerebros (ADR `0006`).
- **IA como capa reversible**: el sistema **arranca y funciona** con `BRAHMA_AI_ENABLED=false` y sin BRAHMA instalado.
- **Nada privilegiado sin autorización explícita + rollback**: particionado, flasheo, systemd, D-Bus/Polkit, toolchain de ISO y arranque.
- **Un perfil a la vez**, una fase del checklist en orden. **No afirmar** lo no probado en VM/hardware.
- **Reproducible > artesanal**: todo sale de recetas **versionadas** con `dry-run` por defecto.

## 1. Base y stack (común)

| Área | Elección (candidata) |
|---|---|
| Base PC | **Kubuntu / KDE Plasma** (LTS). Lab de desarrollo actual: WSL2 `Ubuntu-24.04-F`. |
| Init/servicios | **systemd**; sesión de usuario + unidades de sistema (opt-in) |
| Comunicación | **D-Bus / Polkit** (mínimo y justificado); NetworkManager; PipeWire (audio) |
| AI runtime | **Ollama** local CPU-first (1 modelo, on-demand, `ctx=4096`) |
| Voz / visión | whisper.cpp (STT) · Piper (TTS) · Tesseract (OCR) |
| UI | **BRAHMA DESKTOP** (React+Vite+TS, web local) + **Qt6/QML** shell nativo (posterior) |

## 2. Perfiles

| Perfil | Base | Kernel / Boot | Shell / UI | Imagen | Estado |
|---|---|---|---|---|---|
| **PC x86_64** | Kubuntu/KDE | kernel distro · GRUB/sd-boot · (U)EFI | KDE Plasma + BRAHMA DESKTOP | ISO híbrida (live+installer) | Diseño |
| **ARM64 SBC** | Debian/Ubuntu arm64 | mainline + DTB · U-Boot | KDE ligero / headless | `.img` (dd a SD/USB) | No iniciado |
| **ARM64 móvil** | postmarketOS / Halium / Ubuntu Touch | kernel del dispositivo · `boot.img` · A/B · `fastboot` | Plasma Mobile / Phosh / Lomiri | imagen de dispositivo + recovery | No iniciado |

Detalle por perfil: `brahma-os/profiles/pc-x86_64.md`, `arm64-sbc.md`, `arm64-mobile.md`.

## 3. Fases

- **Fase 9 — BRAHMA SYSTEM** (seguridad/OS): units systemd, modelo `OBSERVER/ASSISTANT/OPERATOR`, catálogo de operaciones *allowlisted* (read-only primero), `dry-run` + confirmación + auditoría append-only. Prohibido shell arbitrario. (Ver `CHECKLIST.md` §G.)
- **Fase 10 — BRAHMA OS** (distro): perfil mínimo de paquetes, integración CORE+DESKTOP, branding/first-boot, pipeline ISO **reproducible**, recovery/rollback, hardening, SBOM/licencias, pruebas VM + hardware. (Ver `CHECKLIST.md` §H.)

## 4. Pipeline de imagen (propuesto)

| Perfil | Herramienta primaria | Alternativas | Salida |
|---|---|---|---|
| PC x86_64 | **live-build** | Cubic / mkosi / debootstrap+chroot | ISO híbrida (BIOS+UEFI), live + instalador |
| ARM64 SBC | **debos** | mkosi / debootstrap+dd | `.img` con U-Boot + DTB |
| ARM64 móvil | *(evaluar)* postmarketOS / Halium | Ubuntu Touch | imagen de dispositivo + recovery |

Recetas versionadas (dry-run por defecto; build real no ejecutado — requiere autorización):
- `brahma-os/iso/build.sh` — orquestador (`--profile`, `--print-cmd`, `--apply`).
- `brahma-os/iso/live-build/` — receta PC x86_64 (`auto/config` + `config/hooks/`); paquetes desde `base/packages/` (fuente única, sin duplicar).
- `brahma-os/iso/debos/brahma-sbc.yaml` — receta ARM64 SBC (`debootstrap`→`apt`→`overlay`→`setup`→`image-partition`).
- ARM64 móvil: sin receta (evaluar postmarketOS/Halium). Pin de versiones y artefactos hasheados.

## 5. Seguridad y arranque

- **Least privilege**: allowlist, `dry-run` + confirmación, auditoría append-only, sin escalado silencioso, sin secretos en logs.
- **Hardening**: firewall local (nftables/ufw), AppArmor, contraseña de usuario, updates firmados.
- **Arranque verificado**: Secure Boot / dm-verity / A-B — *evaluar por perfil* (no asumir soporte).
- **Recovery/rollback**: partición de recuperación, snapshot pre-cambio, imagen previa.

## 6. Legal / licencias

- **SBOM por build**; solo componentes con licencia compatible.
- **AGPL-3.0** (`external/free-claude-code`): aislado; **no** bundling ni servicio de red sin revisión legal/TOS.

## 7. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Recursos del host (WSL ~7–8 GiB, CPU FX-6300) | modelos pequeños, 1 modelo, on-demand, timeouts |
| Privilegios de sistema | allowlist + dry-run + auditoría; systemd/D-Bus/Polkit solo autorizado |
| Divergencia WSL ↔ F: | código canónico en WSL; sincronizar solo docs/artefactos de forma controlada |
| Complejidad móvil (drivers/bootloader) | empezar por SBC, móvil como investigación acotada |

## 8. Autorizaciones requeridas (pendientes de tu aprobación)

1. Instalar/activar units systemd y servicios (Fase 9).
2. Instalar toolchain de build (live-build/debos/mkosi) y crear entorno de imagen (Fase 10).
3. Construir la primera ISO/imagen y arrancarla en VM (QEMU).
4. Flashear en hardware real (SBC / smartphone) y probar bring-up.

---

## Anexo — Plan inicial (versión previa, preservada)

- Base: desarrollo en Ubuntu 24.04 (WSL2); objetivo Kubuntu/KDE Plasma con interfaz/shell BRAHMA.
- Restricción: 8GB/4vCPU, inferencia CPU; servicios/modelos on-demand.
- Integración de sistema (Fase 9) — **requiere autorización**: units systemd (ejemplo en `infrastructure/systemd/brahma-core.service.example`, no instalado), D-Bus/Polkit solo si es necesario; OBSERVER/ASSISTANT/OPERATOR, ops allowlisted, dry-run+confirmación, auditoría; sin shell arbitrario.
- Imagen (Fase 10) — **requiere autorización + tooling**: ISO instalable (live + installer) con Cubic/debootstrap/live-build (elegir tras validar en host); incluir CORE/MEMORY/KNOWLEDGE/REKHA/AI ENGINE/MIND + interfaz nueva + Ollama opcional + adaptadores externos vetados; revisión de licencias/TOS; AGPL-3.0 → cumplimiento de código fuente correspondiente antes de incluir.
- Bloqueos: cambios de sistema/servicios, entorno de build de ISO y decisiones de modelos/descargas necesitan autorización explícita del usuario.

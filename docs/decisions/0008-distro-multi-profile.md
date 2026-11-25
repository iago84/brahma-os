# ADR 0008 — BRAHMA OS multi-perfil (PC x86_64 · ARM64 SBC · ARM64 móvil)

- **Estado:** propuesto (2026-11-25)
- **Contexto:** la Fase 10 exige definir alcance de la distro. La visión del proyecto pide no solo escritorio sino también ARM (SBC) y una nueva experiencia para **smartphones**.
- **Decisión:**
  1. BRAHMA OS se diseña en **3 perfiles** con recetas independientes y una **base común** (systemd + candidata KDE/Kubuntu).
  2. Toolchain: **live-build** (PC x86_64), **debos** (ARM64 SBC), **evaluación** de postmarketOS/Halium/Ubuntu Touch para móvil.
  3. La **IA es capa reversible**: `BRAHMA_AI_ENABLED=false` por defecto; el sistema arranca y funciona sin BRAHMA.
  4. **Nada privilegiado** (installs / ISO / flasheo / systemd / particionado) sin autorización explícita + rollback.
  5. Canónico = WSL `/home/yago/BRAHMA`; la copia `F:\...\BRAHMA` es **sincronización controlada**.
- **Consecuencias:** `docs/DISTRO_PLAN.md` pasa a multi-perfil; se crea `brahma-os/` (perfiles, listas de paquetes, receta `iso/build.sh` dry-run, checklist). El perfil móvil queda como **investigación acotada** (drivers/bootloader).

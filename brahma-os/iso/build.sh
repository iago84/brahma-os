#!/usr/bin/env bash
# BRAHMA OS — receta de build (orquestador). Dry-run por defecto.
#
# Uso: ./build.sh [--profile pc|arm64-sbc|arm64-mobile] [--print-cmd] [--apply]
#   (sin flags)  dry-run: imprime el plan y las recetas implicadas. No toca el sistema.
#   --print-cmd  imprime los COMANDOS EXACTOS que se ejecutarían. No ejecuta.
#   --apply      build real. Requiere BRAHMA_BUILD_AUTHORIZED=1 + toolchain validada.
#
# Recetas: live-build/ (PC x86_64) y debos/ (ARM64 SBC). Ver README.md y ../../docs/DISTRO_PLAN.md
set -euo pipefail

PROFILE="pc"
APPLY=0
PRINT_CMD=0

usage() { sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)   PROFILE="${2:-}"; shift 2 ;;
    --print-cmd) PRINT_CMD=1; shift ;;
    --apply)     APPLY=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Opción desconocida: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"          # brahma-os/
PKG_DIR="$ROOT_DIR/base/packages"
LB_DIR="$SCRIPT_DIR/live-build"
DEBOS_DIR="$SCRIPT_DIR/debos"

case "$PROFILE" in
  pc)           OUT="brahma-os.hybrid.iso" ;;
  arm64-sbc)    OUT="brahma-os-sbc-arm64.img" ;;
  arm64-mobile) OUT="brahma-os-mobile.img" ;;
  *) echo "Perfil no soportado: $PROFILE" >&2; exit 2 ;;
esac

MODE="DRY-RUN"; [[ $APPLY -eq 1 ]] && MODE="APPLY"

echo "BRAHMA OS build — perfil: $PROFILE — modo: $MODE"
echo "Scaffold: $ROOT_DIR"
echo

show_plan() {
  echo "PLAN (nada se ejecuta sin --apply + autorización):"
  echo "  - paquetes (fuente única) : $PKG_DIR/*.list  (propuesta, VALIDAR)"
  case "$PROFILE" in
    pc)
      cat <<EOF
  - receta                  : $LB_DIR/  (auto/config + auto/build)
  - pasos:
      1. materializar listas : $PKG_DIR/{base,desktop-pc,services}.list
                                -> $LB_DIR/config/package-lists/*.list.chroot
      2. lb config           (flags en auto/config; base Ubuntu LTS + KDE Plasma mínimo)
      3. lb build            (auto/build)
  - artefacto               : $OUT   (ISO híbrida BIOS+UEFI, live)
EOF
      ;;
    arm64-sbc)
      cat <<EOF
  - receta                  : $DEBOS_DIR/brahma-sbc.yaml  (+ scripts/, overlays/)
  - pasos:
      1. comprobar prereqs   : debos + qemu-user-static + binfmt (build cruzado arm64)
      2. debos brahma-sbc.yaml
  - artefacto               : $OUT   (.img; bootloader U-Boot/DTB = por placa, PENDIENTE)
EOF
      ;;
    arm64-mobile)
      cat <<EOF
  - receta                  : (sin receta) evaluar postmarketOS / Halium / Ubuntu Touch
  - nota                    : investigación acotada; ver DISTRO_PLAN.md §4
  - artefacto               : $OUT   (imagen de dispositivo + recovery; PENDIENTE)
EOF
      ;;
  esac
  cat <<EOF

PENDIENTE (requiere autorización — DISTRO_PLAN.md §8):
  - instalar toolchain de build en entorno aislado
  - SBOM + revisión de licencias (incl. AGPL) antes de distribuir
  - arrancar en VM (QEMU) y, después, en hardware real
  - IA como capa reversible: BRAHMA_AI_ENABLED=false por defecto
EOF
}

print_cmds() {
  echo "COMANDOS EXACTOS (NO ejecutados):"
  case "$PROFILE" in
    pc)
      cat <<EOF
  mkdir -p "$LB_DIR/config/package-lists"
  cp "$PKG_DIR/base.list"        "$LB_DIR/config/package-lists/brahma-base.list.chroot"
  cp "$PKG_DIR/desktop-pc.list"  "$LB_DIR/config/package-lists/brahma-desktop.list.chroot"
  cp "$PKG_DIR/services.list"    "$LB_DIR/config/package-lists/brahma-services.list.chroot"
  ( cd "$LB_DIR" && bash auto/config && bash auto/build )
EOF
      ;;
    arm64-sbc)
      cat <<EOF
  ( cd "$DEBOS_DIR" && debos brahma-sbc.yaml )
EOF
      ;;
    arm64-mobile)
      echo "  # sin receta versionada: evaluar postmarketOS/Halium (manual)"
      ;;
  esac
  echo
  echo "  # salida esperada: $OUT"
}

if [[ $PRINT_CMD -eq 1 ]]; then
  print_cmds
  exit 0
fi

show_plan

if [[ $APPLY -eq 1 ]]; then
  echo
  if [[ "${BRAHMA_BUILD_AUTHORIZED:-0}" != "1" ]]; then
    echo "ERROR: build no autorizado. Exporta BRAHMA_BUILD_AUTHORIZED=1 solo tras aprobar la Fase 10 (DISTRO_PLAN.md §8)." >&2
    exit 1
  fi

  case "$PROFILE" in
    pc)
      echo "==> [1/3] Materializando listas de paquetes (fuente única)"
      mkdir -p "$LB_DIR/config/package-lists"
      cp "$PKG_DIR/base.list"        "$LB_DIR/config/package-lists/brahma-base.list.chroot"
      cp "$PKG_DIR/desktop-pc.list"  "$LB_DIR/config/package-lists/brahma-desktop.list.chroot"
      cp "$PKG_DIR/services.list"    "$LB_DIR/config/package-lists/brahma-services.list.chroot"

      echo "==> [2/3] lb config"
      ( cd "$LB_DIR" && bash auto/config )

      echo "==> [3/3] lb build"
      ( cd "$LB_DIR" && bash auto/build )

      echo
      echo "==> Build completado. Artefacto(s):"
      ls -lh "$LB_DIR"/*.iso 2>/dev/null || echo "  (no se encontró ningún .iso)"
      ;;
    *)
      echo "ERROR: perfil '$PROFILE' sin build automatizado (por ahora solo PC x86_64)." >&2
      exit 1
      ;;
  esac
  exit 0
fi

echo
echo "DRY-RUN OK: sin cambios en el sistema."

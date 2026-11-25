#!/bin/sh
# BRAHMA OS — configuración dentro del chroot (perfil ARM64 SBC, debos).
# Branding/estado mínimo; la IA permanece desactivada (capa reversible).
set -e

install -d /etc/brahma

cat > /etc/brahma/brahma-release <<'EOF'
BRAHMA_OS=1
BRAHMA_OS_PROFILE=arm64-sbc
BRAHMA_AI_ENABLED=false
EOF

# Servicios base: red y acceso remoto (opt-in; no activa nada de BRAHMA).
systemctl enable NetworkManager || true
systemctl enable ssh || true

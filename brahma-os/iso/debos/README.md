# BRAHMA OS — receta debos (perfil ARM64 SBC)

Receta **real** (YAML versionado) para construir la imagen de placa/SBC con
[`debos`](https://github.com/go-debos/debos). **No** se ejecuta por defecto: la
orquesta `../build.sh` (dry-run) y requiere autorización (Fase 10).

## Estructura

```
debos/
├── brahma-sbc.yaml            # debootstrap -> apt -> overlay -> setup -> image-partition
├── scripts/setup-sbc.sh       # se ejecuta dentro del chroot
└── overlays/rootfs/           # ficheros copiados tal cual sobre el rootfs
    └── etc/motd
```

## Prerequisitos de build

- `debos` + **build cruzado arm64**: `qemu-user-static` y `binfmt` registrado.
- Base: **Debian arm64** (`--suite bookworm`; `--architecture arm64`).

## Pendiente por placa (no bloquea la receta)

- **Bootloader U-Boot** y **DTB** concretos (`u-boot-tools`/`device-tree-compiler` ya
  incluidos; falta el binario/defconfig de la placa).
- Partición **/boot FAT** y layout de arranque específico del SoC.
- Arranque verificado (dm-verity / A-B) — *evaluar por placa*.

## Build (cuando se autorice)

```bash
../build.sh --profile arm64-sbc            # plan (dry-run)
../build.sh --profile arm64-sbc --print-cmd
export BRAHMA_BUILD_AUTHORIZED=1
../build.sh --profile arm64-sbc --apply
```

Revisar SBOM y licencias antes de distribuir.

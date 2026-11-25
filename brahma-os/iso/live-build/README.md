# BRAHMA OS — receta live-build (perfil PC x86_64)

Receta **real** (config versionada) para construir la ISO del perfil PC con
[`live-build`](https://live-team.pages.debian.net/live-manual/). La orquesta
`../build.sh` (**dry-run** por defecto; `--apply` requiere `BRAHMA_BUILD_AUTHORIZED=1`).
En la práctica se construye en **GitHub Actions** (`.github/workflows/build-iso.yml`),
donde la red es rápida.

## Estructura

```
live-build/
├── auto/
│   ├── config   # flags de `lb config` (base Ubuntu/Kubuntu LTS, ISO híbrida)
│   ├── build    # `lb build`
│   └── clean    # `lb clean --purge`
└── config/
    ├── hooks/live/0100-brahma-branding.hook.chroot   # /etc/brahma/* y /etc/motd
    └── package-lists/    # GENERADO en build desde ../../base/packages/*.list
```

## Fuente única de paquetes

Las listas **no** se duplican: `build.sh` copia (paso 1) desde `../../base/packages/`:

| Origen | Destino en `config/package-lists/` |
|---|---|
| `base.list` | `brahma-base.list.chroot` |
| `desktop-pc.list` | `brahma-desktop.list.chroot` |
| `services.list` | `brahma-services.list.chroot` |

## Base

- **Ubuntu LTS** (`--mode ubuntu --distribution noble`) con **KDE Plasma mínimo**
  (`desktop-pc.list` → `kde-plasma-desktop`): ISO manejable (~1,5–2 GB). Requiere host
  Ubuntu (CI: runner `ubuntu-24.04`; lab: WSL2 `Ubuntu-24.04-F`).
- **Alternativa Debian**: sustituir por `--distribution bookworm`, quitar `--mode ubuntu`
  y ajustar mirrors/`--archive-areas` (`main contrib non-free-firmware`). Decisión de base
  pendiente de validación (`DISTRO_PLAN.md` §1).

## Build (cuando se autorice)

```bash
# 1) ver el plan y los comandos exactos (sin ejecutar nada)
../build.sh --profile pc
../build.sh --profile pc --print-cmd

# 2) build real (autorizado; en CI lo hace el workflow)
export BRAHMA_BUILD_AUTHORIZED=1
../build.sh --profile pc --apply
```

En **CI** (`ubuntu-24.04`) el build necesita root para `debootstrap`, así que el workflow
invoca `sudo -E bash brahma-os/iso/build.sh --profile pc --apply`. Salida esperada:
`brahma-os.hybrid.iso` (por `--image-name brahma-os`).

Requisitos del host: paquete `live-build`, ~20 GB libres y root (mediante el propio
live-build). Revisar SBOM y licencias antes de distribuir.

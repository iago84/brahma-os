# BRAHMA OS — Pipeline de imagen (recetas reales, dry-run)

Ver diseño: [`../../docs/DISTRO_PLAN.md`](../../docs/DISTRO_PLAN.md) §4.

| Perfil | Receta versionada | Salida |
|---|---|---|
| PC x86_64 | [`live-build/`](live-build/) (`auto/config` + `config/hooks/`) | ISO híbrida (BIOS+UEFI), live |
| ARM64 SBC | [`debos/brahma-sbc.yaml`](debos/brahma-sbc.yaml) (+ `scripts/`, `overlays/`) | `.img` (U-Boot/DTB por placa, pendiente) |
| ARM64 móvil | *(evaluar)* postmarketOS / Halium / Ubuntu Touch | imagen de dispositivo (pendiente) |

## Orquestador

`build.sh` es el punto de entrada. **Dry-run por defecto** (no root, sin cambios).

```bash
./build.sh --profile pc                 # plan (dry-run)
./build.sh --profile arm64-sbc          # plan (dry-run)
./build.sh --profile pc --print-cmd     # COMANDOS exactos, sin ejecutar
./build.sh --profile pc --apply         # build real: requiere BRAHMA_BUILD_AUTHORIZED=1
./build.sh --help
```

## Estado

- Recetas `live-build/` y `debos/` **escritas y versionadas**; el orquestador está listo.
- **Build en CI**: `.github/workflows/build-iso.yml` (GitHub Actions, runner `ubuntu-24.04`)
  construye la ISO del perfil PC y publica el artefacto troceado (<2 GiB) o en un Release.
  Se lanza manualmente (`workflow_dispatch`) o al empujar un tag `v*`.
- `--apply` solo se ejecuta si se exporta `BRAHMA_BUILD_AUTHORIZED=1`.

## Principios

- Recetas **versionadas** y **reproducibles** (pin de versiones, artefactos hasheados).
- Perfil de paquetes desde `../base/packages/*.list` (**fuente única**; `live-build` copia, no duplica).
- `BRAHMA_AI_ENABLED=false` por defecto; el sistema arranca sin BRAHMA.
- **SBOM** + revisión de licencias (incl. AGPL) antes de distribuir.

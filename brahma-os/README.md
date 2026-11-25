# BRAHMA OS — scaffold de la distribución (Fase 10)

Scaffold de la **distribución Linux AI-native** de BRAHMA. **No** contiene aún código de build
ejecutable ni artefactos; es la estructura de diseño + recetas en `dry-run`.

Diseño completo: [`../docs/DISTRO_PLAN.md`](../docs/DISTRO_PLAN.md). Decisión: ADR `0008`.
Reglas del proyecto: `../ROADMAP.md` §1 y `../docs/PROJECTS_SCOPE.md` (no duplicar cerebros; CORE es la fuente de verdad).

## Estructura

```
brahma-os/
├── README.md              # este archivo
├── CHECKLIST-OS.md        # checklist por perfil (VM + hardware)
├── base/
│   └── packages/          # perfiles de paquetes (listas, propuesta a validar)
│       ├── base.list
│       ├── desktop-pc.list
│       ├── desktop-mobile.list
│       └── services.list
├── profiles/
│   ├── pc-x86_64.md       # escritorio (Kubuntu/KDE)
│   ├── arm64-sbc.md       # placas / SBC (Debian arm64 + U-Boot)
│   └── arm64-mobile.md    # smartphone (postmarketOS/Halium/UT)
└── iso/
    ├── README.md          # pipeline (recetas reales, dry-run)
    ├── build.sh           # orquestador, dry-run por defecto
    ├── live-build/        # receta PC x86_64 (auto/config + hooks + package-lists)
    └── debos/             # receta ARM64 SBC (brahma-sbc.yaml + scripts + overlays)
```

## Reglas

- **IA reversible**: el sistema arranca y funciona con `BRAHMA_AI_ENABLED=false` y sin BRAHMA.
- **Nada privilegiado** sin autorización explícita + rollback (installs, ISO, flasheo, systemd, particionado).
- **Reproducible**: recetas versionadas, `dry-run` por defecto; sin pasos manuales ocultos.
- **No afirmar** lo no probado en VM/hardware.

## Estado

| Elemento | Estado |
|---|---|
| `docs/DISTRO_PLAN.md` multi-perfil | Hecho (diseño) |
| Estructura `brahma-os/` | Hecho (scaffold) |
| Perfiles de paquetes | Propuesta (validar) |
| Receta PC (`iso/live-build/`) | Escrita (config + hook; build real no ejecutado) |
| Receta SBC (`iso/debos/`) | Escrita (YAML + scripts; build real no ejecutado) |
| `iso/build.sh` | Dry-run funcional (`--apply` requiere autorización) |
| ISO/imagen real | **No construida** (requiere autorización + toolchain) |

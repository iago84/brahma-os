# Perfil — ARM64 SBC (placas / dispositivos)

| Campo | Valor |
|---|---|
| Base | Debian/Ubuntu **arm64** |
| Kernel / Boot | kernel mainline + **DTB** del dispositivo · **U-Boot** |
| Shell / UI | KDE ligero o headless |
| Imagen | `.img` (escritura a SD/USB con `dd`) |
| Toolchain | **debos** (alt.: mkosi / debootstrap+dd) |
| Salida | `brahma-os-sbc-arm64.img` |
| Estado | No iniciado |

## Pasos previstos

1. Elegir **placa objetivo** (modelo + SoC + bootloader) y confirmar soporte mainline.
2. Receta `debos` (YAML) reproducible con pin de versiones.
3. Kernel + DTB correctos para el SoC; U-Boot configurado.
4. Perfil de paquetes ligero (`base.list` + subconjunto desktop o headless).
5. Bring-up: red, almacenamiento, consola serie; luego CORE si procede.
6. SBOM/licencias → pruebas en hardware real.

## Requisitos / bloqueos

- Autorización para instalar toolchain y para escribir imagen en medio físico.
- Dependencia fuerte del **soporte de hardware** del SoC elegido.

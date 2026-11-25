# Perfil — ARM64 móvil (smartphone)

> Investigación acotada. El bring-up móvil depende del **soporte del dispositivo** y conlleva riesgo de brick.

| Campo | Valor |
|---|---|
| Base | **postmarketOS** / Halium / Ubuntu Touch (Lomiri) — a evaluar |
| Kernel / Boot | kernel del dispositivo · `boot.img` · A/B · `fastboot` · recovery |
| Shell / UI | **Plasma Mobile** / Phosh / Lomiri |
| Imagen | imagen de dispositivo + recovery |
| Toolchain | a evaluar por base elegida |
| Salida | `brahma-os-mobile.img` (nombre tentativo) |
| Estado | No iniciado |

## Pasos previstos

1. Elegir **dispositivo objetivo** y evaluar nivel de soporte (mainline vs downstream).
2. Elegir base (postmarketOS/Halium/UT) con criterios de aceptación explícitos.
3. Documentar particiones, `boot.img`, A/B y flujo `fastboot`/recovery.
4. Bring-up mínimo: arranque → pantalla táctil → red → audio.
5. **Rollback** a imagen previa documentado antes de cualquier flasheo.
6. Evaluar integración de CORE/DESKTOP solo tras bring-up estable.

## Requisitos / bloqueos

- Dispositivo de pruebas (no el de uso diario) y autorización explícita para flashear.
- Riesgo alto de bloqueo del dispositivo; sin garantías hasta validar en hardware.

> **Honestidad de estado:** no se afirma compatibilidad con ningún smartphone concreto hasta probarlo de verdad.

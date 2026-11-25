# BRAHMA OS — Checklist por perfil (Fase 10)

> Marcar `[x]` solo con evidencia (log/comando/captura). Nada privilegiado sin autorización explícita.
> Diseño: `../docs/DISTRO_PLAN.md`. Estructura: `README.md`.

## 0. Común (todos los perfiles)

- [ ] Perfil de paquetes mínimo definido y validado (`base/packages/*.list`)
- [ ] `BRAHMA_AI_ENABLED=false` por defecto; el sistema arranca y funciona **sin** BRAHMA
- [ ] CORE + DESKTOP integrados como unidades (user/system) con puertos sin colisión
- [ ] First-boot documentado + recuperación/rollback definidos
- [ ] Hardening: firewall local, least privilege, contraseña de usuario, updates firmados
- [ ] SBOM generado y licencias revisadas (incl. **AGPL**)
- [ ] Sin secretos en la imagen, logs ni docs
- [ ] Receta de build reproducible (dry-run OK) + artefacto hasheado
- [ ] Arranque verificado en **VM** (QEMU) con evidencia

## 1. PC x86_64 (escritorio)

- [ ] Base Kubuntu/KDE validada en VM
- [ ] GRUB/sd-boot + (U)EFI: arranque BIOS y UEFI
- [ ] Instalador (live + installer) probado
- [ ] GPU/audio/red verificados en VM y, si aplica, hardware real
- [ ] Flashear/probar en hardware real

## 2. ARM64 SBC

- [ ] Placa objetivo elegida (modelo + SoC + bootloader)
- [ ] Kernel mainline + **DTB** del dispositivo arrancan
- [ ] U-Boot configurado; imagen `.img` escrita a SD/USB
- [ ] Red/almacenamiento/consola serie verificados

## 3. ARM64 móvil (smartphone)

- [ ] Dispositivo objetivo y nivel de soporte (mainline vs downstream) evaluados
- [ ] Base elegida (postmarketOS / Halium / Ubuntu Touch) y criterios de aceptación
- [ ] Particiones + `boot.img` + A/B + `fastboot`/recovery documentados
- [ ] Bring-up mínimo: arranque, pantalla táctil, red, audio
- [ ] Rollback a imagen previa documentado (riesgo de brick)

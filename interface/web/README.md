# BRAHMA INTERFACE (web) — scaffold (Fase 8)

- Stack (ADR 0007): React + Vite + TypeScript, API-first contra BRAHMA CORE.
- Estado: scaffold; requiere Node/npm para inicializar Vite. No se ejecutó create-vite automáticamente.
- Consume /api/v1/*; sin ejecución privilegiada.

## Init sugerida (Node 20+)
cd /home/yago/BRAHMA/interface/web && npm create vite@latest . -- --template react-ts && npm install

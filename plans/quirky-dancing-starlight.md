# Add Vite ESLint Plugin for Lint-on-Save

## Context
The project has a working ESLint config (`eslint.config.mjs`) but no dev-server integration — lint errors only surface when running `npm run lint` manually. Adding a Vite ESLint plugin will show lint errors in the terminal/overlay during development on every file save.

## Steps

1. **Install `vite-plugin-eslint2`** (the maintained fork for Vite 5+/ESLint 9+)
   ```bash
   cd client && bun add -d vite-plugin-eslint2
   ```

2. **Update `client/vite.config.ts`** — import and add the plugin:
   - Import `eslint` from `vite-plugin-eslint2`
   - Add `eslint()` to the plugins array

## Files Modified
- `client/package.json` (new dev dependency)
- `client/vite.config.ts` (add plugin)

## Verification
- Run `npm run dev` from `client/` and confirm ESLint errors appear in terminal on save
- Introduce a deliberate lint error (e.g., unused import) and verify it's reported
- Run `npm run build` to confirm no build regressions

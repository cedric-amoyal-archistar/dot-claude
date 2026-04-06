# Plan: Add UEFA Europa League competition

## Context

The Europa League uses the exact same UEFA API as the Champions League — same proxy, same response format, same endpoints. The only difference is `competitionId=14` (vs `1` for UCL), a different external URL path, and a different season range (Europa League started later than UCL).

## Approach

Refactor the existing UEFA provider into a **factory function** that accepts config, then create both UCL and UEL providers from it. This avoids code duplication.

### 1. Refactor `src/providers/uefa/index.ts`

Turn the hardcoded `uefaProvider` into a `createUefaProvider(config)` factory:

```typescript
interface UefaProviderConfig {
  id: string
  name: string
  competitionId: string
  externalUrlPath: string   // e.g. 'uefachampionsleague' or 'uefaeuropaleague'
  firstSeason: number       // e.g. 1956 for UCL, 1972 for UEL
}
```

Export two providers:
- `uefaUclProvider` — Champions League (competitionId `'1'`, firstSeason ~1956)
- `uefaUelProvider` — Europa League (competitionId `'14'`, firstSeason ~1972)

Everything else (`fetchJson`, `computeCurrentSeason`, `seasonLabel`, proxy path `/uefa-api`) is shared.

### 2. Update `src/providers/registry.ts`

Import and register both providers.

### 3. No other files change

- Same proxy (`/uefa-api`) — both competitions use the same UEFA API
- No `vite.config.ts` changes needed
- No component/hook/page changes
- The competition selector in `DefaultLayout.tsx` already shows all registered providers when there are >1

## Files to modify

- `src/providers/uefa/index.ts` — refactor to factory, export both providers
- `src/providers/registry.ts` — register the Europa League provider

## Verification

1. `npm run type-check` — no errors
2. `npm run test` — all tests pass
3. `npm run dev` → `/` shows both Champions League and Europa League cards
4. Click Europa League → match list loads for UEL
5. Click a match → detail page with lineups works
6. Season selector works for both competitions

# Plan: UEFA Champions League Match List & Lineups App

## Context
The app currently has a placeholder "Create Team" landing page. The user wants to replace it with a Champions League match browser that shows fixtures and, on click, displays team lineups in a pitch formation view. The app will be used primarily on mobile.

## API Details (verified via curl)
- **Match list**: `GET https://match.uefa.com/v5/matches?competitionId=1&seasonYear=2026&limit=50&offset=0&order=DESC`
- **Lineups**: `GET https://match.uefa.com/v5/matches/{matchId}/lineups`
- The lineups API provides `fieldCoordinate: { x, y }` (0-1000 grid) for each player — we'll use these directly for pitch positioning
- Player `countryCode` uses 3-letter codes (e.g., "ESP", "ENG")
- CORS blocks browser requests — need Vite proxy

## Implementation Steps

### Step 1: Vite proxy setup
**File**: `vite.config.ts`
- Add `server.proxy` entry: `/uefa-api` -> `https://match.uefa.com` (rewrite path, strip prefix)

### Step 2: TypeScript types
**File**: `src/types/match.ts` (new)
- `Match` — id, homeTeam, awayTeam, kickOffTime, score, status, round, stadium, competition
- `TeamInMatch` — internationalName, id, logoUrl, mediumLogoUrl, countryCode, teamCode
- `MatchLineups` — homeTeam, awayTeam, lineupStatus, matchId
- `TeamLineup` — team, coaches, field (starting XI), bench, shirtColor, kitImageUrl
- `LineupPlayer` — jerseyNumber, fieldCoordinate {x, y}, player (id, internationalName, clubShirtName, countryCode, fieldPosition, imageUrl), type
- `Coach` — person.internationalName, imageUrl

### Step 3: API composable
**File**: `src/composables/useUefaApi.ts` (new)
- Create axios instance with `baseURL: '/uefa-api'`
- `getMatches(seasonYear, offset, limit)` -> `Match[]`
- `getMatchLineups(matchId)` -> `MatchLineups`

### Step 4: Country flag utility
**File**: `src/composables/useCountryFlag.ts` (new)
- Map FIFA 3-letter codes to ISO 2-letter codes for flag CDN/emoji
- `getFlagUrl(countryCode)` -> returns `https://flagcdn.com/w40/{iso2}.png`
- `getFlagEmoji(countryCode)` -> returns emoji flag character

### Step 5: Match list view (replaces HomeView)
**File**: `src/views/HomeView.vue` (rewrite)
- Fetch matches from UEFA API on mount (both seasonYear=2025 and 2026)
- Group by date, display as cards
- Each card: team logos + names, score or kickoff time, round name
- Loading and error states
- Mobile-first responsive layout

### Step 6: Match card component
**File**: `src/components/match/MatchCard.vue` (new)
- Team logos, names, score/time
- RouterLink to `/match/:id`
- Compact mobile-friendly design

### Step 7: Match detail view with lineups
**File**: `src/views/MatchDetailView.vue` (new)
- Fetch lineups on mount using route param `id`
- Display pitch with both teams
- Flag/jersey toggle switch
- Back button to match list
- Loading/error states

### Step 8: Pitch & lineup components
**Files** (all new):
- `src/components/lineup/PitchView.vue` — Full pitch container (dark background), renders both team halves
- `src/components/lineup/TeamHalf.vue` — Positions players using `fieldCoordinate` x/y on a relative grid. Home team top, away team bottom
- `src/components/lineup/PlayerNode.vue` — Circle with jersey number (or flag when toggled) + player name below
- `src/components/lineup/BenchList.vue` — Horizontal scrollable list of bench players

### Step 9: Routing update
**File**: `src/router/index.ts`
- Keep `/` -> `HomeView` (now the match list)
- Add `/match/:id` -> `MatchDetailView`

### Step 10: Layout update
**File**: `src/layouts/DefaultLayout.vue`
- Change icon from Users to Trophy
- Update text to "UCL Lineups" or similar

## Key Design Decisions
- **Use `fieldCoordinate` directly** instead of parsing formation strings — the API provides exact x,y positions (0-1000 grid), which is more accurate and simpler
- **No Pinia store** initially — use composable + local component state. Simpler for this use case, can add store later if needed
- **Vite proxy** for CORS — simplest solution for dev. Production deployment would need its own proxy (document but don't implement)
- **Flag CDN** (flagcdn.com) for country flags — lightweight, no bundled assets needed
- **Mobile-first** — max-w-sm pitch, scrollable match list, touch-friendly card sizes

## Verification
1. `npm run dev` — check match list loads at `/`
2. Click a match with status FINISHED — verify lineups load on `/match/:id`
3. Toggle flag switch — verify flags appear instead of jersey numbers
4. Test on mobile viewport (375px width) — verify responsive layout
5. `npm run build` — verify no TypeScript errors (strict mode)

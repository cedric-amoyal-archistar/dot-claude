# Plan: Redesign EnvironmentSwitcher to match CitySelect sub-env dropdown

## Context
The current EnvironmentSwitcher popover shows plain uppercase text buttons (e.g. "PROD", "UAT"). We want it to match the CitySelect sub-env dropdown from the property frontend: each environment shown as a card-like row with an icon, bold label, and description text. The active environment gets a highlighted border.

The data shape is changing from `string[]` to an array of objects with `{ type, country_code, subEnv, label, short_name, icon, url, description }`.

## Files to modify
- `client/src/components/EnvironmentSwitcher.vue` — main changes

## Implementation

### 1. Update data handling
- Replace `subEnvironmentsWithProd` computed (which prepends `'prod'` string) with `subEnvironments` that reads `cityAppSettings.sub_environments` directly as objects
- The `sub_environments` array already includes production as one of the entries (per the sample data), so no need to prepend
- Keep `hasMultipleEnvs` check but adapted for the object array
- Determine active sub-env by matching `cityAppSettings.active_sub_env` against `subEnv` field of each object (with `'production'` as fallback)

### 2. Update `selectSubEnv` function
- Accept the full sub-env object instead of a string
- Navigate using `subEnv.url` — use `window.location.href` to go to `https://{url}/` (matching the pattern in CitySelect: `window.open('https://' + subEnv.url + '...', '_self')`)

### 3. Redesign PopoverContent to match screenshot
- Header: `<p>Change Environment</p>` (text-sm font-medium, matching screenshot)
- List items: each is a clickable div/button with:
  - Left: Lucide icon (mapped from `subEnv.icon` string)
  - Right: bold label + description paragraph below
  - Active item: `border border-primary rounded-lg` highlight
  - Inactive items: `border border-transparent` with `hover:bg-accent` on hover
- Width: `w-80` (~320px, matching the ~350px from CitySelect)

### 4. Icon mapping
Create a simple icon map to convert icon strings to Lucide components:
- `"check-circle"` -> `CircleCheck`
- `"plus-circle"` -> `CirclePlus`  
- `"headphones"` -> `Headphones`
- Fallback: `Circle`

Use a `component :is="..."` pattern to render dynamically.

### 5. Trigger button
- Keep existing trigger button style (outline, rounded-full, Layers icon, chevron)
- Display `subEnv.label` instead of raw `active_sub_env` string

## Verification
- Run `npm run dev` and navigate to a city with multiple sub_environments
- Confirm popover shows "Change Environment" header with icon+label+description rows
- Confirm active environment has border highlight
- Confirm clicking an environment navigates to its URL
- Run `npm run type-check` and `npm run lint`

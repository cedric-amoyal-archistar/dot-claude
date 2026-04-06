# Plan: Add Navbar + Fix Region URL Format

## Context

The `/:region` (ProjectsView) route needs a navbar matching the React prototype's `Header.tsx`. The `/` (HomeView) route should have no navbar. Additionally, the region URL must use the format `countryCode/cityName` (e.g., `ca/burlington` or `ca/-` if no city).

## 1. Install shadcn-vue components

Install `popover` and `dropdown-menu` for the AppSwitcher and user menu respectively, and `separator` for dividers.

```bash
npx shadcn-vue@latest add popover dropdown-menu separator --yes
```

## 2. Copy missing assets

Copy from React app `public/` to Vue `client/public/`:
- `archistar-logo-dark.svg` — main logo
- `images/app_home.svg` — home icon for AppSwitcher
- `images/app_precheck.svg` — precheck icon for AppSwitcher
- `images/app_explore.svg` — explore icon for AppSwitcher

## 3. Update router — `client/src/router/index.ts`

Change the `/:region` route to `/:country/:city` to support the `countryCode/cityName` format:

```ts
routes: [
  { path: '/', name: 'home', component: HomeView },
  { path: '/:country/:city', name: 'projects', component: ProjectsView },
]
```

## 4. Update HomeView — `client/src/views/HomeView.vue`

When a municipality is selected, navigate using the municipality's `country` field (lowercased) and `SUGGESTED_NAMES` (lowercased) for the city slug:

```ts
function confirmMunicipality(m: Municipality) {
  appStore.setMunicipality(m)
  appStore.setLocationSource('manual')
  appStore.setResolvedAt(new Date().toISOString())
  const country = m.country.toLowerCase()
  const city = (SUGGESTED_NAMES[m.id] ?? m.name).toLowerCase()
  router.push({ name: 'projects', params: { country, city } })
}
```

## 5. Create AppSwitcher — `client/src/components/AppSwitcher.vue`

Convert React `AppSwitcher.tsx` → Vue using shadcn-vue `Popover`.

- **Trigger**: slot (waffle grid icon passed from navbar)
- **Content**: Popover panel with:
  - "Home" link → navigates to `/`
  - Separator
  - Product items (PRODUCTS array) with icons from `/images/app_*.svg`
  - Lock icon on AI PreCheck if municipality is disabled
  - Each item navigates to the correct route and closes the popover

## 6. Create LocationSwitcher — `client/src/components/LocationSwitcher.vue`

Convert React `LocationSwitcher.tsx` → Vue.

- **Props**: none needed (reads from appStore)
- **Emits**: `switchCity`
- Displays current municipality name with MapPin + ChevronDown icons (from lucide-vue-next)
- Pill-shaped button with border

## 7. Create AppNavbar — `client/src/components/AppNavbar.vue`

Convert React `Header.tsx` → Vue. Simplified per requirements:

- **Left**: AppSwitcher (waffle icon) + Archistar logo (links to `/`)
- **Center**: LocationSwitcher (opens CityPickerDialog)
- **Right**: User avatar with shadcn `DropdownMenu` containing only **Sign out** (calls `APIHelper.handleLogout()` from `@archistarai/auth-frontend`)
- Fixed header, `h-14`, white background, bottom border
- No white-label theming for now (simplify — can be added later)

## 8. Update App.vue — wrap `/:country/:city` in layout

Use Vue Router's `<RouterView>` with a conditional layout approach. Since only `/:country/:city` needs the navbar:

```vue
<template>
  <AppNavbar v-if="showNavbar" />
  <main :class="{ 'pt-14': showNavbar }">
    <RouterView />
  </main>
</template>
```

Where `showNavbar` is a computed that checks `route.name === 'projects'`.

## 9. Update ProjectsView — `client/src/views/ProjectsView.vue`

- Remove the `min-h-screen` centering (navbar is now above, layout handles padding)
- Remove the location pill + "Switch city" button (now in navbar's LocationSwitcher)
- Remove `<Toaster>` from here — move to `App.vue` so it's available globally
- Keep: greeting, product cards, terms footer

## 10. Update CityPickerDialog

When a city is selected inside the dialog (on the projects page), also update the URL to reflect the new city:

```ts
function handleSelect(m: Municipality) {
  // existing logic...
  // also update route params
  router.replace({
    name: 'projects',
    params: {
      country: m.country.toLowerCase(),
      city: (SUGGESTED_NAMES[m.id] ?? m.name).toLowerCase(),
    },
  })
}
```

This needs to only happen when we're on the projects route. The dialog is also used from the navbar, so we should check the current route before pushing.

## Files Summary

| File | Action |
|---|---|
| `client/src/router/index.ts` | Modify — `/:country/:city` route |
| `client/src/App.vue` | Modify — add conditional navbar + Toaster |
| `client/src/views/HomeView.vue` | Modify — region URL format |
| `client/src/views/ProjectsView.vue` | Modify — remove location pill, adjust layout |
| `client/src/components/AppNavbar.vue` | **Create** — main navbar |
| `client/src/components/AppSwitcher.vue` | **Create** — product popover menu |
| `client/src/components/LocationSwitcher.vue` | **Create** — city pill button |
| `client/src/components/CityPickerDialog.vue` | Modify — update URL on city switch |
| `client/public/archistar-logo-dark.svg` | **Copy** from React app |
| `client/public/images/app_*.svg` | **Copy** from React app |

## Implementation Order

1. Install shadcn `popover`, `dropdown-menu`, `separator`
2. Copy image/logo assets
3. Update router (`/:country/:city`)
4. Update HomeView (region URL format on municipality select)
5. Create LocationSwitcher
6. Create AppSwitcher
7. Create AppNavbar
8. Update App.vue (conditional navbar + global Toaster)
9. Update ProjectsView (remove location pill, adjust layout)
10. Update CityPickerDialog (update URL on city switch)
11. Lint + type-check

## Verification

1. `npm run dev` — open `http://localhost:5173`
2. `/` shows welcome page with NO navbar
3. Select a city → navigates to e.g. `/ca/burlington`
4. `/:country/:city` shows navbar with AppSwitcher, LocationSwitcher, user menu
5. AppSwitcher popover shows Home + 3 products
6. LocationSwitcher shows current city, clicking opens CityPickerDialog
7. Switching city in dialog updates the URL
8. Sign out button in user menu works
9. `npm run lint` + `npm run type-check` pass

# Lineups — Vue 3 Frontend App

## Context
Create a new sports team lineups management app from scratch in an empty directory. The app will allow users to manage player lineups for sports teams/games.

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | **Vue 3** (Composition API + `<script setup>`) | User requirement |
| Language | **TypeScript** | User requirement |
| Build tool | **Vite** | Standard for Vue 3, fast HMR |
| Styling | **Tailwind CSS v4** | User requirement |
| UI Components | **shadcn-vue** | User requirement — headless, customizable components |
| Icons | **Lucide Vue Next** | User requirement |
| Routing | **Vue Router 4** | Multi-page navigation |
| State | **Pinia** | Centralized state management |
| HTTP | **Axios** | API communication |
| Utilities | **VueUse** | Handy composables (useLocalStorage, useDark, etc.) |
| Linting | **ESLint + Prettier** | Code quality |

## Scaffolding Steps

### 1. Create Vite project
```bash
npm create vite@latest . -- --template vue-ts
```

### 2. Install core dependencies
```bash
npm install vue-router@4 pinia axios @vueuse/core
npm install -D tailwindcss @tailwindcss/vite
```

### 3. Set up Tailwind CSS v4
- Add the Tailwind Vite plugin to `vite.config.ts`
- Create `src/assets/main.css` with `@import "tailwindcss"`

### 4. Set up shadcn-vue
```bash
npx shadcn-vue@latest init
```
This will configure path aliases, CSS variables, and the `components.json` file. Then add a few starter components:
```bash
npx shadcn-vue@latest add button card input table
```

### 5. Install Lucide icons
```bash
npm install lucide-vue-next
```

### 6. Set up project structure
```
src/
├── assets/
│   └── main.css            # Tailwind + shadcn CSS variables
├── components/
│   └── ui/                 # shadcn-vue components (auto-generated)
├── composables/            # Reusable composables
├── layouts/
│   └── DefaultLayout.vue   # App shell with nav
├── lib/
│   └── axios.ts            # Axios instance config
├── router/
│   └── index.ts            # Vue Router config
├── stores/                 # Pinia stores
├── types/                  # TypeScript interfaces
├── views/                  # Page-level components
│   └── HomeView.vue
├── App.vue
└── main.ts
```

### 7. Configure Router
- Set up `createRouter` with `createWebHistory`
- Add a home route (`/`) as starting point

### 8. Configure Pinia
- Install Pinia plugin in `main.ts`

### 9. Configure Axios
- Create a base Axios instance in `src/lib/axios.ts` with a placeholder `baseURL`

### 10. Wire everything together in `main.ts`
- Import CSS, create app, use Router, use Pinia, mount

### 11. Create a minimal App shell
- `App.vue` with `<RouterView />` inside a `DefaultLayout`
- `DefaultLayout.vue` with a basic nav header and main content area
- `HomeView.vue` as a landing page with the app name

## Verification
1. Run `npm run dev` — app starts without errors
2. Navigate to `http://localhost:5173` — see the home page with nav
3. Verify Tailwind styles are applied
4. Verify shadcn-vue Button renders correctly
5. Verify Lucide icon renders
6. Run `npx vue-tsc --noEmit` — no TypeScript errors

# Plan: Simple "Hello World" Vue Setup

## Context
`App.vue` and `router/index.ts` are currently empty files. The task is to wire them up so the app renders a basic "Hello World" page with Vue Router.

## Files to modify
- `client/src/App.vue` — Add template with `<RouterView />` component
- `client/src/router/index.ts` — Create router with a home route pointing to a Hello World view

## Implementation

### 1. `client/src/router/index.ts`
- Import `createRouter`, `createWebHistory` from `vue-router`
- Define a single `/` route with an inline or simple component that renders "Hello World"
- Export the router instance

### 2. `client/src/App.vue`
- Add a `<template>` with `<RouterView />`
- Minimal SFC — no script or style needed

## Verification
- Run `cd client && npm run dev` and open `http://localhost:5173` — should see "Hello World"
- Run `npm run type-check` to verify no TS errors

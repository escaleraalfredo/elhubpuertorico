# ElHub Puerto Rico

ElHub Puerto Rico – News + Vibes. A mobile app for Puerto Rico. The only product description so far is the tagline; the chosen stack (Supabase, maps, location, push notifications) suggests news plus local, location-aware content. Ask the owner before assuming specific features.

The app is at the scaffold stage: the stack is wired up, but product features (news feed, events, user accounts) are not built yet. The Home and Explore tabs still show Expo template content.

@AGENTS.md

## Stack

- Expo SDK 57, React Native 0.86, React 19, TypeScript (strict), React Compiler enabled
- Expo Router with file-based routes in `src/app/`. The tabs are defined in `src/components/app-tabs.tsx` (native tabs) and `app-tabs.web.tsx` (web).
- Supabase (`@supabase/supabase-js`) is the backend for data and auth
- `react-native-maps`, `expo-location`, `expo-notifications`

## Key files

| Path | Purpose |
| --- | --- |
| `src/lib/supabase.ts` | Supabase client. Stores the session in AsyncStorage, refreshes it only while the app is in the foreground, and throws if the env vars are missing. |
| `src/lib/notifications.ts` | Sets the foreground notification handler and provides `registerForPushNotificationsAsync()`, which returns an Expo push token or `null`. |
| `src/hooks/use-current-location.ts` | Asks for foreground location permission and returns `{ location, error }` |
| `src/app/_layout.tsx` | Root layout. Registers for push notifications on launch. TODO: save the token to Supabase. |
| `src/app/map.tsx` / `map.web.tsx` | Map centred on Puerto Rico (18.2208, -66.5901). Web gets a placeholder because react-native-maps has no web support. |
| `app.json` | Static config: bundle ID/package `com.elhubpuertorico.app`, scheme `elhubpuertorico`, and the location and notifications plugins |
| `app.config.ts` | Extends `app.json` with build-time env values (Google Maps Android key) |

## Environment

- Copy `.env.example` to `.env`. `.env` is git-ignored.
- `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY` are inlined into the client bundle. Never add secrets such as the `service_role` key under an `EXPO_PUBLIC_` name.
- `GOOGLE_MAPS_ANDROID_API_KEY` is optional and only read at build time by `app.config.ts`.

## Conventions

- Add packages with `npx expo install <pkg>` so versions match the SDK. If the network blocks the Expo API, `EXPO_OFFLINE=1 npx expo install <pkg>` uses the SDK's bundled version map.
- Keep non-route code (components, hooks, `lib/`) out of `src/app/`. Import through the `@/` path alias, which maps to `src/`.
- When a screen uses a native-only module, add a `.web.tsx` variant so static web rendering still works.
- User-facing copy is currently in English. Content will likely be Spanish and English, so confirm with the owner before hardcoding one language.
- Native modules mean you need a development build (`npx expo run:ios|android`), not Expo Go.

## Verifying changes

```bash
npm run typecheck                      # tsc --noEmit
npm run lint                           # expo lint (1 known template error in src/hooks/use-color-scheme.web.ts)
npx expo export --platform all         # bundles iOS/Android/web; needs a .env (placeholder values are fine)
```

The repo has no test suite or CI workflows yet.

# elhubpuertorico
ElHub Puerto Rico – News + Vibes

A mobile app built with [Expo](https://expo.dev) (SDK 57), React Native, and TypeScript.

## Stack

- **Expo Router** – file-based navigation (`src/app/`)
- **@supabase/supabase-js** – backend, auth and data (`src/lib/supabase.ts`)
- **react-native-maps** – map screen centered on Puerto Rico (`src/app/map.tsx`)
- **expo-location** – foreground location permission and current position (`src/hooks/use-current-location.ts`)
- **expo-notifications** – notification handler and Expo push token registration (`src/lib/notifications.ts`)

## Prerequisites

- Node.js 20+ and npm
- iOS Simulator (macOS + Xcode) and/or Android Emulator (Android Studio), or a physical device
- A [Supabase](https://supabase.com) project

## Setup

1. Install dependencies:

   ```bash
   npm install
   ```

2. Create your environment file:

   ```bash
   cp .env.example .env
   ```

   Then fill in the values from **Supabase → Project Settings → API**:

   | Variable | Description |
   | --- | --- |
   | `EXPO_PUBLIC_SUPABASE_URL` | Your project URL, e.g. `https://abcd1234.supabase.co` |
   | `EXPO_PUBLIC_SUPABASE_ANON_KEY` | The public `anon` key |
   | `GOOGLE_MAPS_ANDROID_API_KEY` | Optional. Google Maps SDK for Android key, needed for maps in Android release builds |

   `.env` is git-ignored. Variables prefixed with `EXPO_PUBLIC_` are inlined into the
   JS bundle, so never put secrets there (e.g. the Supabase `service_role` key).
   Restart the dev server after changing `.env`.

3. Start the app. `react-native-maps`, `expo-location` and `expo-notifications` contain
   native code, so use a [development build](https://docs.expo.dev/develop/development-builds/introduction/)
   rather than Expo Go:

   ```bash
   npx expo run:ios       # or
   npx expo run:android
   ```

   Or build in the cloud with EAS: `npx eas-cli@latest build --profile development`.

   After the first native build, `npm start` is enough for day-to-day JS changes.
   Web (`npm run web`) works too; the Map tab shows a placeholder there.

## Push notifications

Expo push tokens require an EAS project ID. Link the project once with:

```bash
npx eas-cli@latest init
```

Push tokens are only issued on physical devices. The token is logged on startup in
`src/app/_layout.tsx`; save it to Supabase to send notifications to a user.

## Project structure

```
src/
  app/          # Routes (Expo Router): _layout.tsx, index, explore, map
  components/   # Shared UI components
  constants/    # Theme values
  hooks/        # React hooks (color scheme, location)
  lib/          # Supabase client, notification helpers
app.json        # Static Expo config (permissions, plugins)
app.config.ts   # Dynamic config that reads build-time env vars
```

## Scripts

| Command | Description |
| --- | --- |
| `npm start` | Start the Expo dev server |
| `npm run ios` / `npm run android` / `npm run web` | Start and open on a platform |
| `npm run lint` | Lint with ESLint (`expo lint`) |
| `npm run typecheck` | Type-check with `tsc` |
| `npx expo export` | Produce production JS bundles for all platforms |

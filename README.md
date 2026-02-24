# HerVest AI Monorepo

This repository contains:

- Flutter mobile app at repo root (`lib/`, `android/`, `ios/`, etc.)
- Node/Supabase backend in `api/`

## Structure

- `lib/`: Flutter app source
- `api/src/`: Express API source
- `api/sql/schema.sql`: Supabase/Postgres schema
- `api/tests/`: backend integration test scaffolding

## Run Flutter App

1. `flutter pub get`
2. `flutter run`

Optional backend URL override:

- `flutter run --dart-define=API_BASE_URL=http://18.175.213.46:3000`

## Run Backend

1. `cd api`
2. `npm install`
3. Copy `api/.env.example` to `api/.env` and fill required values
4. `npm run dev`

Health endpoint (expected):

- `GET /api/health`

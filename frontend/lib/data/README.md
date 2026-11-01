# Data Architecture — Unlost Frontend

This directory contains the contract and mock data layer for the **Unlost** Flutter frontend.

## Overview
Currently, there is no live backend running. The app runs completely standalone using `MockAppRepository`, which implements the typed `AppRepository` interface.

```
UI Layer (Screens / Widgets)
       │
       ▼
Providers (State Management via ChangeNotifier)
       │
       ▼
AppRepository (Abstract Interface / Data Contract)
       │
       ├── MockAppRepository (Current: in-memory seed dataset, latency & flaky errors)
       └── HttpAppRepository (Future: real REST / GraphQL backend)
```

## Connecting a Real Backend Later
To connect a real HTTP backend in the future:
1. Implement `HttpAppRepository implements AppRepository` inside `lib/data/repositories/http_app_repository.dart`.
2. Map the endpoints to the typed methods in `AppRepository` (`login`, `register`, `getItems`, `createItem`, `submitClaim`, etc.).
3. In `lib/main.dart`, change the injected repository provider:
   ```dart
   // From:
   Provider<AppRepository>(create: (_) => MockAppRepository()),
   // To:
   Provider<AppRepository>(create: (_) => HttpAppRepository(baseUrl: 'https://api.unlost.campus.edu')),
   ```
4. **No UI or Provider rewrite is needed.** The models and data contract remain 100% identical.

## Methods the backend must mirror later
These exist on `AppRepository` and `MockAppRepository` only. The real backend has to provide matching endpoints:

- `submitFinderClaim(itemId, foundDescription)`: a finder says "I found this" on a LOST report. It starts as `awaiting_admin`, the admin passes or rejects it, then the owner answers.
- `confirmFinderClaim(claimId, isMine)`: the owner of the lost report answers "This is mine" (claim `approved`, item `resolved`, other open finder messages closed) or "Not mine" (claim `rejected`). Only the owner may call it and only while the claim is `passed_to_finder`.
- `submitReview`, `getReviewsForUser`, `getRecentReunions`, `getAllReviewsAdmin` (admin only), `hasReviewedCase`: one review per person per case, only on a `resolved` case, no self-reviews. `getRecentReunions` must return anonymised, positive reviews only (first name + initial, category, quote). Reviews do not change trust scores.
- The match score must be computed server-side later. The Flutter `MatchScorer` is only a stand-in.

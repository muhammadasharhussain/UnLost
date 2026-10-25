# UnLost Backend — Antigravity Brief (v0)

**Owner:** Ash (muhammadasharhussain07@gmail.com)
**Purpose:** Build the **UnLost backend from ground zero** as a teaching exercise — Antigravity's job is **to teach Ash backend architecture while building**, not to code-dump.

> "Antigravity" = the agent/engineer this doc is addressed to. Update this file as decisions get made — it is the single source of truth for the backend.

---

## 1) Mission

Build a **REST API backend** for UnLost (university lost & found) that serves:

1. the **Flutter app** already present at `frontend/` (see §2 — the frontend is DONE and defines the API contract), and
2. any **future web app** (same REST/JSON API — same backend serves both).

**Antigravity must TEACH the project workflow while building** — architecture first, explain every choice, no black boxes.

## 2) Critical context: the frontend already defines the contract

The Flutter frontend ships with a **typed API contract** and a **mock repository**. The backend must implement the same behaviour over HTTP.

**Read these files FIRST (frontend/lib/data/):**
- `repositories/app_repository.dart` — the API contract (auth, items, claims, handover OTP, chat, admin endpoints). Every method = one or more REST endpoints to implement.
- `models/` (`user_model.dart`, `item_model.dart`, `claim_model.dart`, `chat_message_model.dart`) — the data shapes. Only holder of truth for fields; backend schemas must match.
- `repositories/mock_app_repository.dart` — the reference behaviour (incl. claims approval → high-value items generate a 6-digit handover code, session persistence, error simulation).
- `data/README.md` — documents the swap from `MockAppRepository` → `HttpAppRepository(baseUrl: ...)` with **zero UI changes**.
- `PROGRESS.md` — full feature checklist the backend must cover.

**Key integration fact:** the frontend team will swap ONE provider line in `frontend/lib/main.dart`:
```dart
Provider<AppRepository>(create: (_) => HttpAppRepository(baseUrl: 'https://api.unlost.campus.edu'))
```
So: **stable base URL + JSON responses matching `*Model` shapes + auth token in responses** = done.

## 3) Tech stack (initial proposal — confirm/finalize with Ash before scaffolding)

| Layer | Choice | Notes |
|---|---|---|
| Runtime | **Node.js LTS (v20+)** | Ash knows Node from web dev — knowledge transfers |
| Framework | **Express** (or NestJS — decide in Phase 0) | Express keeps abstractions low → better for learning |
| Database | **MongoDB** (Atlas free tier or local) | Same stack as web projects |
| ODM | **Mongoose** | Schemas map 1:1 to the Flutter models |
| Auth | **JWT** + bcrypt | Flutter models have `role` field (student/admin) — enforce server-side |
| Realtime | plain polling first, WebSockets later (chat) | Don't over-engineer now |
| Tests / docs | automated tests + `API.md` | Every endpoint documented with cURL examples |

*-change anything in this table only with Ash's sign-off; update this file when you do.*

## 4) Build plan — ground zero (each phase ends with teaching checkpoint)

**Phase 0 — Environment & project anatomy**
- Install Node, set up repo folder (in `backend/`), git init if needed, understand request/response lifecycle
- **Checkpoint:** Ash can draw the request lifecycle (client → route → controller → service → model → DB → JSON response) unaided

**Phase 1 — Hello-World API**
- Minimal Express server, health check endpoint, connect mongo, serve JSON
- **Checkpoint:** explain middleware, routing, what `express.json()` does

**Phase 2 — Auth**
- Register/login flows emitting JWT; password hashing; role by fork of student vs. admin; token refresh decision
- **Checkpoint:** JWT anatomy, what lives client-side vs server-side, why hashing not encryption

**Phase 3 — Items**
- Collection + CRUD matching `getItems`, `createItem` etc.; filter/search params the client sends (`type`, `category`, `search`)
- **Checkpoint:** indexes/queries, pagination strategy the client imposes

**Phase 4 — Claims & handover codes + Admin**
- Claim lifecycle mirrors `submitClaim` → `approveClaim`/`rejectClaim` → `confirmHandover(otp)`; admin-only endpoints mirror `getPendingPosts` etc.
- **Checkpoint:** state machine diagram, token-based authorization middleware

**Phase 5 — Chat + glue the frontend**
- Messages matching `chat_message_model.dart`
- Implement what `HttpAppRepository` demands, hand frontend team the base URL + a token, verify end-to-end against the real app
- **Checkpoint:** full flow demo on a real device

## 5) Workflow rules

1. **Explain before code.** Write a short architecture blurb in `backend/` for each phase before writing it.
2. **Ask before choosing a library** not in this brief.
3. **Every phase: commit per meaningful step** (Ash to review between commits).
4. Keep `backend/API.md` updated alongside every endpoint change.
5. **No secrets in git:** `.env` is gitignored; ship `.env.example`. (Careful: `frontend/.env.example` already exists — be careful not to break the frontend in that folder.)
6. After backend is ready: fill §6 with real run instructions and update `API.md` index.

## 6) Run instructions — to be filled once Phase 1 exists

```
(to be written by Antigravity in Phase 1)
node --version needed X
backend/ endpoints...

How to point the Flutter app at it:
- Web: http://localhost:<port>
- Android emulator: http://10.0.2.2:<port>
- Real device: LAN IP of PC + same port, firewall allow inbound
```

## 7) Open questions for Ash (fill before/during Phase 0)

- [ ] Express vs NestJS? (brief author default: Express)
- [ ] MongoDB local vs Atlas cloud? (free)
- [ ] Where to run the backend in dev? (e.g. `backend/server/` subfolder / separate folder)
- [ ] JWT in headers only (REST) or also httpOnly cookie variant? (default: headers)
- [ ] Any existing browser/web client this must serve day-one? (or is Flutter the only client for now)

## 8) Notes

- Repo: <https://github.com/muhammadasharhussain/UnLost> — Ash pushes/pulls via VS Code source control; commits happen per phase not per keystroke.
- Reference frontend UX flows for corners in `PROGRESS.md` (handover codes, admin gates, trust score, chat notifications).
- Training-first mindset: if a shortcut hides a concept behind a black box, take the longer path and explain it.

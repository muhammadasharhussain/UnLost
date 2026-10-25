# UnLost Backend — Antigravity Brief (v1)

**Owner:** Ash (muhammadasharhussain07@gmail.com)
**Purpose:** Build the **UnLost backend from ground zero** as a teaching exercise — Antigravity's job is **to teach Ash backend architecture while building**, not to code-dump. 

> "Antigravity" = the agent/engineer this doc is addressed to. Update this file as decisions get made — it is the single source of truth for the backend.

---

## 1) Mission

Build a **REST API backend** for UnLost (university lost & found) that serves:

1. the **Flutter app** already present at `frontend/` (see §2 — the frontend is DONE and defines the API contract), and
2. any **future web app** (same REST/JSON API — same backend serves both).

**Teaching philosophy:** Architecture first, explain every choice, deep-dive into security & vulnerabilities, quiz checkpoints before progressing.

---

## 2) Critical context: the frontend already defines the contract

The Flutter frontend ships with a **typed API contract** and a **mock repository**. The backend must implement the same behaviour over HTTP.

**Key files (frontend/lib/data/):**
- `repositories/app_repository.dart` — API contract (auth, items, claims, handover OTP, chat, admin endpoints).
- `models/` (`user_model.dart`, `item_model.dart`, `claim_model.dart`, `chat_message_model.dart`) — data shapes.
- `repositories/mock_app_repository.dart` — reference behavior.
- `data/README.md` — documents the swap from `MockAppRepository` to `HttpAppRepository(baseUrl: ...)`.
- `PROGRESS.md` — full feature checklist.

---

## 3) Tech Stack (Finalized)

| Layer | Choice | Notes |
|---|---|---|
| Runtime | **Node.js LTS (v24.x)** | Asynchronous, non-blocking Event Loop |
| Framework | **Express 5** | Unopinionated, low-magic, ideal for learning request/response lifecycle |
| Database | **MongoDB Atlas** | Managed cloud replica set on AWS |
| ODM | **Mongoose 9** | Schema enforcement, validation, and object modeling |
| Auth | **JWT + bcrypt** | Stateless Bearer token auth in HTTP headers |
| Realtime | Polling first, WebSockets later | Chat |
| Tests / docs | automated tests + `API.md` | Documented endpoints with cURL |

---

## 4) Build plan

- [x] **Phase 0 — Environment & project anatomy** (Node, npm, git branch workflow, folder skeleton)
- [x] **Phase 1 — Hello-World API & Atlas Connection** (Express server, Atlas connected, live `/api/health` test)
- [ ] **Phase 2 — Auth** (Register/login with JWT, bcrypt hashing, User Mongoose model, auth middleware)
- [ ] **Phase 3 — Items** (Items CRUD, queries, search, hidden fields security)
- [ ] **Phase 4 — Claims & Handover Codes + Admin** (State machine, OTP generation, role-based authorization)
- [ ] **Phase 5 — Chat + Flutter Integration** (Messages, link Flutter app to live backend)

---

## 5) Workflow Rules

1. Explain before code.
2. Ask before choosing any new library.
3. Every phase done on its own feature branch (`phase/*`) and merged into `main`.
4. Keep `backend/API.md` updated with every endpoint change.
5. No secrets in Git: `.env` is gitignored; `.env.example` is committed.

---

## 6) Run Instructions

```bash
# 1. Enter the backend directory
cd backend

# 2. Install dependencies (if first time)
npm install

# 3. Ensure .env is set up with:
# PORT=3000
# MONGODB_URI=mongodb+srv://...
# JWT_SECRET=...
# JWT_EXPIRES_IN=7d

# 4. Start the development server (auto-reloads on file change)
npm run dev

# 5. Test health endpoint:
curl http://localhost:3000/api/health
```

### Pointing the Flutter app at the backend:
- **Web:** `http://localhost:3000`
- **Android Emulator:** `http://10.0.2.2:3000` (10.0.2.2 points to host machine localhost)
- **Physical Device:** `http://<YOUR_LAN_IP>:3000` (ensure Windows Firewall allows port 3000 inbound)

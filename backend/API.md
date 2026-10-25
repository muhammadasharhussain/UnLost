# UnLost API Reference

> Updated alongside every new endpoint.
> Base URL (local dev): `http://localhost:3000`

---

## 1. System & Health

### `GET /api/health`
Check if the API server and MongoDB Atlas connection are operational.

- **Auth Required:** No
- **Headers:** None required

#### Success Response (`200 OK`)
```json
{
  "status": "ok",
  "message": "UnLost API is running 🚀",
  "database": "connected",
  "timestamp": "2026-10-25T13:19:11.533Z"
}
```

#### Degraded Response (`503 Service Unavailable`)
```json
{
  "status": "degraded",
  "message": "UnLost API is running 🚀",
  "database": "disconnected",
  "timestamp": "2026-10-25T13:19:11.533Z"
}
```

#### Example cURL
```bash
curl http://localhost:3000/api/health
```

---

_More endpoints will be documented here as we implement Auth, Items, Claims, Chat, and Admin._

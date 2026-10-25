// server.js
//
// THE ENTRY POINT — this is the first file Node runs when you do "node server.js"
//
// WHAT HAPPENS IN ORDER:
//   1. Load secrets from .env into process.env
//   2. Connect to MongoDB
//   3. Create an Express app
//   4. Register middleware (functions that run on EVERY request, before controllers)
//   5. Register routes (which URLs map to which handlers)
//   6. Start listening on a port

// ─── Step 1: Load .env ───────────────────────────────────────────────────────
// dotenv reads the .env file and puts each line into process.env
// e.g. PORT=3000 → process.env.PORT === '3000'
// MUST be the very first line so every file below can use process.env.*
require('dotenv').config();

// ─── Step 2: Import dependencies ──────────────────────────────────────────────
const express = require('express');       // the web framework
const connectDB = require('./config/db'); // our DB connection function

// ─── Step 3: Connect to MongoDB ───────────────────────────────────────────────
// connectDB() returns a Promise, so we call it but don't await here
// (server still starts, routes register, but DB queries will work once connected)
connectDB();

// ─── Step 4: Create Express app ───────────────────────────────────────────────
// express() gives us an "app" object — this is the entire server
const app = express();

// ─── Step 5: Register Middleware ──────────────────────────────────────────────
//
// WHAT IS MIDDLEWARE?
// Middleware = functions that run on EVERY incoming request, BEFORE your route handler.
// Think of it like airport security: every passenger (request) goes through the
// metal detector (middleware) before they reach their gate (controller).
//
// express.json() — parses the raw body text of incoming requests into a JS object
// Without this: req.body is undefined even if Flutter sent { email: "..." }
// With this:    req.body.email === "ash@uni.edu"  ← accessible as a JS object
app.use(express.json());

// ─── Step 6: Routes ───────────────────────────────────────────────────────────
//
// WHAT IS A ROUTE?
// A route says: "when a request hits THIS URL with THIS HTTP method, run THIS function"
// We'll add real routes as we build each phase. For now, just a health check.
//
// Health check — the simplest possible endpoint
// Flutter app (or any monitoring tool) can call GET /api/health to verify the server is up
app.get('/api/health', (req, res) => {
  // req = the incoming request  (what Flutter sent)
  // res = the response we send back
  res.json({
    status: 'ok',
    message: 'UnLost API is running 🚀',
    timestamp: new Date().toISOString(), // ISO 8601 date string
  });
  // res.json() automatically:
  //   1. Sets Content-Type header to application/json
  //   2. Serializes the JS object to a JSON string
  //   3. Sends it with HTTP 200 status
});

// ─── Step 7: 404 catch-all ────────────────────────────────────────────────────
// If no route matched, Express falls through to here
// This must be LAST — after all routes
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ─── Step 8: Start listening ──────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
// process.env.PORT comes from .env
// || 3000 is a fallback — if PORT isn't set, use 3000

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`   Health check: http://localhost:${PORT}/api/health`);
});

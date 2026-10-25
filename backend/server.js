// server.js
//
// THE ENTRY POINT — this is the first file Node runs when you do "npm run dev"
//
// WHAT HAPPENS IN ORDER:
//   1. Load secrets from .env into process.env
//   2. Connect to MongoDB Atlas
//   3. Create an Express app
//   4. Register middleware (express.json, etc.)
//   5. Register routes (health check, auth, items, claims, chat, admin)
//   6. Start listening on PORT

// ─── Step 1: Load .env ───────────────────────────────────────────────────────
require('dotenv').config();

// ─── Step 2: Import dependencies ──────────────────────────────────────────────
const express = require('express');
const mongoose = require('mongoose');
const connectDB = require('./config/db');

// ─── Step 3: Connect to MongoDB ───────────────────────────────────────────────
connectDB();

// ─── Step 4: Create Express app ───────────────────────────────────────────────
const app = express();

// ─── Step 5: Register Middleware ──────────────────────────────────────────────
// express.json() parses incoming JSON bodies (req.body)
app.use(express.json());

// ─── Step 6: Routes ───────────────────────────────────────────────────────────

// Health check — verifies both the HTTP server and MongoDB Atlas connection
app.get('/api/health', (req, res) => {
  // readyState: 0 = disconnected, 1 = connected, 2 = connecting, 3 = disconnecting
  const isDbConnected = mongoose.connection.readyState === 1;

  res.status(isDbConnected ? 200 : 503).json({
    status: isDbConnected ? 'ok' : 'degraded',
    message: 'UnLost API is running 🚀',
    database: isDbConnected ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString(),
  });
});

// ─── Step 7: 404 catch-all ────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ─── Step 8: Start listening ──────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`   Health check: http://localhost:${PORT}/api/health`);
});

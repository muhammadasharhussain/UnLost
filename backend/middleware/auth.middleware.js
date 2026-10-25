// middleware/auth.middleware.js
// ─── Phase 2: Auth ────────────────────────────────────────────────────────────
//
// WHAT THIS WILL DO:
// Every protected route (anything requiring login) will run this middleware first.
// It reads the JWT from the Authorization header, verifies the signature,
// and attaches the decoded user payload to req.user.
//
// If the token is missing or tampered with → 401 Unauthorized (request blocked here)
// If valid → req.user = { id, role } and the request continues to the controller
//
// We'll implement this in Phase 2 when we build auth.
// Placeholder so the folder isn't empty.

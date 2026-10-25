// config/db.js
//
// WHAT THIS FILE DOES:
// Connects our Node.js server to MongoDB Atlas using Mongoose.
// We call connectDB() once when the server boots — after that, Mongoose
// keeps the connection alive automatically.
//
// WHY A SEPARATE FILE?
// Single Responsibility: server.js boots the server, db.js owns the DB connection.
// If we ever switch databases, we change ONE file.

const mongoose = require('mongoose');  // import the Mongoose library

const connectDB = async () => {
  try {
    // mongoose.connect() opens a persistent connection to MongoDB Atlas
    // process.env.MONGODB_URI reads the value from our .env file
    // (dotenv in server.js loads .env into process.env before this runs)
    const conn = await mongoose.connect(process.env.MONGODB_URI);

    console.log(`✅ MongoDB connected: ${conn.connection.host}`);
    // conn.connection.host prints something like "cluster0.abc.mongodb.net"
    // so you can see WHERE you're connected
  } catch (error) {
    // If connection fails (wrong password, no internet, etc.)
    // we log the error and EXIT — no point running a server with no database
    console.error(`❌ MongoDB connection error: ${error.message}`);
    process.exit(1); // exit code 1 = crash (0 = clean exit)
  }
};

module.exports = connectDB;
// module.exports is Node's way of saying "this is what other files get
// when they require() this file". Only connectDB is exported — nothing else leaks out.

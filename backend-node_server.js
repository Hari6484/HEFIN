// server.js - HEFIN Bridge: Express + Mongoose
// This file includes routes for syncing health, finance, users and basic query endpoints.
// Expanded with comments and small helpers for demonstration.

import express from "express";
import morgan from "morgan";
import bodyParser from "body-parser";
import cors from "cors";

import { Health } from "./models/Health.js";
import { Finance } from "./models/Finance.js";
import { User } from "./models/User.js";
import logger from "./utils/logger.js";
import { connectDB } from "./utils/db.js";

const app = express();
const PORT = process.env.PORT || 3000;

app.use(morgan("dev"));
app.use(bodyParser.json({ limit: "2mb" }));
app.use(cors());

// Connect to DB
await connectDB();

// Health sync
app.post("/sync/health", async (req, res) => {
  try {
    const payload = req.body;
    if (!payload || !payload.recordId) return res.status(400).json({ error: "invalid payload" });
    const record = new Health(payload);
    await record.save();
    res.json({ status: "ok", saved: record });
  } catch (err) {
    logger.error("sync/health error", err);
    res.status(500).json({ error: "db_error" });
  }
});

// Finance sync
app.post("/sync/finance", async (req, res) => {
  try {
    const payload = req.body;
    if (!payload || !payload.txnId) return res.status(400).json({ error: "invalid payload" });
    const txn = new Finance(payload);
    await txn.save();
    res.json({ status: "ok", saved: txn });
  } catch (err) {
    logger.error("sync/finance error", err);
    res.status(500).json({ error: "db_error" });
  }
});

// User sync
app.post("/sync/user", async (req, res) => {
  try {
    const payload = req.body;
    if (!payload || !payload.id) return res.status(400).json({ error: "invalid payload" });
    const user = new User(payload);
    await user.save();
    res.json({ status: "ok", saved: user });
  } catch (err) {
    logger.error("sync/user error", err);
    res.status(500).json({ error: "db_error" });
  }
});

// Query endpoints
app.get("/health/:userId", async (req, res) => {
  const data = await Health.findByUser(req.params.userId);
  res.json(data);
});

app.get("/finance/:userId", async (req, res) => {
  const data = await Finance.findByUser(req.params.userId);
  res.json(data);
});

app.get("/users", async (req, res) => {
  const data = await User.findAll();
  res.json(data);
});

// Basic health check
app.get("/_health", (req, res) => {
  res.json({ status: "ok", uptime: process.uptime() });
});

// Error handler
app.use((err, req, res, next) => {
  logger.error("Unhandled error", err);
  res.status(500).json({ error: "internal" });
});

// Start
app.listen(PORT, () => {
  logger.info("HEFIN Bridge listening on port " + PORT);
});

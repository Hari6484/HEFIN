// db.js - MongoDB connection helper
import mongoose from "mongoose";
import logger from "./logger.js";

export async function connectDB() {
  const uri = process.env.MONGO_URI || "mongodb://localhost:27017/hefin";
  try {
    await mongoose.connect(uri, { });
    logger.info("Connected to MongoDB:", uri);
  } catch (err) {
    logger.error("MongoDB connection error:", err);
    process.exit(1);
  }
}

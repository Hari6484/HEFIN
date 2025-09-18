// Health.js - Mongoose model for health records
// Expanded for GitHub scaffold with comments and basic statics.

import mongoose from "mongoose";

const HealthSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  recordId: { type: String, required: true, unique: true },
  diagnosis: { type: String, required: true },
  treatment: { type: String },
  notes: { type: String },
  timestamp: { type: Number, default: Date.now }
}, { timestamps: true });

// Basic static helper
HealthSchema.statics.findByUser = function(userId) {
  return this.find({ userId }).sort({ timestamp: -1 }).exec();
};

// Ensure index creation
HealthSchema.index({ userId: 1 });

export const Health = mongoose.model("Health", HealthSchema);

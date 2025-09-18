// Finance.js - Mongoose model for finance transactions

import mongoose from "mongoose";

const FinanceSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  txnId: { type: String, required: true, unique: true },
  amount: { type: Number, required: true },
  currency: { type: String, default: "USD" },
  category: { type: String },
  meta: { type: String },
  timestamp: { type: Number, default: Date.now }
}, { timestamps: true });

FinanceSchema.statics.findByUser = function(userId) {
  return this.find({ userId }).sort({ timestamp: -1 }).exec();
};

FinanceSchema.index({ userId: 1 });

export const Finance = mongoose.model("Finance", FinanceSchema);

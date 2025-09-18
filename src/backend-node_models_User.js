// User.js - Mongoose model for user profiles

import mongoose from "mongoose";

const UserSchema = new mongoose.Schema({
  id: { type: String, required: true, unique:true, index: true },
  name: { type: String, required: true },
  email: { type: String },
  role: { type: String, default: "patient" }
}, { timestamps: true });

UserSchema.statics.findAll = function() {
  return this.find({}).sort({ createdAt: -1 }).exec();
};

UserSchema.index({ id: 1 });

export const User = mongoose.model("User", UserSchema);

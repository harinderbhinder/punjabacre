const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name:      { type: String, trim: true },
  email:     { type: String, required: true, unique: true, trim: true, lowercase: true },
  phone:     { type: String, trim: true },
  address:   { type: String, trim: true },
  avatar:    { type: String },
  otp:       { type: String },
  otpExpiry: { type: Date },
  googleId:  { type: String },
  isActive:  { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);

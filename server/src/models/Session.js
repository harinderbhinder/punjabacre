const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', required: true },
  tokenHash: { type: String, required: true, unique: true }, // SHA-256 of refresh token
  createdAt: { type: Date, default: Date.now, expires: '7d' }, // auto-delete after 7 days
});

sessionSchema.index({ adminId: 1 });

module.exports = mongoose.model('Session', sessionSchema);

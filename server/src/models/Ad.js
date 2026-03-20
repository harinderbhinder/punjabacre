const mongoose = require('mongoose');

const adSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true },
  brand: { type: String, default: '', trim: true },
  price: { type: Number, required: true },
  description: { type: String, required: true },
  images: [{ type: String }],
  category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', required: true },
  subcategory: { type: mongoose.Schema.Types.ObjectId, ref: 'Subcategory', default: null },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  isActive: { type: Boolean, default: true },
  isApproved: { type: Boolean, default: false },
  approvalStatus: { type: String, enum: ['pending', 'approved', 'disapproved'], default: 'pending' },
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], default: undefined }, // [lng, lat]
  },
  address: { type: String, default: '' },
  city:    { type: String, default: '' },
  state:   { type: String, default: '' },
  attributes: { type: Map, of: String, default: {} },
}, { timestamps: true });

adSchema.index({ category: 1, createdAt: -1 });
adSchema.index({ isActive: 1, createdAt: -1 });
adSchema.index({ location: '2dsphere' }, { sparse: true });

// Remove malformed location before saving
adSchema.pre('save', function (next) {
  if (this.location && (!this.location.coordinates || this.location.coordinates.length < 2)) {
    this.location = undefined;
  }
  next();
});

module.exports = mongoose.model('Ad', adSchema);

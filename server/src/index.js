require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const path = require('path');
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const rateLimit = require('express-rate-limit');
const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4']);

const authRoutes = require('./routes/auth');
const userAuthRoutes = require('./routes/userAuth');
const userProfileRoutes = require('./routes/userProfile');
const categoryRoutes = require('./routes/categories');
const subcategoryRoutes = require('./routes/subcategories');
const adRoutes = require('./routes/ads');
const bannerRoutes = require('./routes/banners');

const app = express();

// Security headers
app.use(helmet({
  contentSecurityPolicy: false, // allow React app to load
  crossOriginResourcePolicy: { policy: 'cross-origin' }, // allow images to load cross-origin
}));

// Prevent NoSQL injection
app.use(mongoSanitize());

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl) or any localhost origin
    if (!origin || origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
      return callback(null, true);
    }
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
}));
app.use(express.json({ limit: '10kb' })); // limit body size

// Global rate limit
app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 100,
  message: { message: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
}));

// Strict rate limit on login
app.use('/api/auth/login', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { message: 'Too many login attempts, please try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
}));

// Serve React admin panel static build
const buildPath = path.join(__dirname, '../../admin-panel/build');
app.use(express.static(buildPath));

// Serve uploaded images
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/user', userAuthRoutes);
app.use('/api/user', userProfileRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/subcategories', subcategoryRoutes);
app.use('/api/ads', adRoutes);
app.use('/api/banners', bannerRoutes);

// All non-API routes serve the React app (client-side routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(buildPath, 'index.html'));
});

// Connect to MongoDB and start server
mongoose
  .connect(process.env.MONGO_URI)
  .then(async () => {
    console.log(`MongoDB connected [worker ${process.pid}]`);
    await dropLegacyIndexes();
    await fixBadLocations();
    await seedAdmin();
    await seedCategories();
    const server = app.listen(process.env.PORT, () =>
      console.log(`Worker ${process.pid} listening on port ${process.env.PORT}`)
    );

    // Graceful shutdown for PM2 cluster restarts
    process.on('SIGINT', () => gracefulShutdown(server));
    process.on('SIGTERM', () => gracefulShutdown(server));
  })
  .catch((err) => console.error('MongoDB connection error:', err));

function gracefulShutdown(server) {
  console.log(`Worker ${process.pid} shutting down gracefully...`);
  server.close(() => {
    mongoose.connection.close(false, () => {
      console.log(`Worker ${process.pid} exited cleanly`);
      process.exit(0);
    });
  });
  // Force exit after 10s if still hanging
  setTimeout(() => process.exit(1), 10000);
}

// Drop legacy indexes that no longer match the current schema
async function dropLegacyIndexes() {
  try {
    const col = mongoose.connection.collection('users');
    await col.dropIndex('phone_1');
    console.log('Dropped legacy phone_1 index from users');
  } catch (e) {
    // Index doesn't exist — that's fine
  }
}

// Fix ads that have location.type but no coordinates (breaks 2dsphere index)
async function fixBadLocations() {
  try {
    const result = await mongoose.connection.collection('ads').updateMany(
      { 'location.type': 'Point', 'location.coordinates': { $exists: false } },
      { $unset: { location: '' } }
    );
    if (result.modifiedCount > 0)
      console.log(`Fixed ${result.modifiedCount} ads with malformed location`);
  } catch (e) {
    console.error('fixBadLocations error:', e.message);
  }
}

// Seed default admin if none exists
async function seedAdmin() {
  const Admin = require('./models/Admin');
  const bcrypt = require('bcryptjs');
  const existing = await Admin.findOne({ email: 'admin@app.com' });
  if (!existing) {
    const hash = await bcrypt.hash('admin123', 10);
    await Admin.create({ email: 'admin@app.com', password: hash, name: 'Super Admin' });
  }
}

// Seed default categories if none exist
async function seedCategories() {
  const Category = require('./models/Category');
  const count = await Category.countDocuments();
  if (count > 0) return;

  const categories = [
    { name: 'Agriculture Land',       icon: '🌾', order: 1 },
    { name: 'House / Home / Apartment', icon: '🏠', order: 2 },
    { name: 'Shop / Booth',           icon: '🏪', order: 3 },
    { name: 'Store / Warehouse',      icon: '🏭', order: 4 },
    { name: 'Businesses',             icon: '💼', order: 5 },
    { name: 'Plots',                  icon: '📐', order: 6 },
    { name: 'Tubewell Connection',    icon: '💧', order: 7 },
  ];

  await Category.insertMany(categories);
  console.log('Default categories seeded');
}

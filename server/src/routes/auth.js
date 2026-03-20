const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const Admin = require('../models/Admin');
const Session = require('../models/Session');
const auth = require('../middleware/auth');

const ACCESS_EXPIRES = '15m';

function generateAccessToken(admin) {
  return jwt.sign(
    { id: admin._id, email: admin.email, name: admin.name },
    process.env.JWT_SECRET,
    { expiresIn: ACCESS_EXPIRES }
  );
}

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password)
      return res.status(400).json({ message: 'Email and password are required' });

    const admin = await Admin.findOne({ email: email.toLowerCase().trim() });

    // Always run bcrypt to prevent timing attacks
    const dummyHash = '$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012345';
    const match = await bcrypt.compare(password, admin ? admin.password : dummyHash);

    if (!admin) return res.status(401).json({ message: 'Invalid credentials' });

    if (admin.isLocked) {
      const remaining = Math.ceil((admin.lockUntil - Date.now()) / 60000);
      return res.status(423).json({
        message: `Account locked. Try again in ${remaining} minute(s).`,
      });
    }

    if (!match) {
      await admin.incLoginAttempts();
      const attemptsLeft = 5 - (admin.loginAttempts + 1);
      return res.status(401).json({
        message: attemptsLeft > 0
          ? `Invalid credentials. ${attemptsLeft} attempt(s) remaining.`
          : 'Account locked for 15 minutes due to too many failed attempts.',
      });
    }

    await admin.resetLoginAttempts();

    const accessToken = generateAccessToken(admin);
    const refreshToken = crypto.randomBytes(40).toString('hex');

    // Store hashed refresh token in MongoDB (shared across all PM2 workers)
    await Session.create({ adminId: admin._id, tokenHash: hashToken(refreshToken) });

    res.json({
      accessToken,
      refreshToken,
      admin: { id: admin._id, name: admin.name, email: admin.email },
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// POST /api/auth/refresh
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ message: 'Refresh token required' });

    const session = await Session.findOne({ tokenHash: hashToken(refreshToken) }).populate('adminId');
    if (!session) return res.status(401).json({ message: 'Invalid or expired session' });

    const accessToken = generateAccessToken(session.adminId);
    res.json({ accessToken });
  } catch (err) {
    res.status(500).json({ message: 'Internal server error' });
  }
});

// POST /api/auth/logout
router.post('/logout', auth, async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await Session.deleteOne({ tokenHash: hashToken(refreshToken) });
    }
    res.json({ message: 'Logged out' });
  } catch (err) {
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /api/auth/me
router.get('/me', auth, async (req, res) => {
  try {
    const admin = await Admin.findById(req.admin.id).select('-password');
    if (!admin) return res.status(404).json({ message: 'Admin not found' });
    res.json(admin);
  } catch (err) {
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;

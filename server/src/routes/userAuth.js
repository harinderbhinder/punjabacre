const router = require('express').Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { Resend } = require('resend');
const User = require('../models/User');

const resend = new Resend(process.env.RESEND_API_KEY);
const OTP_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes

function generateToken(user) {
  return jwt.sign(
    { id: user._id, name: user.name, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );
}

function generateOtp() {
  return crypto.randomInt(100000, 999999).toString();
}

async function sendOtp(email, otp) {
  await resend.emails.send({
    from: process.env.RESEND_FROM,
    to: email,
    subject: 'Your OTP Code',
    html: `
      <div style="font-family:sans-serif;max-width:400px;margin:auto;padding:32px;border-radius:12px;border:1px solid #eee">
        <h2 style="color:#6CA651;margin-bottom:8px">Classified App</h2>
        <p style="color:#555;margin-bottom:24px">Use the code below to sign in. It expires in 10 minutes.</p>
        <div style="background:#f5f5f5;border-radius:10px;padding:20px;text-align:center;font-size:36px;font-weight:800;letter-spacing:12px;color:#222">
          ${otp}
        </div>
        <p style="color:#aaa;font-size:12px;margin-top:24px">If you didn't request this, ignore this email.</p>
      </div>
    `,
  });
  console.log(`[OTP] sent to ${email}`);
}

// POST /api/user/send-otp
// Body: { email }
router.post('/send-otp', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
      return res.status(400).json({ message: 'Valid email is required' });

    const otp = generateOtp();
    const otpExpiry = new Date(Date.now() + OTP_EXPIRY_MS);

    await User.findOneAndUpdate(
      { email: email.toLowerCase().trim() },
      { $set: { otp, otpExpiry }, $setOnInsert: { isActive: true } },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    await sendOtp(email, otp);
    console.log(`[send-otp] OTP for ${email}: ${otp}`); // remove in production
    res.json({ message: 'OTP sent' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/user/verify-otp
// Body: { email, otp, name? }
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp, name } = req.body;
    if (!email || !otp)
      return res.status(400).json({ message: 'Email and OTP are required' });

    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) return res.status(401).json({ message: 'Invalid OTP' });

    // Compare as strings, trim any whitespace
    if (user.otp?.toString().trim() !== otp.toString().trim())
      return res.status(401).json({ message: 'Invalid OTP' });

    if (!user.otpExpiry || user.otpExpiry < new Date())
      return res.status(401).json({ message: 'OTP expired, please request a new one' });

    if (!user.isActive)
      return res.status(403).json({ message: 'Account is disabled' });

    // Save name if provided (first time)
    if (name && !user.name) user.name = name.trim();

    // Clear OTP after use
    user.otp = undefined;
    user.otpExpiry = undefined;
    await user.save();

    const token = generateToken(user);
    res.json({ token, user: { id: user._id, name: user.name, email: user.email } });
  } catch (err) {
    console.error('[verify-otp]', err);
    res.status(500).json({ message: err.message });
  }
});

// POST /api/user/google
// Body: { idToken } — verify Google ID token and sign in / register
router.post('/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ message: 'idToken required' });

    // Verify token with Google
    const response = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`
    );
    const payload = await response.json();

    if (payload.error || !payload.email) {
      return res.status(401).json({ message: 'Invalid Google token' });
    }

    const { email, name, sub: googleId } = payload;

    let user = await User.findOne({ email });
    if (!user) {
      user = await User.create({ email, name: name || '', googleId, isActive: true });
    } else {
      if (!user.isActive) return res.status(403).json({ message: 'Account is disabled' });
      if (!user.googleId) { user.googleId = googleId; await user.save(); }
    }

    const token = generateToken(user);
    res.json({ token, user: { id: user._id, name: user.name, email: user.email } });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;

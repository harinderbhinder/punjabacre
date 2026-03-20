const router = require('express').Router();
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');
const User = require('../models/User');
const userAuth = require('../middleware/userAuth');
const upload = require('../middleware/upload');

const AVATAR_DIR = path.join(__dirname, '../../uploads/avatars');
if (!fs.existsSync(AVATAR_DIR)) fs.mkdirSync(AVATAR_DIR, { recursive: true });

// GET /api/user/profile
router.get('/profile', userAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-otp -otpExpiry');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/user/profile
router.put('/profile', userAuth, async (req, res) => {
  try {
    const { name, phone, address } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (name !== undefined) user.name = name.trim();
    if (phone !== undefined) user.phone = phone.trim();
    if (address !== undefined) user.address = address.trim();
    await user.save();
    res.json({ id: user._id, name: user.name, email: user.email, phone: user.phone, address: user.address, avatar: user.avatar });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// POST /api/user/avatar
router.post('/avatar', userAuth, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded' });
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Delete old avatar
    if (user.avatar) {
      const old = path.join(__dirname, '../../', user.avatar);
      if (fs.existsSync(old)) fs.unlinkSync(old);
    }

    const filename = `avatar_${user._id}_${Date.now()}.webp`;
    const outPath = path.join(AVATAR_DIR, filename);
    await sharp(req.file.buffer)
      .resize(200, 200, { fit: 'cover' })
      .webp({ quality: 85 })
      .toFile(outPath);

    user.avatar = `/uploads/avatars/${filename}`;
    await user.save();
    res.json({ avatar: user.avatar });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

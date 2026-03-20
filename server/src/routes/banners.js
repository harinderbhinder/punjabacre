const router = require('express').Router();
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');
const Banner = require('../models/Banner');
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');

const UPLOAD_DIR = path.join(__dirname, '../../uploads/banners');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

async function saveImage(buffer, filename) {
  const outPath = path.join(UPLOAD_DIR, filename);
  await sharp(buffer)
    .resize(1200, 400, { fit: 'cover' })
    .webp({ quality: 85 })
    .toFile(outPath);
  return `/uploads/banners/${filename}`;
}

// GET /api/banners/public — Flutter app fetches active banners
router.get('/public', async (req, res) => {
  try {
    const banners = await Banner.find({ isActive: true }).sort({ order: 1 });
    res.json({ data: banners });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/banners — admin
router.get('/', auth, async (req, res) => {
  try {
    const banners = await Banner.find().sort({ order: 1 });
    res.json({ data: banners });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/banners — admin create
router.post('/', auth, (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      console.error('[Banner upload error]', err.message);
      return res.status(400).json({ message: `Upload error: ${err.message}` });
    }
    next();
  });
}, async (req, res) => {
  try {
    console.log('[Banner POST] req.file:', req.file ? req.file.originalname : 'undefined');
    console.log('[Banner POST] req.body:', req.body);
    const { title, subtitle, buttonText, order, isActive } = req.body;
    let image = '';
    if (req.file) {
      const filename = `banner_${Date.now()}.webp`;
      image = await saveImage(req.file.buffer, filename);
    }
    const banner = await Banner.create({
      title, subtitle, buttonText, image,
      order: parseInt(order) || 0,
      isActive: isActive !== 'false',
    });
    res.status(201).json(banner);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// PUT /api/banners/:id — admin update
router.put('/:id', auth, (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      console.error('[Banner upload error]', err.message);
      return res.status(400).json({ message: `Upload error: ${err.message}` });
    }
    next();
  });
}, async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id);
    if (!banner) return res.status(404).json({ message: 'Banner not found' });

    const { title, subtitle, buttonText, order, isActive } = req.body;
    if (title !== undefined) banner.title = title;
    if (subtitle !== undefined) banner.subtitle = subtitle;
    if (buttonText !== undefined) banner.buttonText = buttonText;
    if (order !== undefined) banner.order = parseInt(order) || 0;
    if (isActive !== undefined) banner.isActive = isActive !== 'false';

    if (req.file) {
      // Delete old image
      if (banner.image) {
        const old = path.join(__dirname, '../../', banner.image);
        if (fs.existsSync(old)) fs.unlinkSync(old);
      }
      const filename = `banner_${Date.now()}.webp`;
      banner.image = await saveImage(req.file.buffer, filename);
    }

    await banner.save();
    res.json(banner);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE /api/banners/:id — admin delete
router.delete('/:id', auth, async (req, res) => {
  try {
    const banner = await Banner.findByIdAndDelete(req.params.id);
    if (!banner) return res.status(404).json({ message: 'Banner not found' });
    if (banner.image) {
      const old = path.join(__dirname, '../../', banner.image);
      if (fs.existsSync(old)) fs.unlinkSync(old);
    }
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

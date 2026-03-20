const router = require('express').Router();
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');
const Subcategory = require('../models/Subcategory');
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');

const UPLOAD_DIR = path.join(__dirname, '../../uploads/subcategories');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

async function saveImage(buffer, filename) {
  const outPath = path.join(UPLOAD_DIR, filename);
  await sharp(buffer)
    .resize(400, 400, { fit: 'cover' })
    .webp({ quality: 80 })
    .toFile(outPath);
  return `/uploads/subcategories/${filename}`;
}

function deleteImage(imagePath) {
  if (!imagePath) return;
  const full = path.join(__dirname, '../../', imagePath);
  if (fs.existsSync(full)) fs.unlinkSync(full);
}

// GET subcategories — public for app
router.get('/public', async (req, res) => {
  try {
    const filter = { isActive: true };
    if (req.query.categoryId) filter.category = req.query.categoryId;
    const subcategories = await Subcategory.find(filter)
      .populate('category', 'name')
      .sort({ order: 1, createdAt: -1 });
    res.json(subcategories);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET all subcategories
router.get('/', auth, async (req, res) => {
  try {
    const filter = req.query.categoryId ? { category: req.query.categoryId } : {};
    const subcategories = await Subcategory.find(filter)
      .populate('category', 'name')
      .sort({ order: 1, createdAt: -1 });
    res.json(subcategories);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST create subcategory
router.post('/', auth, upload.single('image'), async (req, res) => {
  try {
    const { name, icon, categoryId, order } = req.body;
    let image = '';
    if (req.file) {
      const filename = `sub_${Date.now()}.webp`;
      image = await saveImage(req.file.buffer, filename);
    }
    const subcategory = await Subcategory.create({
      name, icon, image, category: categoryId, order: order ?? 0,
    });
    await subcategory.populate('category', 'name');
    res.status(201).json(subcategory);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// PUT update subcategory
router.put('/:id', auth, upload.single('image'), async (req, res) => {
  try {
    const { name, icon, isActive, categoryId, order } = req.body;
    const existing = await Subcategory.findById(req.params.id);
    if (!existing) return res.status(404).json({ message: 'Subcategory not found' });

    let image = existing.image;
    if (req.file) {
      deleteImage(existing.image);
      const filename = `sub_${Date.now()}.webp`;
      image = await saveImage(req.file.buffer, filename);
    }

    const update = {
      name, icon, image,
      isActive: isActive === 'true' || isActive === true,
      order: order ?? 0,
    };
    if (categoryId) update.category = categoryId;

    const subcategory = await Subcategory.findByIdAndUpdate(req.params.id, update, { new: true })
      .populate('category', 'name');
    res.json(subcategory);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE subcategory
router.delete('/:id', auth, async (req, res) => {
  try {
    const subcategory = await Subcategory.findByIdAndDelete(req.params.id);
    if (!subcategory) return res.status(404).json({ message: 'Subcategory not found' });
    deleteImage(subcategory.image);
    res.json({ message: 'Subcategory deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

const router = require('express').Router();
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');
const Category = require('../models/Category');
const Subcategory = require('../models/Subcategory');
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');

const UPLOAD_DIR = path.join(__dirname, '../../uploads/categories');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

async function saveImage(buffer, filename) {
  const outPath = path.join(UPLOAD_DIR, filename);
  await sharp(buffer)
    .resize(400, 400, { fit: 'cover' })
    .webp({ quality: 80 })
    .toFile(outPath);
  return `/uploads/categories/${filename}`;
}

function deleteImage(imagePath) {
  if (!imagePath) return;
  const full = path.join(__dirname, '../../', imagePath);
  if (fs.existsSync(full)) fs.unlinkSync(full);
}

// GET all categories — public for app
router.get('/public', async (req, res) => {
  try {
    const categories = await Category.find({ isActive: true }).sort({ order: 1, createdAt: -1 });
    res.json(categories);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET all categories
router.get('/', auth, async (req, res) => {
  try {
    const categories = await Category.find().sort({ order: 1, createdAt: -1 });
    res.json(categories);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST create category
router.post('/', auth, upload.single('image'), async (req, res) => {
  try {
    const { name, icon, order } = req.body;
    let image = '';
    if (req.file) {
      const filename = `cat_${Date.now()}.webp`;
      image = await saveImage(req.file.buffer, filename);
    }
    const category = await Category.create({ name, icon, image, order: order ?? 0 });
    res.status(201).json(category);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// PUT update category
router.put('/:id', auth, upload.single('image'), async (req, res) => {
  try {
    const { name, icon, isActive, order } = req.body;
    const existing = await Category.findById(req.params.id);
    if (!existing) return res.status(404).json({ message: 'Category not found' });

    let image = existing.image;
    if (req.file) {
      deleteImage(existing.image); // remove old image
      const filename = `cat_${Date.now()}.webp`;
      image = await saveImage(req.file.buffer, filename);
    }

    const category = await Category.findByIdAndUpdate(
      req.params.id,
      { name, icon, image, isActive: isActive === 'true' || isActive === true, order: order ?? 0 },
      { new: true }
    );
    res.json(category);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE category
router.delete('/:id', auth, async (req, res) => {
  try {
    const category = await Category.findByIdAndDelete(req.params.id);
    if (!category) return res.status(404).json({ message: 'Category not found' });
    deleteImage(category.image);
    await Subcategory.deleteMany({ category: req.params.id });
    res.json({ message: 'Category deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

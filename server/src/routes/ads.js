const router = require('express').Router();
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');
const Ad = require('../models/Ad');
const upload = require('../middleware/upload');
const userAuth = require('../middleware/userAuth');
const adminAuth = require('../middleware/auth');

const UPLOAD_DIR = path.join(__dirname, '../../uploads/ads');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

async function saveImage(buffer, filename) {
  const outPath = path.join(UPLOAD_DIR, filename);
  await sharp(buffer)
    .resize(800, 600, { fit: 'inside', withoutEnlargement: true })
    .webp({ quality: 82 })
    .toFile(outPath);
  return `/uploads/ads/${filename}`;
}

function deleteImages(images = []) {
  images.forEach((img) => {
    const full = path.join(__dirname, '../../', img);
    if (fs.existsSync(full)) fs.unlinkSync(full);
  });
}

// GET /api/ads — public, paginated, nearest first if lat/lng provided
router.get('/', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(20, parseInt(req.query.limit) || 10);
    const skip = (page - 1) * limit;
    const filter = { isActive: true, approvalStatus: 'approved' };
    if (req.query.categoryId) filter.category = req.query.categoryId;
    if (req.query.subcategoryId) filter.subcategory = req.query.subcategoryId;
    if (req.query.q) {
      const re = new RegExp(req.query.q, 'i');
      filter.$or = [{ title: re }, { brand: re }, { description: re }];
    }

    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const hasLocation = !isNaN(lat) && !isNaN(lng);

    let ads, total;

    if (hasLocation) {
      // Use $geoNear aggregation to sort by distance
      const geoNearStage = {
        $geoNear: {
          near: { type: 'Point', coordinates: [lng, lat] },
          distanceField: 'distance',
          spherical: true,
          query: filter,
        },
      };
      const pipeline = [
        geoNearStage,
        { $skip: skip },
        { $limit: limit },
        { $lookup: { from: 'categories', localField: 'category', foreignField: '_id', as: 'category' } },
        { $unwind: { path: '$category', preserveNullAndEmpty: true } },
        { $lookup: { from: 'subcategories', localField: 'subcategory', foreignField: '_id', as: 'subcategory' } },
        { $unwind: { path: '$subcategory', preserveNullAndEmpty: true } },
        { $lookup: { from: 'users', localField: 'user', foreignField: '_id', as: 'user' } },
        { $unwind: { path: '$user', preserveNullAndEmpty: true } },
        { $addFields: { 'user.name': '$user.name', 'user.avatar': '$user.avatar' } },
      ];
      const countPipeline = [geoNearStage, { $count: 'total' }];
      const [results, countResult] = await Promise.all([
        Ad.aggregate(pipeline),
        Ad.aggregate(countPipeline),
      ]);
      ads = results;
      total = countResult[0]?.total || 0;
    } else {
      [ads, total] = await Promise.all([
        Ad.find(filter)
          .populate('category', 'name icon image')
          .populate('subcategory', 'name')
          .populate('user', 'name avatar')
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit),
        Ad.countDocuments(filter),
      ]);
    }

    res.json({ ads, total, page, pages: Math.ceil(total / limit) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/ads/my — user's own ads (requires auth)
router.get('/my', userAuth, async (req, res) => {
  try {
    const ads = await Ad.find({ user: req.user.id })
      .populate('category', 'name icon image')
      .populate('subcategory', 'name')
      .sort({ createdAt: -1 });
    res.json({ ads });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/ads/:id — single ad
router.get('/:id', async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id)
      .populate('category', 'name icon image')
      .populate('subcategory', 'name')
      .populate('user', 'name avatar');
    if (!ad) return res.status(404).json({ message: 'Ad not found' });
    res.json(ad);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/ads/:id — edit own ad (requires auth)
router.put('/:id', userAuth, upload.array('images', 6), async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id);
    if (!ad) return res.status(404).json({ message: 'Ad not found' });
    if (ad.user?.toString() !== req.user.id)
      return res.status(403).json({ message: 'Not your ad' });

    const { title, brand, price, description } = req.body;
    if (title) ad.title = title;
    if (brand !== undefined) ad.brand = brand;
    if (price) ad.price = parseFloat(price);
    if (description) ad.description = description;

    // If new images uploaded, replace old ones
    if (req.files?.length) {
      deleteImages(ad.images);
      const newImages = [];
      for (const file of req.files) {
        const filename = `ad_${Date.now()}_${Math.random().toString(36).slice(2)}.webp`;
        newImages.push(await saveImage(file.buffer, filename));
      }
      ad.images = newImages;
    }

    await ad.save();
    await ad.populate('category', 'name icon');
    await ad.populate('subcategory', 'name');
    res.json(ad);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE /api/ads/:id — delete own ad (requires auth)
router.delete('/:id', userAuth, async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id);
    if (!ad) return res.status(404).json({ message: 'Ad not found' });
    if (ad.user?.toString() !== req.user.id)
      return res.status(403).json({ message: 'Not your ad' });
    deleteImages(ad.images);
    await ad.deleteOne();
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/ads/:id/toggle — disable/enable own ad (requires auth)
router.patch('/:id/toggle', userAuth, async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id);
    if (!ad) return res.status(404).json({ message: 'Ad not found' });
    if (ad.user?.toString() !== req.user.id)
      return res.status(403).json({ message: 'Not your ad' });
    ad.isActive = !ad.isActive;
    await ad.save();
    res.json({ isActive: ad.isActive });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/ads — requires user login
router.post('/', userAuth, upload.array('images', 6), async (req, res) => {
  try {
    const { title, brand, price, description, categoryId, subcategoryId, lat, lng, city, area, address, state } = req.body;
    const images = [];
    if (req.files?.length) {
      for (const file of req.files) {
        const filename = `ad_${Date.now()}_${Math.random().toString(36).slice(2)}.webp`;
        const imgPath = await saveImage(file.buffer, filename);
        images.push(imgPath);
      }
    }

    // Parse attributes[key] fields from body
    const attributes = {};
    for (const key of Object.keys(req.body)) {
      const match = key.match(/^attributes\[(.+)\]$/);
      if (match) attributes[match[1]] = req.body[key];
    }

    const adData = {
      title, brand, price: parseFloat(price), description,
      images, category: categoryId,
      subcategory: subcategoryId || null,
      user: req.user.id,
      address: address || '',
      area: area || '',
      city: city || '',
      state: state || '',
      attributes,
    };

    // Save location if provided
    const latNum = parseFloat(lat);
    const lngNum = parseFloat(lng);
    if (!isNaN(latNum) && !isNaN(lngNum)) {
      adData.location = { type: 'Point', coordinates: [lngNum, latNum] };
    }

    const ad = await Ad.create(adData);
    await ad.populate('category', 'name icon');
    await ad.populate('subcategory', 'name');
    res.status(201).json(ad);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// ── Admin routes ────────────────────────────────────────────────────────────

// GET /api/ads/admin/all — all ads with pagination + filters
router.get('/admin/all', adminAuth, async (req, res) => {
  try {
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const skip  = (page - 1) * limit;
    const filter = {};
    if (req.query.isActive   !== undefined) filter.isActive   = req.query.isActive   === 'true';
    if (req.query.isApproved !== undefined) filter.isApproved = req.query.isApproved === 'true';
    if (req.query.q) {
      const re = new RegExp(req.query.q, 'i');
      filter.$or = [{ title: re }, { brand: re }];
    }
    const [ads, total] = await Promise.all([
      Ad.find(filter)
        .populate('category', 'name')
        .populate('user', 'name email')
        .sort({ createdAt: -1 })
        .skip(skip).limit(limit),
      Ad.countDocuments(filter),
    ]);
    res.json({ ads, total, page, pages: Math.ceil(total / limit) });
  } catch (err) { res.status(500).json({ message: err.message }); }
});

// PATCH /api/ads/admin/:id/toggle — enable/disable
router.patch('/admin/:id/toggle', adminAuth, async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id);
    if (!ad) return res.status(404).json({ message: 'Not found' });
    ad.isActive = !ad.isActive;
    await ad.save();
    res.json({ isActive: ad.isActive });
  } catch (err) { res.status(500).json({ message: err.message }); }
});

// PATCH /api/ads/admin/:id/approve — toggle approve/disapprove
router.patch('/admin/:id/approve', adminAuth, async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id);
    if (!ad) return res.status(404).json({ message: 'Not found' });
    const { action } = req.body; // 'approve' | 'disapprove'
    if (!['approve', 'disapprove'].includes(action))
      return res.status(400).json({ message: 'action must be approve or disapprove' });
    ad.approvalStatus = action === 'approve' ? 'approved' : 'disapproved';
    ad.isApproved = ad.approvalStatus === 'approved';
    await ad.save();
    res.json({ approvalStatus: ad.approvalStatus, isApproved: ad.isApproved });
  } catch (err) { res.status(500).json({ message: err.message }); }
});

// DELETE /api/ads/admin/:id — admin delete any ad
router.delete('/admin/:id', adminAuth, async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id);
    if (!ad) return res.status(404).json({ message: 'Not found' });
    deleteImages(ad.images);
    await ad.deleteOne();
    res.json({ message: 'Deleted' });
  } catch (err) { res.status(500).json({ message: err.message }); }
});

module.exports = router;

const multer = require('multer');
const path = require('path');

// Store in memory so sharp can process before saving
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowed = /jpeg|jpg|png|webp/;
  const ext = allowed.test(path.extname(file.originalname).toLowerCase());
  // Some browsers send image/jpg instead of image/jpeg — be lenient
  const mime = /image\/(jpeg|jpg|png|webp)/.test(file.mimetype);
  if (ext || mime) return cb(null, true);
  cb(new Error('Only jpeg, jpg, png, webp images are allowed'));
};

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter,
});

module.exports = upload;

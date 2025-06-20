const express = require('express');
const multer = require('multer');
const router = express.Router();
const uploadService = require('../../services/uploadService');
const { authenticateToken, isVendor } = require('../../middleware/auth');
const { supabase } = require('../../config/supabase');

// Configuration de multer pour la mémoire
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Seules les images sont autorisées'), false);
    }
  },
});

// Toutes les routes nécessitent une authentification et le rôle vendeur
router.use(authenticateToken, isVendor);

// POST /api/admin/upload/images
router.post('/images', upload.array('images', 10), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'Aucune image fournie' });
    }

    console.log(`📤 Tentative de téléchargement de ${req.files.length} images`);

    // Vérifier que le bucket existe
    const { data: buckets, error: bucketError } = await supabase.storage.listBuckets();
    if (bucketError) {
      console.error('Erreur lors de la vérification des buckets:', bucketError);
      return res.status(500).json({ message: 'Erreur de configuration du stockage' });
    }

    const bucketExists = buckets.some(bucket => bucket.name === 'product-images');
    if (!bucketExists) {
      console.error('Bucket product-images non trouvé');
      return res.status(500).json({ 
        message: 'Configuration du stockage manquante. Veuillez exécuter le script de configuration Supabase.' 
      });
    }

    const imageUrls = [];
    for (const file of req.files) {
      try {
        console.log(`📁 Téléchargement de l'image: ${file.originalname} (${file.mimetype})`);
        const imageUrl = await uploadService.uploadProductImage(file, 'temp');
        imageUrls.push(imageUrl);
        console.log(`✅ Image téléchargée: ${imageUrl}`);
      } catch (uploadError) {
        console.error(`❌ Erreur lors du téléchargement de ${file.originalname}:`, uploadError);
        throw uploadError;
      }
    }

    console.log(`🎉 ${imageUrls.length} images téléchargées avec succès`);
    res.json({ urls: imageUrls });
  } catch (error) {
    console.error('Erreur lors du téléchargement:', error);
    res.status(500).json({ 
      message: error.message || 'Erreur lors du téléchargement des images',
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

module.exports = router; 
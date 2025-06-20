const { supabase } = require('../config/supabase');

class UploadService {
    // Télécharger une image de produit
    async uploadProductImage(file, productId) {
        try {
            // Générer un nom de fichier unique
            const timestamp = Date.now();
            const randomId = Math.random().toString(36).substring(2, 15);
            
            // Déterminer l'extension basée sur le mimetype
            let fileExt = 'jpg'; // par défaut
            if (file.mimetype) {
                if (file.mimetype.includes('png')) fileExt = 'png';
                else if (file.mimetype.includes('webp')) fileExt = 'webp';
                else if (file.mimetype.includes('gif')) fileExt = 'gif';
                else if (file.mimetype.includes('jpeg')) fileExt = 'jpg';
            }
            
            const fileName = `${productId}/${timestamp}_${randomId}.${fileExt}`;
            
            const { data, error } = await supabase.storage
                .from('product-images')
                .upload(fileName, file.buffer, {
                    contentType: file.mimetype,
                    cacheControl: '3600'
                });

            if (error) throw error;

            // Obtenir l'URL publique
            const { data: { publicUrl } } = supabase.storage
                .from('product-images')
                .getPublicUrl(fileName);

            return publicUrl;
        } catch (error) {
            throw new Error(`Erreur lors du téléchargement: ${error.message}`);
        }
    }

    // Supprimer une image de produit
    async deleteProductImage(imageUrl) {
        try {
            // Extraire le chemin du fichier de l'URL
            const urlParts = imageUrl.split('/');
            const fileName = urlParts[urlParts.length - 2] + '/' + urlParts[urlParts.length - 1];
            
            const { error } = await supabase.storage
                .from('product-images')
                .remove([fileName]);

            if (error) throw error;
            return true;
        } catch (error) {
            throw new Error(`Erreur lors de la suppression: ${error.message}`);
        }
    }

    // Télécharger plusieurs images pour un produit
    async uploadMultipleProductImages(files, productId) {
        try {
            const uploadPromises = files.map(file => this.uploadProductImage(file, productId));
            const imageUrls = await Promise.all(uploadPromises);
            return imageUrls;
        } catch (error) {
            throw new Error(`Erreur lors du téléchargement multiple: ${error.message}`);
        }
    }
}

module.exports = new UploadService(); 
-- Configuration du bucket de stockage pour les images de produits
-- À exécuter dans l'éditeur SQL de Supabase

-- Créer le bucket pour les images de produits
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true,
    5242880, -- 5MB max
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
);

-- Politique pour permettre aux utilisateurs authentifiés de télécharger des images
CREATE POLICY "Authenticated users can upload product images" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'product-images' 
    AND auth.role() = 'authenticated'
);

-- Politique pour permettre aux utilisateurs de voir toutes les images de produits
CREATE POLICY "Anyone can view product images" ON storage.objects
FOR SELECT USING (bucket_id = 'product-images');

-- Politique pour permettre aux vendeurs de supprimer leurs images
CREATE POLICY "Vendors can delete their product images" ON storage.objects
FOR DELETE USING (
    bucket_id = 'product-images' 
    AND auth.role() = 'authenticated'
);

-- Politique pour permettre aux vendeurs de mettre à jour leurs images
CREATE POLICY "Vendors can update their product images" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'product-images' 
    AND auth.role() = 'authenticated'
); 
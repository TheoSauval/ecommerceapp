-- Script pour insérer des données de test avec des catégories appropriées
-- Assurez-vous d'avoir d'abord créé un vendeur

-- 1. Créer un vendeur de test si nécessaire
INSERT INTO public.vendors (nom, user_id) 
VALUES ('Boutique Test', NULL)
ON CONFLICT DO NOTHING;

-- 2. Insérer des produits de test avec des catégories
INSERT INTO public.products (nom, prix_base, vendeur_id, description, categorie, marque, images, actif) VALUES
-- Manteaux
('Doudoune Hiver', 159.99, 1, 'Doudoune épaisse parfaite pour l''hiver, coupe moderne et tissu déperlant.', 'Manteau', 'FashionBrand', '["doudoune_hiver.jpg"]', true),
('Parka Imperméable', 189.99, 1, 'Parka imperméable avec capuche amovible et doublure chaude.', 'Manteau', 'OutdoorStyle', '["parka_imperm.jpg"]', true),
('Blouson Cuir', 299.99, 1, 'Blouson en cuir véritable, style vintage et durable.', 'Manteau', 'LeatherCraft', '["blouson_cuir.jpg"]', true),

-- T-Shirts
('T-Shirt Blanc Basique', 24.99, 1, 'T-shirt basique blanc en coton 100%, coupe droite et col rond.', 'T-Shirt', 'BasicWear', '["tshirt_blanc.jpg"]', true),
('T-Shirt Graphique', 34.99, 1, 'T-shirt avec design graphique original, coton bio.', 'T-Shirt', 'ArtWear', '["tshirt_graphique.jpg"]', true),
('T-Shirt Col V', 29.99, 1, 'T-shirt avec col en V, élégant et polyvalent.', 'T-Shirt', 'ElegantStyle', '["tshirt_colv.jpg"]', true),

-- Sweats
('Sweat Hoodie Gris', 59.99, 1, 'Sweat gris unisexe, coupe oversize, molleton intérieur doux.', 'Sweat', 'ComfortWear', '["sweat_gris.jpg"]', true),
('Sweat Zippé Noir', 69.99, 1, 'Sweat zippé noir, parfait pour le sport ou le quotidien.', 'Sweat', 'SportStyle', '["sweat_zippe.jpg"]', true),
('Sweat Capuche Rouge', 54.99, 1, 'Sweat avec capuche rouge, style streetwear.', 'Sweat', 'StreetFashion', '["sweat_rouge.jpg"]', true),

-- Pantalons
('Jeans Slim Fit', 89.99, 1, 'Jeans slim fit en denim stretch, confortable et tendance.', 'Pantalon', 'DenimCo', '["jeans_slim.jpg"]', true),
('Chino Beige', 79.99, 1, 'Chino beige classique, parfait pour toutes les occasions.', 'Pantalon', 'ClassicWear', '["chino_beige.jpg"]', true),
('Jogging Sport', 49.99, 1, 'Jogging de sport, léger et respirant.', 'Pantalon', 'SportWear', '["jogging_sport.jpg"]', true),

-- Chaussures
('Sneakers Blanc', 89.99, 1, 'Sneakers blanches classiques, polyvalentes et confortables.', 'Chaussure', 'ShoeBrand', '["sneakers_blanc.jpg"]', true),
('Baskets Sport', 119.99, 1, 'Baskets de sport haute performance, amorti optimal.', 'Chaussure', 'SportShoe', '["baskets_sport.jpg"]', true),
('Derbies Cuir', 149.99, 1, 'Derbies en cuir véritable, élégantes et durables.', 'Chaussure', 'LeatherShoe', '["derbies_cuir.jpg"]', true)
ON CONFLICT DO NOTHING;

-- 3. Insérer des variantes pour chaque produit (exemple pour quelques produits)
-- Doudoune Hiver
INSERT INTO public.product_variants (product_id, color_id, height_id, stock, prix, actif) VALUES
(1, 10, 2, 5, NULL, true), -- Noir, S
(1, 10, 3, 8, NULL, true), -- Noir, M
(1, 10, 4, 6, NULL, true), -- Noir, L
(1, 11, 2, 4, NULL, true), -- Blanc, S
(1, 11, 3, 7, NULL, true), -- Blanc, M
(1, 11, 4, 5, NULL, true); -- Blanc, L

-- T-Shirt Blanc Basique
INSERT INTO public.product_variants (product_id, color_id, height_id, stock, prix, actif) VALUES
(4, 11, 2, 15, NULL, true), -- Blanc, S
(4, 11, 3, 20, NULL, true), -- Blanc, M
(4, 11, 4, 18, NULL, true), -- Blanc, L
(4, 11, 5, 12, NULL, true); -- Blanc, XL

-- Sweat Hoodie Gris
INSERT INTO public.product_variants (product_id, color_id, height_id, stock, prix, actif) VALUES
(7, 9, 3, 10, NULL, true), -- Gris, M
(7, 9, 4, 12, NULL, true), -- Gris, L
(7, 9, 5, 8, NULL, true), -- Gris, XL
(7, 10, 3, 9, NULL, true), -- Noir, M
(7, 10, 4, 11, NULL, true), -- Noir, L
(7, 10, 5, 7, NULL, true); -- Noir, XL

-- Jeans Slim Fit
INSERT INTO public.product_variants (product_id, color_id, height_id, stock, prix, actif) VALUES
(10, 10, 2, 6, NULL, true), -- Noir, S
(10, 10, 3, 8, NULL, true), -- Noir, M
(10, 10, 4, 7, NULL, true), -- Noir, L
(10, 10, 5, 5, NULL, true); -- Noir, XL

-- Sneakers Blanc
INSERT INTO public.product_variants (product_id, color_id, height_id, stock, prix, actif) VALUES
(13, 11, 2, 8, NULL, true), -- Blanc, S
(13, 11, 3, 12, NULL, true), -- Blanc, M
(13, 11, 4, 10, NULL, true), -- Blanc, L
(13, 11, 5, 6, NULL, true); -- Blanc, XL

-- 4. Vérifier les catégories créées
SELECT 
    categorie,
    COUNT(*) as nombre_produits,
    COUNT(DISTINCT pv.id) as nombre_variantes
FROM public.products p
LEFT JOIN public.product_variants pv ON p.id = pv.product_id AND pv.actif = true AND pv.stock > 0
WHERE p.actif = true 
    AND p.categorie IS NOT NULL 
    AND p.categorie != ''
GROUP BY categorie
ORDER BY nombre_produits DESC; 
-- Script de diagnostic et correction des catégories
-- Vérifier les catégories existantes dans la base de données

-- 1. Voir toutes les catégories existantes
SELECT 
    categorie,
    COUNT(*) as nombre_produits,
    MIN(created_at) as premier_produit,
    MAX(created_at) as dernier_produit
FROM public.products 
WHERE actif = true 
    AND categorie IS NOT NULL 
    AND categorie != ''
GROUP BY categorie
ORDER BY nombre_produits DESC;

-- 2. Voir les produits sans catégorie
SELECT 
    id,
    nom,
    categorie,
    created_at
FROM public.products 
WHERE actif = true 
    AND (categorie IS NULL OR categorie = '')
ORDER BY created_at DESC;

-- 3. Voir tous les produits avec leurs catégories
SELECT 
    id,
    nom,
    categorie,
    prix_base,
    actif,
    created_at
FROM public.products 
WHERE actif = true
ORDER BY created_at DESC
LIMIT 20;

-- 4. Compter le total de produits actifs
SELECT 
    COUNT(*) as total_produits_actifs,
    COUNT(CASE WHEN categorie IS NOT NULL AND categorie != '' THEN 1 END) as produits_avec_categorie,
    COUNT(CASE WHEN categorie IS NULL OR categorie = '' THEN 1 END) as produits_sans_categorie
FROM public.products 
WHERE actif = true;

-- 5. Si vous voulez ajouter des catégories manquantes (à adapter selon vos besoins)
-- UPDATE public.products 
-- SET categorie = 'Vêtements'
-- WHERE actif = true 
--     AND (categorie IS NULL OR categorie = '')
--     AND nom ILIKE '%t-shirt%' OR nom ILIKE '%sweat%' OR nom ILIKE '%manteau%';

-- 6. Vérifier les catégories avec des espaces en trop
SELECT 
    categorie,
    LENGTH(categorie) as longueur,
    COUNT(*) as nombre_produits
FROM public.products 
WHERE actif = true 
    AND categorie IS NOT NULL
GROUP BY categorie
HAVING LENGTH(categorie) != LENGTH(TRIM(categorie))
ORDER BY nombre_produits DESC;

-- 7. Nettoyer les catégories avec des espaces en trop
-- UPDATE public.products 
-- SET categorie = TRIM(categorie)
-- WHERE actif = true 
--     AND categorie IS NOT NULL
--     AND LENGTH(categorie) != LENGTH(TRIM(categorie));

-- 8. Standardiser les catégories (exemple)
-- UPDATE public.products 
-- SET categorie = 'Manteau'
-- WHERE actif = true 
--     AND categorie ILIKE '%manteau%'
--     AND categorie != 'Manteau';

-- UPDATE public.products 
-- SET categorie = 'T-Shirt'
-- WHERE actif = true 
--     AND categorie ILIKE '%t-shirt%'
--     AND categorie != 'T-Shirt';

-- UPDATE public.products 
-- SET categorie = 'Sweat'
-- WHERE actif = true 
--     AND categorie ILIKE '%sweat%'
--     AND categorie != 'Sweat'; 
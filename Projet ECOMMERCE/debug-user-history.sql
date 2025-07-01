-- Script pour vérifier l'historique utilisateur et comprendre le problème
-- Exécutez ce script pour voir exactement ce qui se passe

-- 1. Vérifier l'historique complet de l'utilisateur
SELECT 
    'Historique complet' as check_type,
    h.id,
    h.user_id,
    h.product_id,
    p.nom as product_name,
    p.categorie,
    h.view_duration,
    h.viewed_at,
    EXTRACT(EPOCH FROM (NOW() - h.viewed_at))/60 as minutes_ago
FROM history h
JOIN products p ON p.id = h.product_id
WHERE h.user_id = auth.uid()
ORDER BY h.viewed_at DESC;

-- 2. Vérifier les catégories consultées par l'utilisateur
WITH user_categories AS (
    SELECT 
        p.categorie as user_categorie,
        COUNT(*) as view_count,
        COALESCE(SUM(h.view_duration), 0) as total_duration
    FROM history h
    JOIN products p ON p.id = h.product_id
    WHERE h.user_id = auth.uid()
    AND h.viewed_at >= NOW() - INTERVAL '30 days'
    AND p.categorie IS NOT NULL
    GROUP BY p.categorie
)
SELECT 
    'Catégories utilisateur' as check_type,
    user_categorie,
    view_count,
    total_duration,
    (view_count * 0.3 + total_duration / 60.0 * 0.7) as calculated_score
FROM user_categories
ORDER BY calculated_score DESC;

-- 3. Vérifier pourquoi category_score est 0
SELECT 
    'Debug category_score' as check_type,
    p.id as product_id,
    p.nom,
    p.categorie as product_categorie,
    uc.user_categorie,
    uc.view_count,
    uc.total_duration,
    CASE 
        WHEN uc.view_count > 0 THEN 
            (uc.view_count * 0.3 + uc.total_duration / 60.0 * 0.7) * 0.7
        ELSE 
            0
    END as category_score
FROM products p
LEFT JOIN (
    SELECT 
        p.categorie as user_categorie,
        COUNT(*) as view_count,
        COALESCE(SUM(h.view_duration), 0) as total_duration
    FROM history h
    JOIN products p ON p.id = h.product_id
    WHERE h.user_id = auth.uid()
    AND h.viewed_at >= NOW() - INTERVAL '30 days'
    AND p.categorie IS NOT NULL
    GROUP BY p.categorie
) uc ON uc.user_categorie = p.categorie
WHERE p.actif = true
AND p.id NOT IN (
    SELECT DISTINCT h3.product_id FROM history h3
    WHERE h3.user_id = auth.uid()
)
AND EXISTS (
    SELECT 1 FROM product_variants pv 
    WHERE pv.product_id = p.id AND pv.stock > 0
)
ORDER BY category_score DESC;

-- 4. Vérifier les dates de création des produits
SELECT 
    'Dates création produits' as check_type,
    p.id,
    p.nom,
    p.categorie,
    p.created_at,
    CASE 
        WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 'Nouveau (7 jours)'
        WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 'Récent (30 jours)'
        ELSE 'Ancien'
    END as age_category
FROM products p
WHERE p.actif = true
AND p.id NOT IN (
    SELECT DISTINCT h3.product_id FROM history h3
    WHERE h3.user_id = auth.uid()
)
AND EXISTS (
    SELECT 1 FROM product_variants pv 
    WHERE pv.product_id = p.id AND pv.stock > 0
)
ORDER BY p.created_at DESC; 
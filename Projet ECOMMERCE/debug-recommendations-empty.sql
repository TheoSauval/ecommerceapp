-- Script de diagnostic pour comprendre pourquoi les recommandations sont vides
-- Exécutez ce script étape par étape

-- 1. Vérifier si l'utilisateur a un historique
SELECT 
    'Historique utilisateur' as check_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT product_id) as unique_products,
    COUNT(DISTINCT p.categorie) as unique_categories
FROM history h
JOIN products p ON p.id = h.product_id
WHERE h.user_id = auth.uid();

-- 2. Vérifier les catégories consultées
SELECT 
    'Catégories consultées' as check_type,
    p.categorie,
    COUNT(*) as view_count,
    COALESCE(SUM(h.view_duration), 0) as total_duration
FROM history h
JOIN products p ON p.id = h.product_id
WHERE h.user_id = auth.uid()
AND h.viewed_at >= NOW() - INTERVAL '30 days'
AND p.categorie IS NOT NULL
GROUP BY p.categorie
ORDER BY view_count DESC;

-- 3. Vérifier les produits disponibles (non consultés)
SELECT 
    'Produits disponibles' as check_type,
    COUNT(*) as total_products,
    COUNT(DISTINCT p.categorie) as unique_categories
FROM products p
WHERE p.actif = true
AND p.id NOT IN (
    SELECT DISTINCT h3.product_id FROM history h3
    WHERE h3.user_id = auth.uid()
)
AND EXISTS (
    SELECT 1 FROM product_variants pv 
    WHERE pv.product_id = p.id AND pv.stock > 0
);

-- 4. Vérifier les produits par catégorie
SELECT 
    'Produits par catégorie' as check_type,
    p.categorie,
    COUNT(*) as available_products
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
GROUP BY p.categorie
ORDER BY available_products DESC;

-- 5. Vérifier la popularité des produits
SELECT 
    'Popularité des produits' as check_type,
    p.nom,
    p.categorie,
    COUNT(h.id) as global_views
FROM products p
LEFT JOIN history h ON h.product_id = p.id
WHERE h.viewed_at >= NOW() - INTERVAL '30 days'
AND p.actif = true
AND p.id NOT IN (
    SELECT DISTINCT h3.product_id FROM history h3
    WHERE h3.user_id = auth.uid()
)
AND EXISTS (
    SELECT 1 FROM product_variants pv 
    WHERE pv.product_id = p.id AND pv.stock > 0
)
GROUP BY p.id, p.nom, p.categorie
ORDER BY global_views DESC
LIMIT 10;

-- 6. Test de la fonction de recommandations avec debug
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
),
product_stats AS (
    SELECT 
        h.product_id,
        COUNT(*) as global_views
    FROM history h
    WHERE h.viewed_at >= NOW() - INTERVAL '30 days'
    GROUP BY h.product_id
),
recommended_products AS (
    SELECT 
        p.id as product_id,
        p.nom,
        p.categorie,
        p.marque,
        -- Debug: afficher les scores individuels
        COALESCE((uc.view_count * 0.3 + uc.total_duration / 60.0 * 0.7), 0) * 0.7 as category_score,
        COALESCE(ps.global_views / 100.0, 0) * 0.2 as popularity_score,
        CASE 
            WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 1.0
            WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 0.5
            ELSE 0.1
        END as recency_score,
        -- Score final
        COALESCE((uc.view_count * 0.3 + uc.total_duration / 60.0 * 0.7), 0) * 0.7 +
        COALESCE(ps.global_views / 100.0, 0) * 0.2 +
        CASE 
            WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 1.0
            WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 0.5
            ELSE 0.1
        END as final_score,
        -- Raison
        CASE 
            WHEN uc.view_count > 0 THEN 'Basé sur vos préférences de catégorie'
            WHEN ps.global_views > 10 THEN 'Produit populaire'
            WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 'Nouveau produit'
            ELSE 'Recommandation générale'
        END as reason
    FROM products p
    LEFT JOIN user_categories uc ON uc.user_categorie = p.categorie
    LEFT JOIN product_stats ps ON ps.product_id = p.id
    WHERE p.actif = true
    AND p.id NOT IN (
        SELECT DISTINCT h3.product_id FROM history h3
        WHERE h3.user_id = auth.uid()
    )
    AND EXISTS (
        SELECT 1 FROM product_variants pv 
        WHERE pv.product_id = p.id AND pv.stock > 0
    )
)
SELECT 
    'Recommandations avec scores' as check_type,
    product_id,
    nom,
    categorie,
    category_score,
    popularity_score,
    recency_score,
    final_score,
    reason
FROM recommended_products
ORDER BY final_score DESC
LIMIT 10; 
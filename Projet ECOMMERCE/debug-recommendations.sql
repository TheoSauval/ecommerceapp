-- Script de debug pour analyser les recommandations
-- Exécutez ce script après avoir consulté le sweat Adidas

-- 1. Vérifier l'historique de l'utilisateur
SELECT 
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

-- 2. Vérifier les statistiques de catégorie pour l'utilisateur
WITH user_category_stats AS (
    SELECT 
        p.categorie,
        COUNT(*) as total_views,
        COALESCE(SUM(h.view_duration), 0) as total_duration,
        AVG(h.view_duration) as avg_duration
    FROM history h
    JOIN products p ON p.id = h.product_id
    WHERE h.user_id = auth.uid()
    AND h.viewed_at >= NOW() - INTERVAL '30 days'
    AND p.categorie IS NOT NULL
    GROUP BY p.categorie
)
SELECT 
    categorie,
    total_views,
    total_duration,
    avg_duration,
    (total_views * 0.3 + (total_duration / 60.0) * 0.7) as preference_score
FROM user_category_stats
ORDER BY preference_score DESC;

-- 3. Vérifier la popularité des produits
SELECT 
    p.id,
    p.nom,
    p.categorie,
    COUNT(h.id) as total_views,
    AVG(h.view_duration) as avg_duration
FROM products p
LEFT JOIN history h ON h.product_id = p.id
WHERE h.viewed_at >= NOW() - INTERVAL '30 days'
GROUP BY p.id, p.nom, p.categorie
ORDER BY total_views DESC
LIMIT 10;

-- 4. Simuler l'algorithme de recommandations pour voir les scores
WITH user_category_stats AS (
    SELECT 
        p.categorie,
        COUNT(*) as total_views,
        COALESCE(SUM(h.view_duration), 0) as total_duration,
        AVG(h.view_duration) as avg_duration
    FROM history h
    JOIN products p ON p.id = h.product_id
    WHERE h.user_id = auth.uid()
    AND h.viewed_at >= NOW() - INTERVAL '30 days'
    AND p.categorie IS NOT NULL
    GROUP BY p.categorie
),
user_preferences AS (
    SELECT 
        categorie,
        total_views,
        total_duration,
        avg_duration,
        (total_views * 0.3 + (total_duration / 60.0) * 0.7) as preference_score
    FROM user_category_stats
),
product_popularity AS (
    SELECT 
        h.product_id,
        COUNT(*) as total_views,
        AVG(h.view_duration) as avg_duration
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
        -- Score de catégorie (50% du score total)
        COALESCE(up.preference_score, 0) * 0.5 as category_score,
        -- Score de popularité (30% du score total)
        COALESCE(pp.total_views / 100.0, 0) * 0.3 as popularity_score,
        -- Score de récence (20% du score total)
        CASE 
            WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 10
            WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 5
            ELSE 1
        END * 0.2 as recency_score,
        -- Score final
        COALESCE(up.preference_score, 0) * 0.5 +
        COALESCE(pp.total_views / 100.0, 0) * 0.3 +
        CASE 
            WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 10
            WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 5
            ELSE 1
        END * 0.2 as final_score,
        -- Raison
        CASE 
            WHEN up.preference_score > 0 THEN 'Basé sur vos préférences de catégorie'
            WHEN pp.total_views > 10 THEN 'Produit populaire'
            WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 'Nouveau produit'
            ELSE 'Recommandation générale'
        END as reason
    FROM products p
    LEFT JOIN user_preferences up ON up.categorie = p.categorie
    LEFT JOIN product_popularity pp ON pp.product_id = p.id
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
    product_id,
    nom,
    categorie,
    marque,
    category_score,
    popularity_score,
    recency_score,
    final_score,
    reason
FROM recommended_products
ORDER BY final_score DESC
LIMIT 10; 
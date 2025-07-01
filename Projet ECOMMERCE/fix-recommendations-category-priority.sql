-- Script pour prioriser les catégories consultées par l'utilisateur
-- Version qui donne plus d'importance aux préférences de catégorie

-- 1. Supprimer les fonctions existantes
DROP FUNCTION IF EXISTS get_recommendations(UUID, INTEGER);

-- 2. Fonction améliorée qui priorise les catégories consultées
CREATE OR REPLACE FUNCTION get_recommendations(user_id_param UUID, limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    product_id INTEGER,
    nom TEXT,
    prix_base DECIMAL(10, 2),
    description TEXT,
    categorie TEXT,
    marque TEXT,
    images JSONB,
    score_recommendation DECIMAL(10, 4),
    reason TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH user_category_stats AS (
        -- Statistiques détaillées par catégorie
        SELECT 
            p.categorie,
            COUNT(*) as total_views,
            COALESCE(SUM(h.view_duration), 0) as total_duration,
            AVG(h.view_duration) as avg_duration
        FROM history h
        JOIN products p ON p.id = h.product_id
        WHERE h.user_id = user_id_param
        AND h.viewed_at >= NOW() - INTERVAL '30 days'
        AND p.categorie IS NOT NULL
        GROUP BY p.categorie
    ),
    user_preferences AS (
        -- Calcul des préférences utilisateur
        SELECT 
            ucs.categorie,
            ucs.total_views,
            ucs.total_duration,
            ucs.avg_duration,
            -- Score de préférence basé sur vues et durée
            (ucs.total_views * 0.3 + (ucs.total_duration / 60.0) * 0.7) as preference_score
        FROM user_category_stats ucs
    ),
    product_popularity AS (
        -- Popularité globale des produits
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
            p.prix_base,
            p.description,
            p.categorie,
            p.marque,
            p.images,
            -- Score de catégorie (70% du score total) - PRIORITÉ ÉLEVÉE
            COALESCE(up.preference_score, 0) * 0.7 as category_score,
            -- Score de popularité (20% du score total) - RÉDUIT
            COALESCE(pp.total_views / 100.0, 0) * 0.2 as popularity_score,
            -- Score de récence (10% du score total) - RÉDUIT
            CASE 
                WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 10
                WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 5
                ELSE 1
            END * 0.1 as recency_score,
            -- Score final avec priorité aux catégories
            COALESCE(up.preference_score, 0) * 0.7 +
            COALESCE(pp.total_views / 100.0, 0) * 0.2 +
            CASE 
                WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 10
                WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 5
                ELSE 1
            END * 0.1 as final_score,
            -- Raison de la recommandation
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
            WHERE h3.user_id = user_id_param
        )
        AND EXISTS (
            SELECT 1 FROM product_variants pv 
            WHERE pv.product_id = p.id AND pv.stock > 0
        )
    )
    SELECT 
        rp.product_id,
        rp.nom,
        rp.prix_base,
        rp.description,
        rp.categorie,
        rp.marque,
        rp.images,
        rp.final_score as score_recommendation,
        rp.reason
    FROM recommended_products rp
    ORDER BY rp.final_score DESC
    LIMIT limit_count;
END;
$$;

-- 3. Vérification finale
SELECT 'Système de recommandations avec priorité catégorie créé avec succès' as status; 
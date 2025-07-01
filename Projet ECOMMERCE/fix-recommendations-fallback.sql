-- Script pour corriger les recommandations vides
-- Version avec fallback pour les nouveaux utilisateurs

-- 1. Supprimer les fonctions existantes
DROP FUNCTION IF EXISTS get_recommendations(UUID, INTEGER);

-- 2. Fonction avec fallback pour les nouveaux utilisateurs
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
    WITH user_categories AS (
        -- Catégories consultées par l'utilisateur
        SELECT 
            p.categorie as user_categorie,
            COUNT(*) as view_count,
            COALESCE(SUM(h.view_duration), 0) as total_duration
        FROM history h
        JOIN products p ON p.id = h.product_id
        WHERE h.user_id = user_id_param
        AND h.viewed_at >= NOW() - INTERVAL '30 days'
        AND p.categorie IS NOT NULL
        GROUP BY p.categorie
    ),
    product_stats AS (
        -- Statistiques de popularité des produits
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
            p.prix_base,
            p.description,
            p.categorie,
            p.marque,
            p.images,
            -- Score de catégorie (70% du score total) ou fallback
            CASE 
                WHEN uc.view_count > 0 THEN 
                    (uc.view_count * 0.3 + uc.total_duration / 60.0 * 0.7) * 0.7
                ELSE 
                    -- Fallback: score basé sur la récence pour les nouveaux utilisateurs
                    CASE 
                        WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 0.7
                        WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 0.5
                        ELSE 0.3
                    END
            END as category_score,
            -- Score de popularité (20% du score total)
            COALESCE(ps.global_views / 100.0, 0) * 0.2 as popularity_score,
            -- Score de récence (10% du score total)
            CASE 
                WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 0.1
                WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 0.05
                ELSE 0.01
            END as recency_score,
            -- Score final avec fallback
            CASE 
                WHEN uc.view_count > 0 THEN 
                    -- Utilisateur avec historique
                    (uc.view_count * 0.3 + uc.total_duration / 60.0 * 0.7) * 0.7 +
                    COALESCE(ps.global_views / 100.0, 0) * 0.2 +
                    CASE 
                        WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 0.1
                        WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 0.05
                        ELSE 0.01
                    END
                ELSE 
                    -- Nouvel utilisateur: priorité à la popularité et récence
                    COALESCE(ps.global_views / 100.0, 0) * 0.5 +
                    CASE 
                        WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 0.4
                        WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 0.3
                        ELSE 0.1
                    END
            END as final_score,
            -- Raison de la recommandation
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
SELECT 'Système de recommandations avec fallback créé avec succès' as status; 
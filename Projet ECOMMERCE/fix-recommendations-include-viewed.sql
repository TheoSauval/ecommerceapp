-- Script pour corriger les recommandations en incluant les produits déjà consultés
-- Version qui montre tous les produits avec des scores différents

-- 1. Supprimer les fonctions existantes
DROP FUNCTION IF EXISTS get_recommendations(UUID, INTEGER);

-- 2. Fonction corrigée qui inclut les produits déjà consultés
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
    WITH user_history AS (
        -- Historique complet de l'utilisateur
        SELECT 
            p.categorie,
            COUNT(*) as view_count,
            COALESCE(SUM(h.view_duration), 0) as total_duration
        FROM history h
        JOIN products p ON p.id = h.product_id
        WHERE h.user_id = user_id_param
        AND h.viewed_at >= NOW() - INTERVAL '30 days'
        AND p.categorie IS NOT NULL
        GROUP BY p.categorie
    ),
    user_product_history AS (
        -- Historique des produits consultés par l'utilisateur
        SELECT 
            h.product_id,
            COUNT(*) as user_view_count,
            COALESCE(SUM(h.view_duration), 0) as user_total_duration
        FROM history h
        WHERE h.user_id = user_id_param
        AND h.viewed_at >= NOW() - INTERVAL '30 days'
        GROUP BY h.product_id
    ),
    product_popularity AS (
        -- Popularité globale des produits
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
            -- Score de catégorie basé sur l'historique utilisateur
            CASE 
                WHEN uh.view_count > 0 THEN 
                    -- L'utilisateur a consulté cette catégorie
                    (uh.view_count * 0.3 + uh.total_duration / 60.0 * 0.7) * 0.6
                ELSE 
                    -- L'utilisateur n'a pas consulté cette catégorie
                    0
            END as category_score,
            -- Score de popularité
            COALESCE(pp.global_views / 50.0, 0) * 0.2 as popularity_score,
            -- Score de récence
            CASE 
                WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 0.1
                WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 0.05
                ELSE 0.02
            END as recency_score,
            -- Score de consultation personnelle (si déjà consulté)
            CASE 
                WHEN uph.user_view_count > 0 THEN 
                    -- Produit déjà consulté par l'utilisateur
                    (uph.user_view_count * 0.2 + uph.user_total_duration / 60.0 * 0.8) * 0.2
                ELSE 
                    -- Produit non consulté
                    0
            END as personal_score,
            -- Score final
            CASE 
                WHEN uh.view_count > 0 THEN 
                    -- Utilisateur avec historique dans cette catégorie
                    (uh.view_count * 0.3 + uh.total_duration / 60.0 * 0.7) * 0.6 +
                    COALESCE(pp.global_views / 50.0, 0) * 0.2 +
                    CASE 
                        WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 0.1
                        WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 0.05
                        ELSE 0.02
                    END +
                    CASE 
                        WHEN uph.user_view_count > 0 THEN 
                            (uph.user_view_count * 0.2 + uph.user_total_duration / 60.0 * 0.8) * 0.2
                        ELSE 
                            0
                    END
                ELSE 
                    -- Utilisateur sans historique dans cette catégorie
                    COALESCE(pp.global_views / 50.0, 0) * 0.5 +
                    CASE 
                        WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 0.3
                        WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 0.2
                        ELSE 0.1
                    END +
                    CASE 
                        WHEN uph.user_view_count > 0 THEN 
                            (uph.user_view_count * 0.2 + uph.user_total_duration / 60.0 * 0.8) * 0.2
                        ELSE 
                            0
                    END
            END as final_score,
            -- Raison de la recommandation
            CASE 
                WHEN uph.user_view_count > 0 THEN 'Produit que vous avez consulté'
                WHEN uh.view_count > 0 THEN 'Basé sur vos préférences de catégorie'
                WHEN pp.global_views > 5 THEN 'Produit populaire'
                WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 'Nouveau produit'
                ELSE 'Recommandation générale'
            END as reason
        FROM products p
        LEFT JOIN user_history uh ON uh.categorie = p.categorie
        LEFT JOIN user_product_history uph ON uph.product_id = p.id
        LEFT JOIN product_popularity pp ON pp.product_id = p.id
        WHERE p.actif = true
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
SELECT 'Système de recommandations corrigé créé avec succès' as status; 
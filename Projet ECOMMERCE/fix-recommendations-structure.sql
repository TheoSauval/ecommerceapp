-- Script de correction pour la structure de la fonction get_recommendations
-- Appliquez ce script dans Supabase SQL Editor

-- Supprimer la fonction existante
DROP FUNCTION IF EXISTS public.get_recommendations(UUID, INTEGER);

-- Recréer la fonction avec la structure corrigée
CREATE OR REPLACE FUNCTION public.get_recommendations(user_id_param UUID, limit_count INTEGER DEFAULT 10)
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
DECLARE
    user_categories RECORD;
    category_weight DECIMAL(10, 4) := 0.0;
    duration_weight DECIMAL(10, 4) := 0.0;
    product_weight DECIMAL(10, 4) := 0.0;
BEGIN
    -- Récupérer les préférences de catégories de l'utilisateur
    SELECT * INTO user_categories FROM public.get_user_category_preferences(user_id_param) LIMIT 1;
    
    RETURN QUERY
    WITH user_category_prefs AS (
        SELECT 
            p.categorie,
            COUNT(*) as view_count,
            SUM(h.view_duration) as total_duration,
            AVG(h.view_duration) as avg_duration
        FROM public.history h
        JOIN public.products p ON p.id = h.product_id
        WHERE h.user_id = user_id_param
        AND h.viewed_at >= NOW() - INTERVAL '30 days'
        AND p.categorie IS NOT NULL
        GROUP BY p.categorie
    ),
    category_scores AS (
        SELECT 
            p.categorie,
            COALESCE(ucp.view_count, 0) * 0.4 + 
            COALESCE(ucp.total_duration, 0) * 0.6 as category_score
        FROM public.products p
        LEFT JOIN user_category_prefs ucp ON ucp.categorie = p.categorie
        WHERE p.actif = true
        GROUP BY p.categorie, ucp.view_count, ucp.total_duration
    ),
    product_scores AS (
        SELECT 
            h.product_id,
            COUNT(*) as view_count,
            SUM(h.view_duration) as total_duration
        FROM public.history h
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
            -- Score basé sur les catégories (40%)
            COALESCE(cs.category_score, 0) * 0.4 +
            -- Score basé sur la durée de consultation (35%)
            COALESCE(ps.total_duration, 0) * 0.35 +
            -- Score basé sur le nombre de vues du produit (25%)
            COALESCE(ps.view_count, 0) * 0.25 as final_score,
            CASE 
                WHEN cs.category_score > 0 THEN 'Catégorie préférée'
                WHEN ps.total_duration > 0 THEN 'Produit populaire'
                ELSE 'Nouveau produit'
            END as reason
        FROM public.products p
        LEFT JOIN category_scores cs ON cs.categorie = p.categorie
        LEFT JOIN product_scores ps ON ps.product_id = p.id
        WHERE p.actif = true
        AND p.id NOT IN (
            SELECT DISTINCT h3.product_id FROM public.history h3
            WHERE h3.user_id = user_id_param
        )
        AND EXISTS (
            SELECT 1 FROM public.product_variants pv 
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

-- Vérification
SELECT 'Fonction get_recommendations corrigée avec succès' as status; 
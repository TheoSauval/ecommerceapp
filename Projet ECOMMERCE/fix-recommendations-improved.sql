-- Script SQL amélioré pour le système de recommandations
-- Version qui prend mieux en compte la durée et les catégories

-- 1. Supprimer les fonctions existantes
DROP FUNCTION IF EXISTS add_product_view(UUID, INTEGER);
DROP FUNCTION IF EXISTS update_view_duration(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_recommendations(UUID, INTEGER);
DROP FUNCTION IF EXISTS get_user_category_preferences(UUID);
DROP FUNCTION IF EXISTS get_user_analytics(UUID);

-- 2. Fonction améliorée pour ajouter une consultation
CREATE OR REPLACE FUNCTION add_product_view(user_id_param UUID, product_id_param INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insérer une nouvelle consultation avec durée initiale de 10 secondes
    INSERT INTO history (user_id, product_id, view_duration)
    VALUES (user_id_param, product_id_param, 10);
END;
$$;

-- 3. Fonction améliorée pour mettre à jour la durée
CREATE OR REPLACE FUNCTION update_view_duration(user_id_param UUID, product_id_param INTEGER, duration_seconds INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE history 
    SET view_duration = duration_seconds,
        viewed_at = NOW()
    WHERE id = (
        SELECT id 
        FROM history 
        WHERE user_id = user_id_param 
          AND product_id = product_id_param
          AND viewed_at::date = CURRENT_DATE
        ORDER BY viewed_at DESC
        LIMIT 1
    );
END;
$$;

-- 4. Fonction améliorée pour obtenir les recommandations
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
            categorie,
            total_views,
            total_duration,
            avg_duration,
            -- Score de préférence basé sur vues et durée
            (total_views * 0.3 + (total_duration / 60.0) * 0.7) as preference_score
        FROM user_category_stats
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
            -- Score de catégorie (50% du score total)
            COALESCE(up.preference_score, 0) * 0.5 +
            -- Score de popularité (30% du score total)
            COALESCE(pp.total_views / 100.0, 0) * 0.3 +
            -- Score de récence (20% du score total)
            CASE 
                WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 10
                WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 5
                ELSE 1
            END * 0.2 as final_score,
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

-- 5. Fonction améliorée pour obtenir les préférences de catégories
CREATE OR REPLACE FUNCTION get_user_category_preferences(user_id_param UUID)
RETURNS TABLE (
    categorie TEXT,
    total_views INTEGER,
    total_duration INTEGER,
    avg_duration DECIMAL(10, 2),
    category_score DECIMAL(10, 4)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.categorie,
        COUNT(*) as total_views,
        COALESCE(SUM(h.view_duration), 0) as total_duration,
        AVG(h.view_duration) as avg_duration,
        -- Score amélioré : 30% vues + 70% durée
        (COUNT(*) * 0.3 + COALESCE(SUM(h.view_duration), 0) / 60.0 * 0.7) as category_score
    FROM history h
    JOIN products p ON p.id = h.product_id
    WHERE h.user_id = user_id_param
    AND h.viewed_at >= NOW() - INTERVAL '30 days'
    AND p.categorie IS NOT NULL
    GROUP BY p.categorie
    ORDER BY category_score DESC;
END;
$$;

-- 6. Fonction améliorée pour obtenir les analytics
CREATE OR REPLACE FUNCTION get_user_analytics(user_id_param UUID)
RETURNS TABLE (
    total_views INTEGER,
    total_duration INTEGER,
    favorite_category TEXT,
    favorite_product_id INTEGER,
    avg_session_duration DECIMAL(10, 2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH user_stats AS (
        SELECT 
            COUNT(*) as total_views,
            COALESCE(SUM(view_duration), 0) as total_duration,
            AVG(view_duration) as avg_duration
        FROM history
        WHERE user_id = user_id_param
    ),
    favorite_category AS (
        SELECT p.categorie
        FROM history h
        JOIN products p ON p.id = h.product_id
        WHERE h.user_id = user_id_param
        GROUP BY p.categorie
        ORDER BY (COUNT(*) * 0.3 + SUM(h.view_duration) * 0.7) DESC
        LIMIT 1
    ),
    favorite_product AS (
        SELECT h.product_id
        FROM history h
        WHERE h.user_id = user_id_param
        GROUP BY h.product_id
        ORDER BY (COUNT(*) * 0.3 + SUM(h.view_duration) * 0.7) DESC
        LIMIT 1
    )
    SELECT 
        us.total_views,
        us.total_duration,
        fc.categorie as favorite_category,
        fp.product_id as favorite_product_id,
        us.avg_duration as avg_session_duration
    FROM user_stats us
    LEFT JOIN favorite_category fc ON true
    LEFT JOIN favorite_product fp ON true;
END;
$$;

-- 7. Vérification finale
SELECT 'Système de recommandations amélioré créé avec succès' as status; 
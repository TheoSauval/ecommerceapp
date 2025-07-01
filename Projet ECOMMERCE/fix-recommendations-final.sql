-- Script SQL final pour corriger tous les problèmes de recommandations
-- Version qui correspond exactement aux appels du backend

-- 1. Supprimer toutes les fonctions existantes
DROP FUNCTION IF EXISTS add_view(UUID, UUID);
DROP FUNCTION IF EXISTS update_view_duration(UUID, UUID, INTEGER);
DROP FUNCTION IF EXISTS get_category_preferences(UUID);
DROP FUNCTION IF EXISTS get_recommendations(INTEGER, UUID);
DROP FUNCTION IF EXISTS get_user_analytics(UUID);
DROP FUNCTION IF EXISTS get_user_history(INTEGER, UUID);
DROP FUNCTION IF EXISTS public.add_product_view(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.get_recommendations(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.update_view_duration(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.get_user_category_preferences(UUID);
DROP FUNCTION IF EXISTS public.get_user_analytics(UUID);

-- 2. Supprimer les politiques RLS existantes
DROP POLICY IF EXISTS "Users can view their own history" ON history;
DROP POLICY IF EXISTS "Users can insert their own history" ON history;
DROP POLICY IF EXISTS "Users can update their own history" ON history;
DROP POLICY IF EXISTS "Users can delete their own history" ON history;
DROP POLICY IF EXISTS "Users can view own history" ON public.history;
DROP POLICY IF EXISTS "Users can insert own history" ON public.history;
DROP POLICY IF EXISTS "Users can update own history" ON public.history;
DROP POLICY IF EXISTS "Users can delete own history" ON public.history;

-- 3. Supprimer les index existants
DROP INDEX IF EXISTS idx_history_user_product;
DROP INDEX IF EXISTS idx_history_user_date;
DROP INDEX IF EXISTS idx_history_product;
DROP INDEX IF EXISTS idx_history_user_id;
DROP INDEX IF EXISTS idx_history_product_id;
DROP INDEX IF EXISTS idx_history_viewed_at;
DROP INDEX IF EXISTS idx_history_view_duration;
DROP INDEX IF EXISTS idx_history_user_product_date;

-- 4. Supprimer la table history si elle existe
DROP TABLE IF EXISTS history CASCADE;
DROP TABLE IF EXISTS public.history CASCADE;

-- 5. Créer la table history
CREATE TABLE history (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_duration INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Créer les index optimisés
CREATE INDEX idx_history_user_id ON history(user_id);
CREATE INDEX idx_history_product_id ON history(product_id);
CREATE INDEX idx_history_viewed_at ON history(viewed_at);
CREATE INDEX idx_history_user_product ON history(user_id, product_id);

-- 7. Activer RLS
ALTER TABLE history ENABLE ROW LEVEL SECURITY;

-- 8. Créer les politiques RLS
CREATE POLICY "Users can view their own history" ON history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own history" ON history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own history" ON history
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own history" ON history
    FOR DELETE USING (auth.uid() = user_id);

-- 9. Fonction pour ajouter une consultation (correspond au backend)
CREATE OR REPLACE FUNCTION add_product_view(user_id_param UUID, product_id_param INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insérer une nouvelle consultation
    INSERT INTO history (user_id, product_id, view_duration)
    VALUES (user_id_param, product_id_param, 60); -- Commencer avec 1 minute
END;
$$;

-- 10. Fonction pour mettre à jour la durée (correspond au backend)
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

-- 11. Fonction pour obtenir les recommandations (correspond au backend)
CREATE OR REPLACE FUNCTION get_recommendations(user_id_param UUID, limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    product_id INTEGER,
    nom TEXT,
    prix_base DECIMAL(10, 2),
    description TEXT,
    categorie TEXT,
    marque TEXT,
    images JSONB,
    score_recommendation DECIMAL(10, 4)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH user_categories AS (
        SELECT p.categorie, COUNT(*) as view_count
        FROM history h
        JOIN products p ON p.id = h.product_id
        WHERE h.user_id = user_id_param
        AND h.viewed_at >= NOW() - INTERVAL '30 days'
        AND p.categorie IS NOT NULL
        GROUP BY p.categorie
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
            COALESCE(uc.view_count, 0) * 0.6 + 
            (SELECT COUNT(*) FROM history h2 WHERE h2.product_id = p.id) * 0.4 as score
        FROM products p
        LEFT JOIN user_categories uc ON uc.categorie = p.categorie
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
        rp.score as score_recommendation
    FROM recommended_products rp
    ORDER BY rp.score DESC
    LIMIT limit_count;
END;
$$;

-- 12. Fonction pour obtenir les préférences de catégories (correspond au backend)
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
        (COUNT(*) * 0.4 + COALESCE(SUM(h.view_duration), 0) * 0.6) as category_score
    FROM history h
    JOIN products p ON p.id = h.product_id
    WHERE h.user_id = user_id_param
    AND h.viewed_at >= NOW() - INTERVAL '30 days'
    AND p.categorie IS NOT NULL
    GROUP BY p.categorie
    ORDER BY category_score DESC;
END;
$$;

-- 13. Fonction pour obtenir les analytics (correspond au backend)
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
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ),
    favorite_product AS (
        SELECT h.product_id
        FROM history h
        WHERE h.user_id = user_id_param
        GROUP BY h.product_id
        ORDER BY COUNT(*) DESC
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

-- 14. Vérification finale
SELECT 'Système de recommandations créé avec succès' as status; 
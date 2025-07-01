-- Script de correction pour la table history
-- À exécuter dans Supabase SQL Editor si la table existe déjà avec des erreurs

-- 1. Supprimer les contraintes et index existants
DROP INDEX IF EXISTS idx_history_user_id;
DROP INDEX IF EXISTS idx_history_product_id;
DROP INDEX IF EXISTS idx_history_viewed_at;

-- 2. Supprimer les politiques RLS existantes
DROP POLICY IF EXISTS "Users can view own history" ON public.history;
DROP POLICY IF EXISTS "Users can insert own history" ON public.history;
DROP POLICY IF EXISTS "Users can delete own history" ON public.history;

-- 3. Supprimer les fonctions existantes
DROP FUNCTION IF EXISTS public.add_product_view(INTEGER);
DROP FUNCTION IF EXISTS public.get_recommendations(INTEGER);

-- 4. Supprimer la table history si elle existe
DROP TABLE IF EXISTS public.history CASCADE;

-- 5. Recréer la table history correctement
CREATE TABLE public.history (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_duration INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Ajouter la contrainte unique correctement
ALTER TABLE public.history ADD CONSTRAINT history_user_product_date_unique 
    UNIQUE(user_id, product_id, (DATE(viewed_at)));

-- 7. Créer les index
CREATE INDEX idx_history_user_id ON public.history(user_id);
CREATE INDEX idx_history_product_id ON public.history(product_id);
CREATE INDEX idx_history_viewed_at ON public.history(viewed_at);

-- 8. Activer RLS
ALTER TABLE public.history ENABLE ROW LEVEL SECURITY;

-- 9. Créer les politiques RLS
CREATE POLICY "Users can view own history" ON public.history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own history" ON public.history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own history" ON public.history
    FOR DELETE USING (auth.uid() = user_id);

-- 10. Créer la fonction pour ajouter une consultation
CREATE OR REPLACE FUNCTION public.add_product_view(product_id_param INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.history (user_id, product_id)
    VALUES (auth.uid(), product_id_param)
    ON CONFLICT (user_id, product_id, (DATE(viewed_at)))
    DO UPDATE SET viewed_at = NOW();
END;
$$;

-- 11. Créer la fonction pour obtenir les recommandations
CREATE OR REPLACE FUNCTION public.get_recommendations(limit_count INTEGER DEFAULT 10)
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
        FROM public.history h
        JOIN public.products p ON p.id = h.product_id
        WHERE h.user_id = auth.uid()
        AND h.viewed_at >= NOW() - INTERVAL '30 days'
        AND p.categorie IS NOT NULL
        GROUP BY p.categorie
    ),
    recommended_products AS (
        SELECT 
            p.id,
            p.nom,
            p.prix_base,
            p.description,
            p.categorie,
            p.marque,
            p.images,
            COALESCE(uc.view_count, 0) * 0.6 + 
            (SELECT COUNT(*) FROM public.history h2 WHERE h2.product_id = p.id) * 0.4 as score
        FROM public.products p
        LEFT JOIN user_categories uc ON uc.categorie = p.categorie
        WHERE p.actif = true
        AND p.id NOT IN (
            SELECT product_id FROM public.history 
            WHERE user_id = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM public.product_variants pv 
            WHERE pv.product_id = p.id AND pv.stock > 0
        )
    )
    SELECT 
        rp.id,
        rp.nom,
        rp.prix_base,
        rp.description,
        rp.categorie,
        rp.marque,
        rp.images,
        rp.score
    FROM recommended_products rp
    ORDER BY rp.score DESC
    LIMIT limit_count;
END;
$$;

-- 12. Vérification finale
SELECT 'Table history créée avec succès' as status; 
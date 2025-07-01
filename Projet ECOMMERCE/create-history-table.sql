-- Script pour créer la table history et le système de recommandations

-- Table pour stocker l'historique de consultation
CREATE TABLE IF NOT EXISTS public.history (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_duration INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Contrainte unique pour éviter les doublons dans la même journée
ALTER TABLE public.history ADD CONSTRAINT history_user_product_date_unique 
    UNIQUE(user_id, product_id, (DATE(viewed_at)));

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_history_user_id ON public.history(user_id);
CREATE INDEX IF NOT EXISTS idx_history_product_id ON public.history(product_id);
CREATE INDEX IF NOT EXISTS idx_history_viewed_at ON public.history(viewed_at);

-- Activer RLS
ALTER TABLE public.history ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Users can view own history" ON public.history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own history" ON public.history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own history" ON public.history
    FOR DELETE USING (auth.uid() = user_id);

-- Fonction pour ajouter une consultation
CREATE OR REPLACE FUNCTION public.add_product_view(product_id_param INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.history (user_id, product_id)
    VALUES (auth.uid(), product_id_param)
    ON CONFLICT (user_id, product_id, DATE(viewed_at))
    DO UPDATE SET viewed_at = NOW();
END;
$$;

-- Fonction pour obtenir les recommandations
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

-- =====================================================
-- FONCTION POUR OBTENIR L'HISTORIQUE UTILISATEUR
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_user_history(
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
    product_id INTEGER,
    nom TEXT,
    prix_base DECIMAL(10, 2),
    description TEXT,
    categorie TEXT,
    marque TEXT,
    images JSONB,
    viewed_at TIMESTAMP WITH TIME ZONE,
    view_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as product_id,
        p.nom,
        p.prix_base,
        p.description,
        p.categorie,
        p.marque,
        p.images,
        h.viewed_at,
        COUNT(*) OVER (PARTITION BY p.id) as view_count
    FROM public.history h
    JOIN public.products p ON p.id = h.product_id
    WHERE h.user_id = auth.uid()
    ORDER BY h.viewed_at DESC
    LIMIT limit_count;
END;
$$;

-- =====================================================
-- TRIGGER POUR METTRE À JOUR LES TIMESTAMPS
-- =====================================================

CREATE TRIGGER update_history_updated_at 
    BEFORE UPDATE ON public.history 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- DONNÉES DE TEST (OPTIONNEL)
-- =====================================================

-- Insérer quelques couleurs de base si elles n'existent pas
INSERT INTO public.colors (nom, code_hex) VALUES 
    ('Noir', '#000000'),
    ('Blanc', '#FFFFFF'),
    ('Rouge', '#FF0000'),
    ('Bleu', '#0000FF'),
    ('Vert', '#00FF00')
ON CONFLICT (nom) DO NOTHING;

-- Insérer quelques tailles de base si elles n'existent pas
INSERT INTO public.heights (nom, ordre) VALUES 
    ('XS', 1),
    ('S', 2),
    ('M', 3),
    ('L', 4),
    ('XL', 5),
    ('XXL', 6)
ON CONFLICT (nom) DO NOTHING; 
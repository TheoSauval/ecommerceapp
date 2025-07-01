-- MIGRATION POUR UTILISER DES IDs ALÉATOIRES POUR LES COMMANDES
-- Version: 6
-- Date: 2025-01-27
-- Objectif: Remplacer les IDs séquentiels par des UUIDs aléatoires pour éviter la confusion entre utilisateurs

-- =====================================================
-- ÉTAPE 1: SAUVEGARDE DES DONNÉES EXISTANTES
-- =====================================================

-- Créer une table temporaire pour sauvegarder les commandes existantes
CREATE TABLE IF NOT EXISTS public.orders_backup AS 
SELECT * FROM public.orders;

-- Créer une table temporaire pour sauvegarder les order_variants existants
CREATE TABLE IF NOT EXISTS public.order_variants_backup AS 
SELECT * FROM public.order_variants;

-- Créer une table temporaire pour sauvegarder les payments existants
CREATE TABLE IF NOT EXISTS public.payments_backup AS 
SELECT * FROM public.payments;

-- =====================================================
-- ÉTAPE 2: SUPPRIMER LES CONTRAINTES ET TABLES
-- =====================================================

-- Supprimer les politiques RLS d'abord
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Vendors can view orders for their products" ON public.orders;

-- Supprimer les triggers
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;

-- Supprimer les contraintes de clé étrangère
ALTER TABLE public.order_variants DROP CONSTRAINT IF EXISTS order_variants_order_id_fkey;
ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_order_id_fkey;

-- Supprimer les tables dans l'ordre
DROP TABLE IF EXISTS public.order_variants CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;

-- =====================================================
-- ÉTAPE 3: RECRÉER LA TABLE ORDERS AVEC UUID
-- =====================================================

-- Table des commandes avec UUID
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prix_total DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'En attente' CHECK (status IN ('En attente', 'Payé', 'Expédiée', 'Livrée', 'Annulée', 'Échec du paiement')),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    adresse_livraison TEXT,
    methode_paiement TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table de liaison commandes-variantes avec UUID
CREATE TABLE public.order_variants (
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    variant_id INTEGER REFERENCES public.product_variants(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL, -- Prix au moment de la commande
    PRIMARY KEY (order_id, variant_id)
);

-- Table des paiements avec UUID
CREATE TABLE public.payments (
    id SERIAL PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'En attente' CHECK (status IN ('En attente', 'Payé', 'Remboursé')),
    stripe_payment_intent_id TEXT,
    refund_amount DECIMAL(10, 2),
    date_paiement TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ÉTAPE 4: RECRÉER LES INDEX
-- =====================================================

-- Index pour les commandes
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_created_at ON public.orders(created_at);

-- Index pour les paiements
CREATE INDEX idx_payments_order_id ON public.payments(order_id);
CREATE INDEX idx_payments_user_id ON public.payments(user_id);
CREATE INDEX idx_payments_status ON public.payments(status);

-- =====================================================
-- ÉTAPE 5: RECRÉER LES TRIGGERS
-- =====================================================

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ÉTAPE 6: RECRÉER LES POLITIQUES RLS
-- =====================================================

-- Activer RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Politiques pour les commandes
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create orders" ON public.orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own orders" ON public.orders FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Vendors can view orders for their products" ON public.orders FOR SELECT USING (
    id IN (
        SELECT DISTINCT ov.order_id 
        FROM public.order_variants ov 
        JOIN public.product_variants pv ON ov.variant_id = pv.id
        JOIN public.products p ON pv.product_id = p.id 
        WHERE p.vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
    )
);

-- Politiques pour les paiements
CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create payments" ON public.payments FOR INSERT WITH CHECK (user_id = auth.uid());

-- Politiques pour order_variants
CREATE POLICY "Anyone can view order_variants" ON public.order_variants FOR SELECT USING (true);
CREATE POLICY "Users can insert order_variants" ON public.order_variants FOR INSERT WITH CHECK (true);

-- =====================================================
-- ÉTAPE 7: MIGRER LES DONNÉES EXISTANTES (OPTIONNEL)
-- =====================================================

-- Note: Cette étape est optionnelle car elle nécessite une correspondance entre les anciens et nouveaux IDs
-- Si vous avez des données existantes importantes, vous devrez créer une logique de migration personnalisée

-- =====================================================
-- ÉTAPE 8: NETTOYAGE
-- =====================================================

-- Supprimer les tables de sauvegarde (optionnel - gardez-les si vous voulez conserver les anciennes données)
-- DROP TABLE IF EXISTS public.orders_backup;
-- DROP TABLE IF EXISTS public.order_variants_backup;
-- DROP TABLE IF EXISTS public.payments_backup;

-- =====================================================
-- MESSAGE DE FIN
-- =====================================================

\echo "Migration pour les IDs aléatoires des commandes appliquée avec succès."
\echo "Les nouvelles commandes utiliseront des UUIDs aléatoires au lieu d'IDs séquentiels."
\echo "Les tables de sauvegarde ont été créées dans le cas où vous auriez besoin de migrer des données existantes." 
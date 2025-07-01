-- MIGRATION DIRECTE POUR LES IDs ALÉATOIRES DES COMMANDES
-- À exécuter directement dans l'interface Supabase SQL Editor
-- Version: 1.0
-- Date: 2025-01-27

-- =====================================================
-- ÉTAPE 1: SAUVEGARDE DES DONNÉES EXISTANTES
-- =====================================================

-- Créer des tables de sauvegarde
CREATE TABLE IF NOT EXISTS public.orders_backup_manual AS 
SELECT * FROM public.orders;

CREATE TABLE IF NOT EXISTS public.order_variants_backup_manual AS 
SELECT * FROM public.order_variants;

CREATE TABLE IF NOT EXISTS public.payments_backup_manual AS 
SELECT * FROM public.payments;

-- =====================================================
-- ÉTAPE 2: SUPPRIMER LES CONTRAINTES ET POLITIQUES
-- =====================================================

-- Supprimer les politiques RLS d'abord
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Vendors can view orders for their products" ON public.orders;

-- Supprimer les triggers
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
DROP TRIGGER IF EXISTS update_payments_updated_at ON public.payments;

-- Supprimer les contraintes de clé étrangère
ALTER TABLE public.order_variants DROP CONSTRAINT IF EXISTS order_variants_order_id_fkey;
ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_order_id_fkey;

-- =====================================================
-- ÉTAPE 3: SUPPRIMER LES TABLES DÉPENDANTES
-- =====================================================

-- Supprimer les tables dans l'ordre inverse des dépendances
DROP TABLE IF EXISTS public.order_variants CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;

-- =====================================================
-- ÉTAPE 4: RECRÉER LA TABLE ORDERS AVEC UUID
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
-- ÉTAPE 5: RECRÉER LES INDEX
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
-- ÉTAPE 6: RECRÉER LES TRIGGERS
-- =====================================================

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ÉTAPE 7: RECRÉER LES POLITIQUES RLS
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
-- ÉTAPE 8: TEST DE VALIDATION
-- =====================================================

-- Créer une commande de test pour vérifier que tout fonctionne
DO $$
DECLARE
    test_user_id UUID;
    test_order_id UUID;
BEGIN
    -- Récupérer un utilisateur de test
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        -- Créer une commande de test
        INSERT INTO public.orders (prix_total, user_id, adresse_livraison, methode_paiement)
        VALUES (25.99, test_user_id, '123 Test Street', 'Carte bancaire')
        RETURNING id INTO test_order_id;
        
        -- Afficher le résultat
        RAISE NOTICE '✅ Commande de test créée avec l''ID: %', test_order_id;
        RAISE NOTICE '📱 Affichage mobile: Commande #%', UPPER(LEFT(test_order_id::text, 8));
        
        -- Nettoyer la commande de test
        DELETE FROM public.orders WHERE id = test_order_id;
        RAISE NOTICE '🧹 Commande de test supprimée';
    ELSE
        RAISE NOTICE '⚠️  Aucun utilisateur trouvé pour le test';
    END IF;
END $$;

-- =====================================================
-- MESSAGE DE FIN
-- =====================================================

-- Afficher un message de succès
DO $$
BEGIN
    RAISE NOTICE '🎉 Migration terminée avec succès !';
    RAISE NOTICE '📋 Les nouvelles commandes utiliseront des UUIDs aléatoires';
    RAISE NOTICE '📱 L''application mobile affichera des numéros courts (8 caractères)';
    RAISE NOTICE '💾 Les données existantes ont été sauvegardées dans les tables _backup_manual';
END $$; 
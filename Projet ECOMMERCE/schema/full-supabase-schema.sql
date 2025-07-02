-- =====================================================
-- FULL SUPABASE SCHEMA - ECOMMERCE APP
-- =====================================================
-- Ce fichier regroupe l'intégralité du schéma SQL pour Supabase, dans l'ordre optimal :
-- 1. Tables
-- 2. Indexes
-- 3. Fonctions
-- 4. Triggers
-- 5. Policies
--
-- Généré automatiquement pour migration/restauration complète.

-- =====================================================
-- 1. TABLES
-- =====================================================

-- >>> Début de tables-supabase.sql <<<
-- =====================================================
-- TABLES SUPABASE - ECOMMERCE APP
-- =====================================================
-- Fichier contenant toutes les définitions de tables principales
-- Version: 1.0 - Optimisé pour Supabase

-- =====================================================
-- SUPPRESSION DES TABLES EXISTANTES (SI NÉCESSAIRE)
-- =====================================================

-- Supprimer les tables dans l'ordre inverse des dépendances
DROP TABLE IF EXISTS public.order_variants CASCADE;
DROP TABLE IF EXISTS public.cart_items CASCADE;
DROP TABLE IF EXISTS public.favorites CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.product_variants CASCADE;
DROP TABLE IF EXISTS public.colors CASCADE;
DROP TABLE IF EXISTS public.heights CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.vendors CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.history CASCADE;

-- =====================================================
-- TABLES PRINCIPALES
-- =====================================================

-- Table de profil utilisateur (extension de auth.users)
CREATE TABLE public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    nom TEXT NOT NULL,
    prenom TEXT NOT NULL,
    age INTEGER NOT NULL CHECK (age >= 0),
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'vendor', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des vendeurs
CREATE TABLE public.vendors (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des produits (sans stock - le stock est dans les variantes)
CREATE TABLE public.products (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    prix_base DECIMAL(10, 2) NOT NULL, -- Prix de base, peut être modifié par variante
    vendeur_id INTEGER NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE,
    description TEXT,
    categorie TEXT,
    marque TEXT,
    images JSONB, -- Images principales du produit
    actif BOOLEAN DEFAULT true, -- Pour activer/désactiver un produit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des couleurs disponibles
CREATE TABLE public.colors (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL UNIQUE, -- ex: "Rouge", "Bleu", "Noir"
    code_hex TEXT, -- ex: "#FF0000"
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des tailles disponibles
CREATE TABLE public.heights (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL UNIQUE, -- ex: "S", "M", "L", "XL"
    ordre INTEGER DEFAULT 0, -- Pour ordonner les tailles
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des variantes de produits (taille + couleur + stock + prix)
CREATE TABLE public.product_variants (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    color_id INTEGER NOT NULL REFERENCES public.colors(id) ON DELETE CASCADE,
    height_id INTEGER NOT NULL REFERENCES public.heights(id) ON DELETE CASCADE,
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    prix DECIMAL(10, 2), -- Prix spécifique à cette variante (optionnel)
    images JSONB, -- Images spécifiques à cette variante (optionnel)
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(product_id, color_id, height_id) -- Une seule variante par combinaison
);

-- Table des commandes (avec UUID pour les IDs)
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

-- Table de liaison commandes-variantes (remplace orders_products)
CREATE TABLE public.order_variants (
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    variant_id INTEGER REFERENCES public.product_variants(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL, -- Prix au moment de la commande
    PRIMARY KEY (order_id, variant_id)
);

-- Table des éléments du panier (utilise les variantes)
CREATE TABLE public.cart_items (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    variant_id INTEGER NOT NULL REFERENCES public.product_variants(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, variant_id)
);

-- Table des favoris (liaison user-product)
CREATE TABLE public.favorites (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, product_id)
);

-- Table des notifications
CREATE TABLE public.notifications (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    titre TEXT NOT NULL,
    message TEXT NOT NULL,
    lu BOOLEAN DEFAULT false,
    type TEXT DEFAULT 'info', -- 'info', 'success', 'warning', 'error'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des paiements
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

-- Table d'historique des consultations (pour les recommandations)
CREATE TABLE public.history (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_duration INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- DONNÉES INITIALES
-- =====================================================

-- Insérer des couleurs de base
INSERT INTO public.colors (nom, code_hex) VALUES
('Rouge', '#FF0000'),
('Bleu', '#0000FF'),
('Vert', '#00FF00'),
('Jaune', '#FFFF00'),
('Orange', '#FFA500'),
('Violet', '#800080'),
('Rose', '#FFC0CB'),
('Marron', '#A52A2A'),
('Gris', '#808080'),
('Noir', '#000000'),
('Blanc', '#FFFFFF')
ON CONFLICT (nom) DO NOTHING;

-- Insérer des tailles de base
INSERT INTO public.heights (nom, ordre) VALUES
('XS', 1),
('S', 2),
('M', 3),
('L', 4),
('XL', 5),
('XXL', 6)
ON CONFLICT (nom) DO NOTHING;

-- =====================================================
-- COMMENTAIRES ET DOCUMENTATION
-- =====================================================

COMMENT ON TABLE public.user_profiles IS 'Profils utilisateurs étendant auth.users';
COMMENT ON TABLE public.vendors IS 'Table des vendeurs';
COMMENT ON TABLE public.products IS 'Table des produits en vente (sans stock)';
COMMENT ON TABLE public.colors IS 'Table des couleurs disponibles';
COMMENT ON TABLE public.heights IS 'Table des tailles disponibles';
COMMENT ON TABLE public.product_variants IS 'Table des variantes de produits (taille + couleur + stock)';
COMMENT ON TABLE public.orders IS 'Table des commandes des utilisateurs (UUID)';
COMMENT ON TABLE public.order_variants IS 'Table de liaison commandes-variantes';
COMMENT ON TABLE public.cart_items IS 'Table des éléments dans le panier des utilisateurs';
COMMENT ON TABLE public.favorites IS 'Table de liaison pour les produits favoris des utilisateurs';
COMMENT ON TABLE public.notifications IS 'Table des notifications utilisateur';
COMMENT ON TABLE public.payments IS 'Table des paiements';
COMMENT ON TABLE public.history IS 'Table d\historique des consultations pour recommandations';

-- =====================================================
-- FIN DU FICHIER TABLES
-- ===================================================== 

-- =====================================================
-- VUES
-- =====================================================

-- Vue pour les revenus des vendeurs (calcul au prorata)
DROP VIEW IF EXISTS public.vendor_revenues;

CREATE OR REPLACE VIEW public.vendor_revenues AS
WITH vendor_order_items AS (
    SELECT
        v.id as vendor_id,
        v.nom as vendor_name,
        o.id as order_id,
        ov.quantity,
        (ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount as item_revenue
    FROM public.vendors v
    JOIN public.products pr ON v.id = pr.vendeur_id
    JOIN public.product_variants pv ON pr.id = pv.product_id
    JOIN public.order_variants ov ON pv.id = ov.variant_id
    JOIN public.orders o ON ov.order_id = o.id
    JOIN public.payments p ON o.id = p.order_id
    WHERE o.status = 'Payé' AND p.status = 'Payé'
)
SELECT
    v.id as vendor_id,
    v.nom as vendor_name,
    COALESCE(SUM(voi.item_revenue), 0)::DECIMAL(10, 2) as total_revenue,
    COUNT(DISTINCT voi.order_id)::BIGINT as total_orders,
    COALESCE(SUM(voi.quantity), 0)::BIGINT as total_products_sold,
    CASE 
        WHEN COUNT(DISTINCT voi.order_id) > 0 THEN (COALESCE(SUM(voi.item_revenue), 0) / COUNT(DISTINCT voi.order_id))::DECIMAL(10, 2)
        ELSE 0 
    END as average_order_value
FROM public.vendors v
LEFT JOIN vendor_order_items voi ON v.id = voi.vendor_id
GROUP BY v.id, v.nom;

-- =====================================================
-- FIN DES VUES
-- =====================================================

-- =====================================================
-- 2. INDEXES
-- =====================================================

-- >>> Début de indexes-supabase.sql <<<
-- ...
-- =====================================================
-- INDEXES SUPABASE - ECOMMERCE APP
-- =====================================================
-- Fichier contenant tous les index optimisés pour les performances
-- Version: 1.0 - Optimisé pour Supabase

-- =====================================================
-- SUPPRESSION DES INDEX EXISTANTS (SI NÉCESSAIRE)
-- =====================================================

-- Index pour user_profiles
DROP INDEX IF EXISTS idx_user_profiles_role;

-- Index pour vendors
DROP INDEX IF EXISTS idx_vendors_user_id;

-- Index pour products
DROP INDEX IF EXISTS idx_products_vendeur_id;
DROP INDEX IF EXISTS idx_products_categorie;
DROP INDEX IF EXISTS idx_products_marque;
DROP INDEX IF EXISTS idx_products_actif;

-- Index pour product_variants
DROP INDEX IF EXISTS idx_product_variants_product_id;
DROP INDEX IF EXISTS idx_product_variants_color_id;
DROP INDEX IF EXISTS idx_product_variants_height_id;
DROP INDEX IF EXISTS idx_product_variants_stock;
DROP INDEX IF EXISTS idx_product_variants_actif;
DROP INDEX IF EXISTS idx_product_variants_unique;

-- Index pour colors et heights
DROP INDEX IF EXISTS idx_colors_nom;
DROP INDEX IF EXISTS idx_heights_nom;
DROP INDEX IF EXISTS idx_heights_ordre;

-- Index pour orders
DROP INDEX IF EXISTS idx_orders_user_id;
DROP INDEX IF EXISTS idx_orders_status;
DROP INDEX IF EXISTS idx_orders_created_at;

-- Index pour cart_items
DROP INDEX IF EXISTS idx_cart_items_user_id;
DROP INDEX IF EXISTS idx_cart_items_variant_id;

-- Index pour favorites
DROP INDEX IF EXISTS idx_favorites_user_id;
DROP INDEX IF EXISTS idx_favorites_product_id;

-- Index pour notifications
DROP INDEX IF EXISTS idx_notifications_user_id;
DROP INDEX IF EXISTS idx_notifications_lu;

-- Index pour payments
DROP INDEX IF EXISTS idx_payments_order_id;
DROP INDEX IF EXISTS idx_payments_user_id;
DROP INDEX IF EXISTS idx_payments_status;

-- Index pour history
DROP INDEX IF EXISTS idx_history_user_id;
DROP INDEX IF EXISTS idx_history_product_id;
DROP INDEX IF EXISTS idx_history_viewed_at;
DROP INDEX IF EXISTS idx_history_user_product;

-- =====================================================
-- INDEXES PRINCIPAUX
-- =====================================================

-- Index pour user_profiles
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);

-- Index pour vendors
CREATE INDEX idx_vendors_user_id ON public.vendors(user_id);

-- Index pour products (optimisés pour les requêtes fréquentes)
CREATE INDEX idx_products_vendeur_id ON public.products(vendeur_id);
CREATE INDEX idx_products_categorie ON public.products(categorie);
CREATE INDEX idx_products_marque ON public.products(marque);
CREATE INDEX idx_products_actif ON public.products(actif);
CREATE INDEX idx_products_categorie_actif ON public.products(categorie, actif) WHERE actif = true;

-- Index pour product_variants (optimisés pour la gestion du stock)
CREATE INDEX idx_product_variants_product_id ON public.product_variants(product_id);
CREATE INDEX idx_product_variants_color_id ON public.product_variants(color_id);
CREATE INDEX idx_product_variants_height_id ON public.product_variants(height_id);
CREATE INDEX idx_product_variants_stock ON public.product_variants(stock);
CREATE INDEX idx_product_variants_actif ON public.product_variants(actif);
CREATE INDEX idx_product_variants_unique ON public.product_variants(product_id, color_id, height_id);
CREATE INDEX idx_product_variants_stock_actif ON public.product_variants(stock, actif) WHERE actif = true AND stock > 0;

-- Index pour colors et heights (optimisés pour les recherches)
CREATE INDEX idx_colors_nom ON public.colors(nom);
CREATE INDEX idx_heights_nom ON public.heights(nom);
CREATE INDEX idx_heights_ordre ON public.heights(ordre);

-- Index pour orders (optimisés pour les commandes utilisateur)
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_created_at ON public.orders(created_at);
CREATE INDEX idx_orders_user_status ON public.orders(user_id, status);
CREATE INDEX idx_orders_user_created ON public.orders(user_id, created_at DESC);

-- Index pour cart_items (optimisés pour le panier)
CREATE INDEX idx_cart_items_user_id ON public.cart_items(user_id);
CREATE INDEX idx_cart_items_variant_id ON public.cart_items(variant_id);
CREATE INDEX idx_cart_items_user_variant ON public.cart_items(user_id, variant_id);

-- Index pour favorites (optimisés pour les favoris)
CREATE INDEX idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX idx_favorites_product_id ON public.favorites(product_id);
CREATE INDEX idx_favorites_user_product ON public.favorites(user_id, product_id);

-- Index pour notifications (optimisés pour les notifications utilisateur)
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_lu ON public.notifications(lu);
CREATE INDEX idx_notifications_user_lu ON public.notifications(user_id, lu);
CREATE INDEX idx_notifications_user_created ON public.notifications(user_id, created_at DESC);

-- Index pour payments (optimisés pour les paiements)
CREATE INDEX idx_payments_order_id ON public.payments(order_id);
CREATE INDEX idx_payments_user_id ON public.payments(user_id);
CREATE INDEX idx_payments_status ON public.payments(status);
CREATE INDEX idx_payments_user_status ON public.payments(user_id, status);
CREATE INDEX idx_payments_stripe_id ON public.payments(stripe_payment_intent_id);

-- Index pour history (optimisés pour les recommandations)
CREATE INDEX idx_history_user_id ON public.history(user_id);
CREATE INDEX idx_history_product_id ON public.history(product_id);
CREATE INDEX idx_history_viewed_at ON public.history(viewed_at);
CREATE INDEX idx_history_user_product ON public.history(user_id, product_id);
CREATE INDEX idx_history_user_date ON public.history(user_id, viewed_at DESC);
CREATE INDEX idx_history_product_date ON public.history(product_id, viewed_at DESC);

-- =====================================================
-- INDEXES COMPOSITES OPTIMISÉS
-- =====================================================

-- Index composite pour les recherches de produits par vendeur et catégorie
CREATE INDEX idx_products_vendor_category ON public.products(vendeur_id, categorie, actif) WHERE actif = true;

-- Index composite pour les variantes avec stock disponible
CREATE INDEX idx_variants_available ON public.product_variants(product_id, actif, stock) WHERE actif = true AND stock > 0;

-- Index composite pour les commandes récentes par utilisateur
CREATE INDEX idx_orders_recent ON public.orders(user_id, created_at DESC, status);

-- Index composite pour les notifications non lues
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, lu, created_at DESC) WHERE lu = false;

-- Index composite pour l'historique récent
-- Note: Utilisation d'un index simple car NOW() n'est pas IMMUTABLE
CREATE INDEX idx_history_recent ON public.history(user_id, viewed_at DESC);

-- =====================================================
-- INDEXES PARTIELS POUR OPTIMISATION
-- =====================================================

-- Index partiel pour les produits actifs uniquement
CREATE INDEX idx_products_active_only ON public.products(id, nom, prix_base, categorie, marque) WHERE actif = true;

-- Index partiel pour les variantes en stock
CREATE INDEX idx_variants_in_stock ON public.product_variants(id, product_id, stock, prix) WHERE stock > 0 AND actif = true;

-- Index partiel pour les commandes payées
CREATE INDEX idx_orders_paid ON public.orders(id, user_id, prix_total, created_at) WHERE status = 'Payé';

-- Index partiel pour les notifications récentes
-- Note: Utilisation d'un index simple car NOW() n'est pas IMMUTABLE
CREATE INDEX idx_notifications_recent ON public.notifications(id, user_id, titre, type, created_at);

-- =====================================================
-- INDEXES POUR LES REQUÊTES D'ANALYTICS
-- =====================================================

-- Index pour les statistiques vendeur
CREATE INDEX idx_products_vendor_analytics ON public.products(vendeur_id, actif, created_at);

-- Index pour les statistiques de commandes
CREATE INDEX idx_orders_analytics ON public.orders(status, created_at, prix_total);

-- Index pour les statistiques de paiements
CREATE INDEX idx_payments_analytics ON public.payments(status, date_paiement, amount);

-- Index pour les statistiques d'historique
CREATE INDEX idx_history_analytics ON public.history(product_id, viewed_at, view_duration);

-- =====================================================
-- COMMENTAIRES SUR LES INDEX
-- =====================================================

COMMENT ON INDEX idx_products_categorie_actif IS 'Index optimisé pour les recherches de produits par catégorie actifs';
COMMENT ON INDEX idx_product_variants_stock_actif IS 'Index optimisé pour les variantes en stock actives';
COMMENT ON INDEX idx_orders_user_created IS 'Index optimisé pour l''historique des commandes utilisateur';
COMMENT ON INDEX idx_notifications_user_lu IS 'Index optimisé pour les notifications non lues';
COMMENT ON INDEX idx_history_recent IS 'Index optimisé pour l''historique utilisateur';

-- =====================================================
-- FIN DU FICHIER INDEXES
-- ===================================================== 

-- =====================================================
-- 3. FONCTIONS
-- =====================================================

-- >>> Début de functions-supabase.sql <<<
-- =====================================================
-- FONCTIONS SUPABASE - ECOMMERCE APP (COMPLÈTE)
-- =====================================================
-- Ce fichier regroupe toutes les fonctions utilisées dans ton projet, avec la version la plus avancée/correcte de chaque fonction.

-- =====================================================
-- SUPPRESSION DES FONCTIONS EXISTANTES (SI NÉCESSAIRE)
-- =====================================================
-- Note: Les triggers sont supprimés avant les fonctions pour éviter les erreurs de dépendance
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.create_missing_profiles() CASCADE;
DROP FUNCTION IF EXISTS public.check_profiles_status() CASCADE;
DROP FUNCTION IF EXISTS public.decrease_stock(integer) CASCADE;
DROP FUNCTION IF EXISTS public.decrease_stock(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.restore_stock(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.restore_stock_from_items(jsonb) CASCADE;
DROP FUNCTION IF EXISTS add_product_view(UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS update_view_duration(UUID, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_recommendations(UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_user_category_preferences(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_user_analytics(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_variant_price(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS validate_and_reserve_stock(jsonb) CASCADE;
DROP FUNCTION IF EXISTS create_order_with_stock_validation(UUID, jsonb, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.get_vendor_revenue(integer) CASCADE;
DROP FUNCTION IF EXISTS public.get_vendor_top_products(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.get_vendor_sales_stats(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.get_vendor_sales_history(integer, integer) CASCADE;

-- =====================================================
-- UTILITAIRES ET PROFILS
-- =====================================================

-- Fonction pour mettre à jour automatiquement le champ updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour créer automatiquement un profil utilisateur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
    user_nom TEXT;
    user_prenom TEXT;
BEGIN
    -- Vérifier si le profil existe déjà (éviter les doublons)
    IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE id = NEW.id) THEN
        -- Récupérer les données utilisateur
        user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
        user_nom := COALESCE(NEW.raw_user_meta_data->>'nom', 'Utilisateur');
        user_prenom := COALESCE(NEW.raw_user_meta_data->>'prenom', 'Anonyme');
        
        -- Insérer le nouveau profil
        INSERT INTO public.user_profiles (id, nom, prenom, age, role)
        VALUES (
            NEW.id,
            user_nom,
            user_prenom,
            COALESCE((NEW.raw_user_meta_data->>'age')::integer, 18),
            user_role
        );
        
        -- Si l'utilisateur a le rôle 'vendor', créer aussi un profil vendeur
        IF user_role = 'vendor' THEN
            -- Vérifier si le profil vendeur existe déjà
            IF NOT EXISTS (SELECT 1 FROM public.vendors WHERE user_id = NEW.id) THEN
                INSERT INTO public.vendors (nom, user_id)
                VALUES (
                    COALESCE(user_nom || ' ' || user_prenom, 'Vendeur ' || NEW.id::text),
                    NEW.id
                );
                
                RAISE NOTICE 'Profil vendeur créé automatiquement pour % (ID: %)', NEW.email, NEW.id;
            END IF;
        END IF;
        
        -- Log pour le debugging
        RAISE NOTICE 'Profil utilisateur créé automatiquement pour % (ID: %) avec rôle %', NEW.email, NEW.id, user_role;
    ELSE
        RAISE NOTICE 'Profil utilisateur existe déjà pour % (ID: %)', NEW.email, NEW.id;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log l'erreur mais ne pas faire échouer l'insertion de l'utilisateur
        RAISE WARNING 'Erreur lors de la création automatique du profil pour % (ID: %): %', NEW.email, NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour créer manuellement les profils manquants
CREATE OR REPLACE FUNCTION public.create_missing_profiles()
RETURNS TABLE(
    user_id UUID,
    user_email TEXT,
    profile_created BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    auth_user RECORD;
    profile_exists BOOLEAN;
    create_error TEXT;
BEGIN
    -- Parcourir tous les utilisateurs auth.users
    FOR auth_user IN 
        SELECT id, email, raw_user_meta_data 
        FROM auth.users
    LOOP
        -- Vérifier si le profil existe
        SELECT EXISTS(
            SELECT 1 FROM public.user_profiles WHERE id = auth_user.id
        ) INTO profile_exists;
        
        IF NOT profile_exists THEN
            -- Tenter de créer le profil
            BEGIN
                INSERT INTO public.user_profiles (id, nom, prenom, age, role)
                VALUES (
                    auth_user.id,
                    COALESCE(auth_user.raw_user_meta_data->>'nom', 'Utilisateur'),
                    COALESCE(auth_user.raw_user_meta_data->>'prenom', 'Anonyme'),
                    COALESCE((auth_user.raw_user_meta_data->>'age')::integer, 18),
                    COALESCE(auth_user.raw_user_meta_data->>'role', 'user')
                );
                
                -- Retourner succès
                user_id := auth_user.id;
                user_email := auth_user.email;
                profile_created := true;
                error_message := NULL;
                RETURN NEXT;
                
            EXCEPTION WHEN OTHERS THEN
                -- Retourner erreur
                user_id := auth_user.id;
                user_email := auth_user.email;
                profile_created := false;
                error_message := SQLERRM;
                RETURN NEXT;
            END;
        END IF;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour créer automatiquement les profils vendeur manquants
CREATE OR REPLACE FUNCTION public.create_missing_vendor_profiles()
RETURNS TABLE(
    user_id UUID,
    user_email TEXT,
    vendor_profile_created BOOLEAN,
    vendor_id INTEGER,
    error_message TEXT
) AS $$
DECLARE
    user_record RECORD;
    vendor_exists BOOLEAN;
    new_vendor_id INTEGER;
    create_error TEXT;
BEGIN
    -- Parcourir tous les utilisateurs avec le rôle 'vendor'
    FOR user_record IN 
        SELECT u.id, u.email, up.nom, up.prenom
        FROM auth.users u
        JOIN public.user_profiles up ON u.id = up.id
        WHERE up.role = 'vendor'
    LOOP
        -- Vérifier si le profil vendeur existe déjà
        SELECT EXISTS(
            SELECT 1 FROM public.vendors WHERE vendors.user_id = user_record.id
        ) INTO vendor_exists;
        
        IF NOT vendor_exists THEN
            -- Tenter de créer le profil vendeur
            BEGIN
                INSERT INTO public.vendors (nom, user_id)
                VALUES (
                    COALESCE(user_record.nom || ' ' || user_record.prenom, 'Vendeur ' || user_record.id::text),
                    user_record.id
                )
                RETURNING id INTO new_vendor_id;
                
                -- Retourner succès
                user_id := user_record.id;
                user_email := user_record.email;
                vendor_profile_created := true;
                vendor_id := new_vendor_id;
                error_message := NULL;
                RETURN NEXT;
                
                RAISE NOTICE 'Profil vendeur créé pour % (ID: %, Vendor ID: %)', user_record.email, user_record.id, new_vendor_id;
                
            EXCEPTION WHEN OTHERS THEN
                -- Retourner erreur
                user_id := user_record.id;
                user_email := user_record.email;
                vendor_profile_created := false;
                vendor_id := NULL;
                error_message := SQLERRM;
                RETURN NEXT;
                
                RAISE WARNING 'Erreur lors de la création du profil vendeur pour %: %', user_record.email, SQLERRM;
            END;
        ELSE
            RAISE NOTICE 'Profil vendeur existe déjà pour %', user_record.email;
        END IF;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier l'état des profils
CREATE OR REPLACE FUNCTION public.check_profiles_status()
RETURNS TABLE(
    total_users INTEGER,
    total_profiles INTEGER,
    missing_profiles INTEGER,
    users_without_metadata INTEGER
) AS $$
BEGIN
    -- Compter les utilisateurs auth.users
    SELECT COUNT(*) INTO total_users FROM auth.users;
    
    -- Compter les profils user_profiles
    SELECT COUNT(*) INTO total_profiles FROM public.user_profiles;
    
    -- Compter les utilisateurs sans profil
    SELECT COUNT(*) INTO missing_profiles 
    FROM auth.users u
    WHERE NOT EXISTS (SELECT 1 FROM public.user_profiles p WHERE p.id = u.id);
    
    -- Compter les utilisateurs sans métadonnées
    SELECT COUNT(*) INTO users_without_metadata 
    FROM auth.users 
    WHERE raw_user_meta_data IS NULL OR raw_user_meta_data = '{}';
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FONCTIONS DE GESTION DU STOCK
-- =====================================================

-- Fonction pour décrémenter le stock après une commande payée
CREATE OR REPLACE FUNCTION public.decrease_stock(order_id_param uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    variant_record RECORD;
BEGIN
    -- Boucler sur chaque article de la commande
    FOR variant_record IN
        SELECT variant_id, quantity FROM public.order_variants WHERE order_id = order_id_param
    LOOP
        -- Mettre à jour le stock de la variante correspondante
        -- Ajout d'une sécurité pour ne pas avoir de stock négatif
        UPDATE public.product_variants
        SET stock = stock - variant_record.quantity
        WHERE id = variant_record.variant_id AND stock >= variant_record.quantity;

        -- Optionnel: Log si le stock était insuffisant
        IF NOT FOUND THEN
            RAISE WARNING 'Stock insuffisant pour la variante % lors de la commande %', variant_record.variant_id, order_id_param;
        END IF;
    END LOOP;
END;
$$;

-- Fonction pour restaurer le stock lors de l'annulation
CREATE OR REPLACE FUNCTION public.restore_stock(order_id_param uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    variant_record RECORD;
BEGIN
    -- Boucler sur chaque article de la commande
    FOR variant_record IN
        SELECT variant_id, quantity FROM public.order_variants WHERE order_id = order_id_param
    LOOP
        -- Restaurer le stock de la variante correspondante
        UPDATE public.product_variants
        SET stock = stock + variant_record.quantity
        WHERE id = variant_record.variant_id;

        -- Log de la restauration
        IF FOUND THEN
            RAISE NOTICE 'Stock restauré pour la variante %: +% unités', variant_record.variant_id, variant_record.quantity;
        ELSE
            RAISE WARNING 'Variante % non trouvée lors de la restauration du stock', variant_record.variant_id;
        END IF;
    END LOOP;
END;
$$;

-- =====================================================
-- FONCTIONS DE RECOMMANDATIONS
-- =====================================================

-- Fonction pour ajouter une consultation (correspond au backend)
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

-- Fonction pour mettre à jour la durée (correspond au backend)
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

-- Fonction pour obtenir les recommandations (correspond au backend)
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

-- Fonction pour obtenir les préférences de catégories (correspond au backend)
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

-- Fonction pour obtenir les analytics (correspond au backend)
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

-- =====================================================
-- FONCTIONS UTILITAIRES SUPPLÉMENTAIRES
-- =====================================================

-- Fonction pour calculer le prix d'une variante
CREATE OR REPLACE FUNCTION get_variant_price(variant_id INTEGER)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    variant_price DECIMAL(10, 2);
    product_price DECIMAL(10, 2);
BEGIN
    SELECT pv.prix, p.prix_base INTO variant_price, product_price
    FROM public.product_variants pv
    JOIN public.products p ON pv.product_id = p.id
    WHERE pv.id = variant_id;
    
    RETURN COALESCE(variant_price, product_price);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMMENTAIRES SUR LES FONCTIONS
-- =====================================================

COMMENT ON FUNCTION update_updated_at_column() IS 'Fonction utilitaire pour mettre à jour automatiquement le champ updated_at';
COMMENT ON FUNCTION public.handle_new_user() IS 'Fonction pour créer automatiquement un profil utilisateur lors de l''inscription';
COMMENT ON FUNCTION public.decrease_stock(uuid) IS 'Fonction pour décrémenter le stock après une commande payée';
COMMENT ON FUNCTION public.restore_stock(uuid) IS 'Fonction pour restaurer le stock lors de l''annulation d''une commande';
COMMENT ON FUNCTION add_product_view(UUID, INTEGER) IS 'Fonction pour ajouter une consultation de produit';
COMMENT ON FUNCTION get_recommendations(UUID, INTEGER) IS 'Fonction pour obtenir des recommandations de produits personnalisées';
COMMENT ON FUNCTION get_variant_price(INTEGER) IS 'Fonction pour calculer le prix d''une variante de produit';

-- =====================================================
-- VALIDATION ATOMIQUE DU STOCK ET CRÉATION DE COMMANDE
-- =====================================================

CREATE OR REPLACE FUNCTION validate_and_reserve_stock(
    order_items JSONB
) RETURNS BOOLEAN AS $$
DECLARE
    item JSONB;
    variant_record RECORD;
    current_stock INTEGER;
    missing_variants TEXT[] := ARRAY[]::TEXT[];
    insufficient_stock TEXT[] := ARRAY[]::TEXT[];
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(order_items)
    LOOP
        SELECT stock, products.nom as product_name 
        INTO variant_record
        FROM product_variants 
        JOIN products ON product_variants.product_id = products.id
        WHERE product_variants.id = (item->>'variant_id')::INTEGER
        FOR UPDATE;
        IF NOT FOUND THEN
            missing_variants := array_append(missing_variants, (item->>'variant_id')::TEXT);
            CONTINUE;
        END IF;
        current_stock := variant_record.stock;
        IF current_stock < (item->>'quantity')::INTEGER THEN
            insufficient_stock := array_append(insufficient_stock, 
                variant_record.product_name || ' (disponible: ' || current_stock || ', demandé: ' || (item->>'quantity')::TEXT || ')'
            );
            CONTINUE;
        END IF;
        UPDATE product_variants 
        SET stock = stock - (item->>'quantity')::INTEGER
        WHERE id = (item->>'variant_id')::INTEGER;
    END LOOP;
    IF array_length(missing_variants, 1) > 0 THEN
        RAISE EXCEPTION 'Produits non trouvés: %', array_to_string(missing_variants, ', ');
    END IF;
    IF array_length(insufficient_stock, 1) > 0 THEN
        RAISE EXCEPTION 'Stock insuffisant pour: %', array_to_string(insufficient_stock, '; ');
    END IF;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors de la validation du stock: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_order_with_stock_validation(
    p_user_id UUID,
    p_items JSONB,
    p_adresse_livraison TEXT,
    p_methode_paiement TEXT
) RETURNS JSONB AS $$
DECLARE
    order_id UUID;
    total_price DECIMAL(10,2) := 0;
    item JSONB;
    result JSONB;
BEGIN
    IF NOT validate_and_reserve_stock(p_items) THEN
        RAISE EXCEPTION 'Échec de la validation du stock - vérifiez les quantités disponibles';
    END IF;
    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        total_price := total_price + ((item->>'prix')::DECIMAL * (item->>'quantity')::INTEGER);
    END LOOP;
    INSERT INTO orders (user_id, status, adresse_livraison, methode_paiement, prix_total)
    VALUES (p_user_id, 'En attente', p_adresse_livraison, p_methode_paiement, total_price)
    RETURNING id INTO order_id;
    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO order_variants (order_id, variant_id, quantity, unit_price)
        VALUES (
            order_id,
            (item->>'variant_id')::INTEGER,
            (item->>'quantity')::INTEGER,
            (item->>'prix')::DECIMAL
        );
    END LOOP;
    SELECT jsonb_build_object(
        'id', o.id,
        'user_id', o.user_id,
        'status', o.status,
        'prix_total', o.prix_total,
        'created_at', o.created_at
    ) INTO result
    FROM orders o
    WHERE o.id = order_id;
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        PERFORM restore_stock_from_items(p_items);
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION restore_stock_from_items(
    p_items JSONB
) RETURNS VOID AS $$
DECLARE
    item JSONB;
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        UPDATE product_variants 
        SET stock = stock + (item->>'quantity')::INTEGER
        WHERE id = (item->>'variant_id')::INTEGER;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STATISTIQUES ET ANALYTIQUES VENDEUR
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_vendor_revenue(vendor_id_param integer)
RETURNS TABLE (
    total_revenue DECIMAL(10, 2),
    total_orders BIGINT,
    total_products_sold BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    WITH vendor_sales AS (
        SELECT 
            o.id as order_id,
            ov.quantity,
            (ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount as item_revenue
        FROM public.orders o
        JOIN public.payments p ON o.id = p.order_id
        JOIN public.order_variants ov ON o.id = ov.order_id
        JOIN public.product_variants pv ON ov.variant_id = pv.id
        JOIN public.products pr ON pv.product_id = pr.id
        WHERE pr.vendeur_id = vendor_id_param
          AND o.status IN ('Payé', 'Expédiée', 'Livrée')
          AND p.status = 'Payé'
    )
    SELECT
        COALESCE(SUM(vs.item_revenue), 0)::DECIMAL(10, 2),
        COUNT(DISTINCT vs.order_id),
        COALESCE(SUM(vs.quantity), 0)
    FROM vendor_sales vs;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_vendor_top_products(vendor_id_param integer, limit_count integer DEFAULT 10)
RETURNS TABLE (
    product_id INTEGER,
    product_name TEXT,
    product_images JSONB,
    total_quantity BIGINT,
    total_revenue DECIMAL(10, 2),
    average_price DECIMAL(10, 2)
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pr.id as product_id,
        pr.nom as product_name,
        pr.images as product_images,
        SUM(ov.quantity)::BIGINT as total_quantity,
        SUM((ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount)::DECIMAL(10, 2) as total_revenue,
        AVG(ov.unit_price)::DECIMAL(10, 2) as average_price
    FROM public.products pr
    JOIN public.product_variants pv ON pr.id = pv.product_id
    JOIN public.order_variants ov ON pv.id = ov.variant_id
    JOIN public.orders o ON ov.order_id = o.id
    JOIN public.payments p ON o.id = p.order_id
    WHERE pr.vendeur_id = vendor_id_param
      AND o.status IN ('Payé', 'Expédiée', 'Livrée')
      AND p.status = 'Payé'
    GROUP BY pr.id, pr.nom, pr.images
    ORDER BY total_quantity DESC, total_revenue DESC
    LIMIT limit_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_vendor_sales_stats(vendor_id_param integer, period_days integer DEFAULT 30)
RETURNS TABLE (
    period_revenue DECIMAL(10, 2),
    period_orders BIGINT,
    period_products_sold BIGINT,
    average_order_value DECIMAL(10, 2),
    best_selling_product TEXT,
    best_selling_product_quantity BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    best_product_name TEXT;
    best_product_qty BIGINT;
BEGIN
    RETURN QUERY
    WITH vendor_period_sales AS (
        SELECT
            o.id as order_id,
            ov.quantity,
            pr.nom as product_name,
            (ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount as item_revenue
        FROM public.orders o
        JOIN public.payments p ON o.id = p.order_id
        JOIN public.order_variants ov ON o.id = ov.order_id
        JOIN public.product_variants pv ON ov.variant_id = pv.id
        JOIN public.products pr ON pv.product_id = pr.id
        WHERE pr.vendeur_id = vendor_id_param
          AND o.status IN ('Payé', 'Expédiée', 'Livrée')
          AND p.status = 'Payé'
          AND p.date_paiement >= NOW() - (period_days || ' days')::interval
    ),
    period_stats AS (
        SELECT
            COALESCE(SUM(vps.item_revenue), 0) as revenue,
            COUNT(DISTINCT vps.order_id) as orders,
            COALESCE(SUM(vps.quantity), 0) as products_sold
        FROM vendor_period_sales vps
    ),
    best_seller AS (
        SELECT
            vps.product_name,
            SUM(vps.quantity)::BIGINT as total_quantity
        FROM vendor_period_sales vps
        GROUP BY vps.product_name
        ORDER BY total_quantity DESC
        LIMIT 1
    )
    SELECT
        ps.revenue::DECIMAL(10, 2),
        ps.orders,
        ps.products_sold,
        (CASE
            WHEN ps.orders > 0 THEN ps.revenue / ps.orders
            ELSE 0
        END)::DECIMAL(10, 2),
        COALESCE(bs.product_name, 'Aucun'),
        COALESCE(bs.total_quantity, 0)
    FROM
        period_stats ps
    LEFT JOIN
        best_seller bs ON true;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_vendor_sales_history(vendor_id_param integer, days_back integer DEFAULT 90)
RETURNS TABLE (
    sale_date DATE,
    daily_revenue DECIMAL(10, 2),
    daily_orders BIGINT,
    daily_products_sold BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE(p.date_paiement) as sale_date,
        SUM((ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount)::DECIMAL(10, 2) as daily_revenue,
        COUNT(DISTINCT o.id) as daily_orders,
        SUM(ov.quantity) as daily_products_sold
    FROM public.payments p
    JOIN public.orders o ON p.order_id = o.id
    JOIN public.order_variants ov ON o.id = ov.order_id
    JOIN public.product_variants pv ON ov.variant_id = pv.id
    JOIN public.products pr ON pv.product_id = pr.id
    WHERE pr.vendeur_id = vendor_id_param
    AND p.status = 'Payé'
    AND o.status IN ('Payé', 'Expédiée', 'Livrée')
    AND p.date_paiement >= NOW() - INTERVAL '1 day' * days_back
    GROUP BY DATE(p.date_paiement)
    ORDER BY sale_date DESC;
END;
$$;

-- =====================================================
-- FIN DU FICHIER FONCTIONS
-- ===================================================== 

-- =====================================================
-- 4. TRIGGERS
-- =====================================================

-- >>> Début de triggers-supabase.sql <<<
-- =====================================================
-- TRIGGERS SUPABASE - ECOMMERCE APP
-- =====================================================
-- Fichier contenant tous les triggers PostgreSQL utilisés
-- Version: 1.0 - Optimisé pour Supabase

-- =====================================================
-- SUPPRESSION DES TRIGGERS EXISTANTS (SI NÉCESSAIRE)
-- =====================================================

-- Triggers pour updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
DROP TRIGGER IF EXISTS update_vendors_updated_at ON public.vendors;
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
DROP TRIGGER IF EXISTS update_product_variants_updated_at ON public.product_variants;
DROP TRIGGER IF EXISTS update_colors_updated_at ON public.colors;
DROP TRIGGER IF EXISTS update_heights_updated_at ON public.heights;
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
DROP TRIGGER IF EXISTS update_cart_items_updated_at ON public.cart_items;
DROP TRIGGER IF EXISTS update_notifications_updated_at ON public.notifications;
DROP TRIGGER IF EXISTS update_payments_updated_at ON public.payments;

-- Trigger pour création automatique de profil (COMMENTÉ - à configurer manuellement dans Supabase)
-- Note: Le trigger on_auth_user_created doit être configuré manuellement dans l'interface Supabase

-- =====================================================
-- TRIGGERS POUR MISE À JOUR AUTOMATIQUE DE UPDATED_AT
-- =====================================================

-- Trigger pour user_profiles
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour vendors
CREATE TRIGGER update_vendors_updated_at 
    BEFORE UPDATE ON public.vendors 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour products
CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON public.products 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour product_variants
CREATE TRIGGER update_product_variants_updated_at 
    BEFORE UPDATE ON public.product_variants 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour colors
CREATE TRIGGER update_colors_updated_at 
    BEFORE UPDATE ON public.colors 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour heights
CREATE TRIGGER update_heights_updated_at 
    BEFORE UPDATE ON public.heights 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour orders
CREATE TRIGGER update_orders_updated_at 
    BEFORE UPDATE ON public.orders 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour cart_items
CREATE TRIGGER update_cart_items_updated_at 
    BEFORE UPDATE ON public.cart_items 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour notifications
CREATE TRIGGER update_notifications_updated_at 
    BEFORE UPDATE ON public.notifications 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour payments
CREATE TRIGGER update_payments_updated_at 
    BEFORE UPDATE ON public.payments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TRIGGER POUR CRÉATION AUTOMATIQUE DE PROFIL UTILISATEUR
-- =====================================================

-- Créer le trigger pour la création automatique de profil
-- Note: Ce trigger utilise SECURITY DEFINER pour avoir les permissions nécessaires
CREATE OR REPLACE FUNCTION create_auth_trigger()
RETURNS void AS $$
BEGIN
    -- Supprimer le trigger s'il existe déjà
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
    
    -- Créer le trigger avec les bonnes permissions
    EXECUTE 'CREATE TRIGGER on_auth_user_created
        AFTER INSERT ON auth.users
        FOR EACH ROW 
        EXECUTE FUNCTION public.handle_new_user()';
        
    RAISE NOTICE 'Trigger on_auth_user_created créé avec succès';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Impossible de créer le trigger automatiquement. Veuillez le créer manuellement dans Supabase Dashboard.';
        RAISE NOTICE 'Erreur: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Exécuter la création du trigger
SELECT create_auth_trigger();

-- Nettoyer la fonction temporaire
DROP FUNCTION IF EXISTS create_auth_trigger();

-- =====================================================
-- TRIGGERS SUPPLÉMENTAIRES POUR LA GESTION MÉTIER
-- =====================================================

-- Trigger pour valider le stock avant insertion dans order_variants
CREATE OR REPLACE FUNCTION validate_stock_before_order()
RETURNS TRIGGER AS $$
DECLARE
    available_stock INTEGER;
BEGIN
    -- Vérifier le stock disponible
    SELECT stock INTO available_stock
    FROM public.product_variants
    WHERE id = NEW.variant_id;
    
    -- Si le stock est insuffisant, lever une erreur
    IF available_stock < NEW.quantity THEN
        RAISE EXCEPTION 'Stock insuffisant pour la variante % (disponible: %, demandé: %)', 
            NEW.variant_id, available_stock, NEW.quantity;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour valider le stock avant commande
CREATE TRIGGER validate_stock_before_order_trigger
    BEFORE INSERT ON public.order_variants
    FOR EACH ROW
    EXECUTE FUNCTION validate_stock_before_order();

-- Trigger pour mettre à jour le statut de la commande quand le paiement est confirmé
CREATE OR REPLACE FUNCTION update_order_status_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    -- Si le paiement passe à "Payé", mettre à jour le statut de la commande
    IF NEW.status = 'Payé' AND OLD.status != 'Payé' THEN
        UPDATE public.orders 
        SET status = 'Payé'
        WHERE id = NEW.order_id;
        
        -- Décrémenter le stock
        PERFORM public.decrease_stock(NEW.order_id);
        
        RAISE NOTICE 'Commande % marquée comme payée et stock décrémenté', NEW.order_id;
    END IF;
    
    -- Si le paiement passe à "Remboursé", restaurer le stock
    IF NEW.status = 'Remboursé' AND OLD.status != 'Remboursé' THEN
        PERFORM public.restore_stock(NEW.order_id);
        
        RAISE NOTICE 'Stock restauré pour la commande % (remboursement)', NEW.order_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour le statut de commande lors du paiement
CREATE TRIGGER update_order_status_on_payment_trigger
    AFTER UPDATE ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION update_order_status_on_payment();

-- Trigger pour nettoyer automatiquement les éléments du panier expirés
CREATE OR REPLACE FUNCTION cleanup_expired_cart_items()
RETURNS TRIGGER AS $$
BEGIN
    -- Supprimer les éléments du panier de plus de 30 jours
    DELETE FROM public.cart_items 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour nettoyer le panier (exécuté périodiquement)
-- Note: Ce trigger peut être remplacé par une tâche cron dans Supabase
CREATE TRIGGER cleanup_expired_cart_items_trigger
    AFTER INSERT ON public.cart_items
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_expired_cart_items();

-- Trigger pour valider les données de produit avant insertion
CREATE OR REPLACE FUNCTION validate_product_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que le prix est positif
    IF NEW.prix_base <= 0 THEN
        RAISE EXCEPTION 'Le prix de base doit être supérieur à 0';
    END IF;
    
    -- Vérifier que le vendeur existe
    IF NOT EXISTS (SELECT 1 FROM public.vendors WHERE id = NEW.vendeur_id) THEN
        RAISE EXCEPTION 'Le vendeur avec l''ID % n''existe pas', NEW.vendeur_id;
    END IF;
    
    -- Vérifier que le nom n'est pas vide
    IF TRIM(NEW.nom) = '' THEN
        RAISE EXCEPTION 'Le nom du produit ne peut pas être vide';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour valider les données de produit
CREATE TRIGGER validate_product_data_trigger
    BEFORE INSERT OR UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION validate_product_data();

-- Trigger pour valider les données de variante
CREATE OR REPLACE FUNCTION validate_variant_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que le stock n'est pas négatif
    IF NEW.stock < 0 THEN
        RAISE EXCEPTION 'Le stock ne peut pas être négatif';
    END IF;
    
    -- Vérifier que le produit existe
    IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = NEW.product_id) THEN
        RAISE EXCEPTION 'Le produit avec l''ID % n''existe pas', NEW.product_id;
    END IF;
    
    -- Vérifier que la couleur existe
    IF NOT EXISTS (SELECT 1 FROM public.colors WHERE id = NEW.color_id) THEN
        RAISE EXCEPTION 'La couleur avec l''ID % n''existe pas', NEW.color_id;
    END IF;
    
    -- Vérifier que la taille existe
    IF NOT EXISTS (SELECT 1 FROM public.heights WHERE id = NEW.height_id) THEN
        RAISE EXCEPTION 'La taille avec l''ID % n''existe pas', NEW.height_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour valider les données de variante
CREATE TRIGGER validate_variant_data_trigger
    BEFORE INSERT OR UPDATE ON public.product_variants
    FOR EACH ROW
    EXECUTE FUNCTION validate_variant_data();

-- =====================================================
-- TRIGGERS POUR LES NOTIFICATIONS AUTOMATIQUES
-- =====================================================

-- Trigger pour créer une notification quand une commande est créée
CREATE OR REPLACE FUNCTION notify_order_created()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer une notification pour l'utilisateur
    INSERT INTO public.notifications (user_id, titre, message, type)
    VALUES (
        NEW.user_id,
        'Commande créée',
        'Votre commande #' || UPPER(LEFT(NEW.id::text, 8)) || ' a été créée avec succès.',
        'success'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour notifier la création de commande
CREATE TRIGGER notify_order_created_trigger
    AFTER INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION notify_order_created();

-- Trigger pour créer une notification quand le statut de commande change
CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer une notification seulement si le statut a changé
    IF OLD.status != NEW.status THEN
        INSERT INTO public.notifications (user_id, titre, message, type)
        VALUES (
            NEW.user_id,
            'Statut de commande mis à jour',
            'Votre commande #' || UPPER(LEFT(NEW.id::text, 8)) || ' est maintenant ' || NEW.status || '.',
            'info'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour notifier le changement de statut
CREATE TRIGGER notify_order_status_change_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION notify_order_status_change();

-- =====================================================
-- COMMENTAIRES SUR LES TRIGGERS
-- =====================================================

COMMENT ON TRIGGER update_user_profiles_updated_at ON public.user_profiles IS 'Met à jour automatiquement le champ updated_at';
-- COMMENT ON TRIGGER on_auth_user_created ON auth.users IS 'Crée automatiquement un profil utilisateur lors de l''inscription';
COMMENT ON TRIGGER validate_stock_before_order_trigger ON public.order_variants IS 'Valide le stock disponible avant d''ajouter un article à une commande';
COMMENT ON TRIGGER update_order_status_on_payment_trigger ON public.payments IS 'Met à jour le statut de commande et gère le stock lors du paiement';
COMMENT ON TRIGGER validate_product_data_trigger ON public.products IS 'Valide les données de produit avant insertion/mise à jour';
COMMENT ON TRIGGER notify_order_created_trigger ON public.orders IS 'Crée une notification lors de la création d''une commande';

-- =====================================================
-- FIN DU FICHIER TRIGGERS
-- ===================================================== 

-- =====================================================
-- 5. POLICIES
-- =====================================================

-- >>> Début de policies-supabase.sql <<<
-- =====================================================
-- POLITIQUES SUPABASE - ECOMMERCE APP
-- =====================================================
-- Fichier contenant toutes les politiques RLS (Row Level Security)
-- Version: 1.0 - Optimisé pour Supabase

-- =====================================================
-- SUPPRESSION DES POLITIQUES EXISTANTES (SI NÉCESSAIRE)
-- =====================================================

-- Politiques pour user_profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.user_profiles;

-- Politiques pour vendors
DROP POLICY IF EXISTS "Vendors can view own profile" ON public.vendors;
DROP POLICY IF EXISTS "Vendors can update own profile" ON public.vendors;
DROP POLICY IF EXISTS "Anyone can view vendors" ON public.vendors;

-- Politiques pour products
DROP POLICY IF EXISTS "Anyone can view active products" ON public.products;
DROP POLICY IF EXISTS "Vendors can manage own products" ON public.products;
DROP POLICY IF EXISTS "Vendors can view all own products" ON public.products;

-- Politiques pour product_variants
DROP POLICY IF EXISTS "Anyone can view active variants" ON public.product_variants;
DROP POLICY IF EXISTS "Vendors can manage variants for own products" ON public.product_variants;

-- Politiques pour colors et heights
DROP POLICY IF EXISTS "Anyone can view colors" ON public.colors;
DROP POLICY IF EXISTS "Anyone can view heights" ON public.heights;

-- Politiques pour orders
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Vendors can view orders for their products" ON public.orders;

-- Politiques pour order_variants
DROP POLICY IF EXISTS "Anyone can view order_variants" ON public.order_variants;
DROP POLICY IF EXISTS "Users can insert order_variants" ON public.order_variants;

-- Politiques pour cart_items
DROP POLICY IF EXISTS "Users can manage own cart" ON public.cart_items;

-- Politiques pour favorites
DROP POLICY IF EXISTS "Users can manage own favorites" ON public.favorites;

-- Politiques pour notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;

-- Politiques pour payments
DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can create payments" ON public.payments;

-- Politiques pour history
DROP POLICY IF EXISTS "Users can view their own history" ON public.history;
DROP POLICY IF EXISTS "Users can insert their own history" ON public.history;
DROP POLICY IF EXISTS "Users can update their own history" ON public.history;
DROP POLICY IF EXISTS "Users can delete their own history" ON public.history;

-- =====================================================
-- ACTIVATION DE ROW LEVEL SECURITY
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.colors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.heights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.history ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLITIQUES POUR LES PROFILS UTILISATEURS
-- =====================================================

-- Politiques pour les profils utilisateurs
CREATE POLICY "Users can view own profile" ON public.user_profiles 
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles 
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles 
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON public.user_profiles 
    FOR DELETE USING (auth.uid() = id);

-- =====================================================
-- POLITIQUES POUR LES VANDEURS
-- =====================================================

-- Politiques pour les vendeurs
CREATE POLICY "Vendors can view own profile" ON public.vendors 
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Vendors can update own profile" ON public.vendors 
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Anyone can view vendors" ON public.vendors 
    FOR SELECT USING (true);

-- =====================================================
-- POLITIQUES POUR LES PRODUITS
-- =====================================================

-- Politiques pour les produits
CREATE POLICY "Anyone can view active products" ON public.products 
    FOR SELECT USING (actif = true);

CREATE POLICY "Vendors can manage own products" ON public.products 
    FOR ALL USING (
        vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
    );

CREATE POLICY "Vendors can view all own products" ON public.products 
    FOR SELECT USING (
        vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
    );

-- =====================================================
-- POLITIQUES POUR LES VARIANTES DE PRODUITS
-- =====================================================

-- Politiques pour les variantes
CREATE POLICY "Anyone can view active variants" ON public.product_variants 
    FOR SELECT USING (actif = true);

CREATE POLICY "Vendors can manage variants for own products" ON public.product_variants 
    FOR ALL USING (
        product_id IN (
            SELECT id FROM public.products 
            WHERE vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
        )
    );

-- =====================================================
-- POLITIQUES POUR LES COULEURS ET TAILLES
-- =====================================================

-- Politiques pour les couleurs et tailles (lecture publique)
CREATE POLICY "Anyone can view colors" ON public.colors 
    FOR SELECT USING (true);

CREATE POLICY "Anyone can view heights" ON public.heights 
    FOR SELECT USING (true);

-- =====================================================
-- POLITIQUES POUR LES COMMANDES
-- =====================================================

-- Politiques pour les commandes
CREATE POLICY "Users can view own orders" ON public.orders 
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create orders" ON public.orders 
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own orders" ON public.orders 
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Vendors can view orders for their products" ON public.orders 
    FOR SELECT USING (
        id IN (
            SELECT DISTINCT ov.order_id 
            FROM public.order_variants ov 
            JOIN public.product_variants pv ON ov.variant_id = pv.id
            JOIN public.products p ON pv.product_id = p.id 
            WHERE p.vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
        )
    );

-- =====================================================
-- POLITIQUES POUR LES ÉLÉMENTS DE COMMANDE
-- =====================================================

-- Politiques pour order_variants
CREATE POLICY "Anyone can view order_variants" ON public.order_variants 
    FOR SELECT USING (true);

CREATE POLICY "Users can insert order_variants" ON public.order_variants 
    FOR INSERT WITH CHECK (true);

-- =====================================================
-- POLITIQUES POUR LE PANIER
-- =====================================================

-- Politiques pour les éléments du panier
CREATE POLICY "Users can manage own cart" ON public.cart_items 
    FOR ALL USING (user_id = auth.uid());

-- =====================================================
-- POLITIQUES POUR LES FAVORIS
-- =====================================================

-- Politiques pour les favoris
CREATE POLICY "Users can manage own favorites" ON public.favorites 
    FOR ALL USING (user_id = auth.uid());

-- =====================================================
-- POLITIQUES POUR LES NOTIFICATIONS
-- =====================================================

-- Politiques pour les notifications
CREATE POLICY "Users can view own notifications" ON public.notifications 
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications" ON public.notifications 
    FOR UPDATE USING (user_id = auth.uid());

-- =====================================================
-- POLITIQUES POUR LES PAIEMENTS
-- =====================================================

-- Politiques pour les paiements
CREATE POLICY "Users can view own payments" ON public.payments 
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create payments" ON public.payments 
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- =====================================================
-- POLITIQUES POUR L'HISTORIQUE
-- =====================================================

-- Politiques pour l'historique des consultations
CREATE POLICY "Users can view their own history" ON public.history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own history" ON public.history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own history" ON public.history
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own history" ON public.history
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- POLITIQUES SUPPLÉMENTAIRES POUR LA SÉCURITÉ
-- =====================================================

-- Politique pour permettre aux admins de tout voir (optionnel)
-- CREATE POLICY "Admins can view everything" ON public.user_profiles
--     FOR ALL USING (
--         EXISTS (
--             SELECT 1 FROM public.user_profiles 
--             WHERE id = auth.uid() AND role = 'admin'
--         )
--     );

-- Politique pour permettre aux admins de gérer tous les produits
-- CREATE POLICY "Admins can manage all products" ON public.products
--     FOR ALL USING (
--         EXISTS (
--             SELECT 1 FROM public.user_profiles 
--             WHERE id = auth.uid() AND role = 'admin'
--         )
--     );

-- =====================================================
-- POLITIQUES POUR LE STOCKAGE SUPABASE (OPTIONNEL)
-- =====================================================

-- Ces politiques sont définies dans supabase-storage-setup.sql
-- mais peuvent être ajoutées ici pour centralisation

-- Politique pour permettre aux utilisateurs authentifiés de télécharger des images
-- CREATE POLICY "Authenticated users can upload product images" ON storage.objects
-- FOR INSERT WITH CHECK (
--     bucket_id = 'product-images' 
--     AND auth.role() = 'authenticated'
-- );

-- Politique pour permettre aux utilisateurs de voir toutes les images de produits
-- CREATE POLICY "Anyone can view product images" ON storage.objects
-- FOR SELECT USING (bucket_id = 'product-images');

-- Politique pour permettre aux vendeurs de supprimer leurs images
-- CREATE POLICY "Vendors can delete their product images" ON storage.objects
-- FOR DELETE USING (
--     bucket_id = 'product-images' 
--     AND auth.role() = 'authenticated'
-- );

-- =====================================================
-- COMMENTAIRES SUR LES POLITIQUES
-- =====================================================

COMMENT ON POLICY "Users can view own profile" ON public.user_profiles IS 'Permet aux utilisateurs de voir leur propre profil';
COMMENT ON POLICY "Vendors can manage own products" ON public.products IS 'Permet aux vendeurs de gérer leurs propres produits';
COMMENT ON POLICY "Anyone can view active products" ON public.products IS 'Permet à tous de voir les produits actifs';
COMMENT ON POLICY "Users can view own orders" ON public.orders IS 'Permet aux utilisateurs de voir leurs propres commandes';
COMMENT ON POLICY "Users can manage own cart" ON public.cart_items IS 'Permet aux utilisateurs de gérer leur propre panier';
COMMENT ON POLICY "Users can view own notifications" ON public.notifications IS 'Permet aux utilisateurs de voir leurs propres notifications';

-- =====================================================
-- FIN DU FICHIER POLITIQUES
-- ===================================================== 

-- =====================================================
-- RÉCUPÉRATION DES PROFILS UTILISATEURS
-- =====================================================

-- Créer automatiquement les profils pour les utilisateurs existants
SELECT public.create_missing_profiles();

-- Créer automatiquement les profils vendeur manquants
SELECT public.create_missing_vendor_profiles();

-- Vérifier l'état des profils
SELECT public.check_profiles_status();

-- =====================================================
-- INSTRUCTIONS POST-INSTALLATION
-- =====================================================

-- IMPORTANT: Configurer le trigger d'authentification dans Supabase Dashboard
-- 
-- 1. Aller dans Supabase Dashboard > Database > Triggers
-- 2. Cliquer sur "New Trigger"
-- 3. Remplir les champs :
--    - Name: on_auth_user_created
--    - Table: auth.users
--    - Events: INSERT
--    - Function: handle_new_user()
--    - Enable: Yes
--
-- Ce trigger permettra la création automatique de profils
-- pour tous les nouveaux utilisateurs qui s'inscrivent.

-- =====================================================
-- VÉRIFICATION FINALE
-- =====================================================

-- Vérifier que tous les utilisateurs ont un profil
SELECT 
    COUNT(*) as total_users,
    COUNT(p.id) as users_with_profiles,
    COUNT(*) - COUNT(p.id) as users_without_profiles
FROM auth.users u
LEFT JOIN public.user_profiles p ON u.id = p.id;

-- =====================================================
-- FIN DU SCHEMA COMPLET
-- ===================================================== 

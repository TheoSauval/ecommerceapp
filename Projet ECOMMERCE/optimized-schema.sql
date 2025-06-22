-- Script SQL optimisé pour recréer la structure de base de données e-commerce dans Supabase
-- Gestion du stock par variante (taille + couleur)

-- =====================================================
-- SUPPRESSION DES TABLES EXISTANTES
-- =====================================================

-- Supprimer les politiques RLS d'abord
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Anyone can view active products" ON public.products;
DROP POLICY IF EXISTS "Vendors can manage own products" ON public.products;
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Vendors can view orders for their products" ON public.orders;
DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can create payments" ON public.payments;
DROP POLICY IF EXISTS "Vendors can view own profile" ON public.vendors;
DROP POLICY IF EXISTS "Vendors can update own profile" ON public.vendors;
DROP POLICY IF EXISTS "Anyone can view vendors" ON public.vendors;
DROP POLICY IF EXISTS "Users can manage own cart" ON public.cart_items;
DROP POLICY IF EXISTS "Anyone can view colors and heights" ON public.colors;
DROP POLICY IF EXISTS "Vendors can manage colors for own products" ON public.colors;
DROP POLICY IF EXISTS "Anyone can view colors and heights" ON public.heights;
DROP POLICY IF EXISTS "Vendors can manage heights for own products" ON public.heights;
DROP POLICY IF EXISTS "Users can manage own favorites" ON public.favorites;
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Anyone can view orders_products" ON public.orders_products;
DROP POLICY IF EXISTS "Users can insert orders_products" ON public.orders_products;

-- Supprimer les triggers
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
DROP TRIGGER IF EXISTS update_vendors_updated_at ON public.vendors;
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
DROP TRIGGER IF EXISTS update_cart_items_updated_at ON public.cart_items;
DROP TRIGGER IF EXISTS update_colors_updated_at ON public.colors;
DROP TRIGGER IF EXISTS update_heights_updated_at ON public.heights;
DROP TRIGGER IF EXISTS update_notifications_updated_at ON public.notifications;
DROP TRIGGER IF EXISTS update_payments_updated_at ON public.payments;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Supprimer les fonctions
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Supprimer les tables dans l'ordre inverse des dépendances
DROP TABLE IF EXISTS public.orders_products CASCADE;
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

-- =====================================================
-- TABLES PRINCIPALES OPTIMISÉES
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

-- Table des commandes
CREATE TABLE public.orders (
    id SERIAL PRIMARY KEY,
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
    order_id INTEGER REFERENCES public.orders(id) ON DELETE CASCADE,
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
    order_id INTEGER REFERENCES public.orders(id) ON DELETE SET NULL,
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
-- INDEX POUR LES PERFORMANCES
-- =====================================================

-- Index pour les profils utilisateurs
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);

-- Index pour les vendeurs
CREATE INDEX idx_vendors_user_id ON public.vendors(user_id);

-- Index pour les produits
CREATE INDEX idx_products_vendeur_id ON public.products(vendeur_id);
CREATE INDEX idx_products_categorie ON public.products(categorie);
CREATE INDEX idx_products_marque ON public.products(marque);
CREATE INDEX idx_products_actif ON public.products(actif);

-- Index pour les variantes
CREATE INDEX idx_product_variants_product_id ON public.product_variants(product_id);
CREATE INDEX idx_product_variants_color_id ON public.product_variants(color_id);
CREATE INDEX idx_product_variants_height_id ON public.product_variants(height_id);
CREATE INDEX idx_product_variants_stock ON public.product_variants(stock);
CREATE INDEX idx_product_variants_actif ON public.product_variants(actif);
CREATE INDEX idx_product_variants_unique ON public.product_variants(product_id, color_id, height_id);

-- Index pour les couleurs et tailles
CREATE INDEX idx_colors_nom ON public.colors(nom);
CREATE INDEX idx_heights_nom ON public.heights(nom);
CREATE INDEX idx_heights_ordre ON public.heights(ordre);

-- Index pour les commandes
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_created_at ON public.orders(created_at);

-- Index pour les éléments du panier
CREATE INDEX idx_cart_items_user_id ON public.cart_items(user_id);
CREATE INDEX idx_cart_items_variant_id ON public.cart_items(variant_id);

-- Index pour les favoris
CREATE INDEX idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX idx_favorites_product_id ON public.favorites(product_id);

-- Index pour les notifications
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_lu ON public.notifications(lu);

-- Index pour les paiements
CREATE INDEX idx_payments_order_id ON public.payments(order_id);
CREATE INDEX idx_payments_user_id ON public.payments(user_id);
CREATE INDEX idx_payments_status ON public.payments(status);

-- =====================================================
-- FONCTIONS ET TRIGGERS
-- =====================================================

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour mettre à jour updated_at
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON public.vendors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_product_variants_updated_at BEFORE UPDATE ON public.product_variants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_colors_updated_at BEFORE UPDATE ON public.colors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_heights_updated_at BEFORE UPDATE ON public.heights FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cart_items_updated_at BEFORE UPDATE ON public.cart_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON public.notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour décrémenter le stock après une commande payée
CREATE OR REPLACE FUNCTION public.decrease_stock(order_id_param integer)
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

-- Fonction pour créer automatiquement un profil utilisateur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, nom, prenom, age, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nom', 'Utilisateur'),
        COALESCE(NEW.raw_user_meta_data->>'prenom', 'Anonyme'),
        COALESCE((NEW.raw_user_meta_data->>'age')::integer, 18),
        COALESCE(NEW.raw_user_meta_data->>'role', 'user')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour créer automatiquement un profil lors de l'inscription
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

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
('Blanc', '#FFFFFF');

-- Insérer des tailles de base
INSERT INTO public.heights (nom, ordre) VALUES
('XS', 1),
('S', 2),
('M', 3),
('L', 4),
('XL', 5),
('XXL', 6);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) - POLITIQUES SIMPLIFIÉES
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

-- Politiques pour les profils utilisateurs
CREATE POLICY "Users can view own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can delete own profile" ON public.user_profiles FOR DELETE USING (auth.uid() = id);

-- Politiques pour les vendeurs
CREATE POLICY "Vendors can view own profile" ON public.vendors FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Vendors can update own profile" ON public.vendors FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Anyone can view vendors" ON public.vendors FOR SELECT USING (true);

-- Politiques pour les produits
CREATE POLICY "Anyone can view active products" ON public.products FOR SELECT USING (actif = true);
CREATE POLICY "Vendors can manage own products" ON public.products FOR ALL USING (
    vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
);
CREATE POLICY "Vendors can view all own products" ON public.products FOR SELECT USING (
    vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
);

-- Politiques pour les variantes
CREATE POLICY "Anyone can view active variants" ON public.product_variants FOR SELECT USING (actif = true);
CREATE POLICY "Vendors can manage variants for own products" ON public.product_variants FOR ALL USING (
    product_id IN (
        SELECT id FROM public.products 
        WHERE vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
    )
);

-- Politiques pour les couleurs et tailles (lecture publique)
CREATE POLICY "Anyone can view colors" ON public.colors FOR SELECT USING (true);
CREATE POLICY "Anyone can view heights" ON public.heights FOR SELECT USING (true);

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

-- Politiques pour les éléments du panier
CREATE POLICY "Users can manage own cart" ON public.cart_items FOR ALL USING (user_id = auth.uid());

-- Politiques pour les favoris
CREATE POLICY "Users can manage own favorites" ON public.favorites FOR ALL USING (user_id = auth.uid());

-- Politiques pour les notifications
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (user_id = auth.uid());

-- Politiques pour les paiements
CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create payments" ON public.payments FOR INSERT WITH CHECK (user_id = auth.uid());

-- Politiques pour order_variants
CREATE POLICY "Anyone can view order_variants" ON public.order_variants FOR SELECT USING (true);
CREATE POLICY "Users can insert order_variants" ON public.order_variants FOR INSERT WITH CHECK (true);

-- =====================================================
-- COMMENTAIRES ET DOCUMENTATION
-- =====================================================

COMMENT ON TABLE public.user_profiles IS 'Profils utilisateurs étendant auth.users';
COMMENT ON TABLE public.vendors IS 'Table des vendeurs';
COMMENT ON TABLE public.products IS 'Table des produits en vente (sans stock)';
COMMENT ON TABLE public.colors IS 'Table des couleurs disponibles';
COMMENT ON TABLE public.heights IS 'Table des tailles disponibles';
COMMENT ON TABLE public.product_variants IS 'Table des variantes de produits (taille + couleur + stock)';
COMMENT ON TABLE public.orders IS 'Table des commandes des utilisateurs';
COMMENT ON TABLE public.order_variants IS 'Table de liaison commandes-variantes';
COMMENT ON TABLE public.cart_items IS 'Table des éléments dans le panier des utilisateurs';
COMMENT ON TABLE public.favorites IS 'Table de liaison pour les produits favoris des utilisateurs';
COMMENT ON TABLE public.notifications IS 'Table des notifications utilisateur';
COMMENT ON TABLE public.payments IS 'Table des paiements';

-- =====================================================
-- FIN DU SCRIPT
-- =====================================================

-- Ce schéma optimisé permet de gérer le stock par variante (taille + couleur)
-- Exemple : Un T-shirt peut avoir 2 en stock taille S rouge et 1 en stock taille L noir 
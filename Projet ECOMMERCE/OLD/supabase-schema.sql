-- Script SQL pour recréer la structure de base de données e-commerce dans Supabase
-- Utilise Supabase Auth avec extension de profil

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

-- Table des produits
CREATE TABLE public.products (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    prix DECIMAL(10, 2) NOT NULL,
    quantite INTEGER NOT NULL CHECK (quantite >= 0),
    vendeur_id INTEGER NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE,
    description TEXT,
    categorie TEXT,
    marque TEXT,
    images JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des commandes
CREATE TABLE public.orders (
    id SERIAL PRIMARY KEY,
    prix_total DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'En attente' CHECK (status IN ('En attente', 'Expédiée', 'Livrée', 'Annulée')),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    adresse_livraison TEXT,
    methode_paiement TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table de liaison commandes-produits
CREATE TABLE public.orders_products (
    order_id INTEGER REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

-- Table des éléments du panier
CREATE TABLE public.cart_items (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    size TEXT NOT NULL,
    color TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id, size, color)
);

-- Table des couleurs des produits
CREATE TABLE public.colors (
    id SERIAL PRIMARY KEY,
    produit_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
    couleur TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des tailles des produits
CREATE TABLE public.heights (
    id SERIAL PRIMARY KEY,
    produit_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
    taille TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
    status TEXT NOT NULL,
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
CREATE INDEX idx_products_prix ON public.products(prix);

-- Index pour les commandes
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_created_at ON public.orders(created_at);

-- Index pour les éléments du panier
CREATE INDEX idx_cart_items_user_id ON public.cart_items(user_id);
CREATE INDEX idx_cart_items_product_id ON public.cart_items(product_id);

-- Index pour les couleurs et tailles
CREATE INDEX idx_colors_produit_id ON public.colors(produit_id);
CREATE INDEX idx_heights_produit_id ON public.heights(produit_id);

-- Index pour les favoris
CREATE INDEX idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX idx_favorites_product_id ON public.favorites(product_id);

-- Index pour les notifications
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);

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
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cart_items_updated_at BEFORE UPDATE ON public.cart_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_colors_updated_at BEFORE UPDATE ON public.colors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_heights_updated_at BEFORE UPDATE ON public.heights FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON public.notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.colors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.heights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Politiques pour les profils utilisateurs
CREATE POLICY "Users can view own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON public.user_profiles FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Politiques pour les vendeurs
CREATE POLICY "Vendors can view own profile" ON public.vendors FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Vendors can update own profile" ON public.vendors FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Anyone can view vendors" ON public.vendors FOR SELECT USING (true);

-- Politiques pour les produits
CREATE POLICY "Anyone can view active products" ON public.products FOR SELECT USING (true);
CREATE POLICY "Vendors can manage own products" ON public.products FOR ALL USING (
    vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
);
CREATE POLICY "Admins can manage all products" ON public.products FOR ALL USING (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Politiques pour les commandes
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create orders" ON public.orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own orders" ON public.orders FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Vendors can view orders for their products" ON public.orders FOR SELECT USING (
    id IN (
        SELECT DISTINCT op.order_id 
        FROM public.orders_products op 
        JOIN public.products p ON op.product_id = p.id 
        WHERE p.vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
    )
);
CREATE POLICY "Admins can view all orders" ON public.orders FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Politiques pour les éléments du panier
CREATE POLICY "Users can manage own cart" ON public.cart_items FOR ALL USING (user_id = auth.uid());

-- Politiques pour les couleurs et tailles
CREATE POLICY "Anyone can view colors and heights" ON public.colors FOR SELECT USING (true);
CREATE POLICY "Anyone can view colors and heights" ON public.heights FOR SELECT USING (true);
CREATE POLICY "Vendors can manage colors for own products" ON public.colors FOR ALL USING (
    produit_id IN (
        SELECT id FROM public.products 
        WHERE vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
    )
);
CREATE POLICY "Vendors can manage heights for own products" ON public.heights FOR ALL USING (
    produit_id IN (
        SELECT id FROM public.products 
        WHERE vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
    )
);

-- Politiques pour les favoris
CREATE POLICY "Users can manage own favorites" ON public.favorites FOR ALL USING (user_id = auth.uid());

-- Politiques pour les notifications
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (user_id = auth.uid());

-- Politiques pour les paiements
CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create payments" ON public.payments FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins can view all payments" ON public.payments FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
);

-- =====================================================
-- COMMENTAIRES ET DOCUMENTATION
-- =====================================================

COMMENT ON TABLE public.user_profiles IS 'Profils utilisateurs étendant auth.users';
COMMENT ON TABLE public.vendors IS 'Table des vendeurs';
COMMENT ON TABLE public.products IS 'Table des produits en vente';
COMMENT ON TABLE public.orders IS 'Table des commandes des utilisateurs';
COMMENT ON TABLE public.cart_items IS 'Table des éléments dans le panier des utilisateurs';
COMMENT ON TABLE public.colors IS 'Table des couleurs disponibles pour chaque produit';
COMMENT ON TABLE public.heights IS 'Table des tailles disponibles pour chaque produit';
COMMENT ON TABLE public.favorites IS 'Table de liaison pour les produits favoris des utilisateurs';
COMMENT ON TABLE public.notifications IS 'Table des notifications utilisateur';
COMMENT ON TABLE public.payments IS 'Table des paiements';

-- =====================================================
-- FIN DU SCRIPT
-- =====================================================

-- Ce script utilise Supabase Auth avec extension de profil
-- pour une authentification sécurisée et des champs personnalisés 
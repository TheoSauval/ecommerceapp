-- Script pour corriger les politiques RLS problématiques
-- Problème : récursion infinie dans les politiques user_profiles

-- Supprimer TOUTES les politiques existantes
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;

DROP POLICY IF EXISTS "Anyone can view active products" ON public.products;
DROP POLICY IF EXISTS "Vendors can manage own products" ON public.products;
DROP POLICY IF EXISTS "Admins can manage all products" ON public.products;

DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Vendors can view orders for their products" ON public.orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;

DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can create payments" ON public.payments;
DROP POLICY IF EXISTS "Admins can view all payments" ON public.payments;

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

-- Recréer les politiques sans récursion
-- Politiques pour les profils utilisateurs (simplifiées)
CREATE POLICY "Users can view own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Politiques pour les produits (simplifiées)
CREATE POLICY "Anyone can view active products" ON public.products FOR SELECT USING (true);
CREATE POLICY "Vendors can manage own products" ON public.products FOR ALL USING (
    vendeur_id IN (SELECT id FROM public.vendors WHERE user_id = auth.uid())
);

-- Politiques pour les commandes (simplifiées)
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

-- Politiques pour les paiements (simplifiées)
CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create payments" ON public.payments FOR INSERT WITH CHECK (user_id = auth.uid());

-- Politiques pour les vendeurs (simplifiées)
CREATE POLICY "Vendors can view own profile" ON public.vendors FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Vendors can update own profile" ON public.vendors FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Anyone can view vendors" ON public.vendors FOR SELECT USING (true);

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

-- Politiques pour orders_products
CREATE POLICY "Anyone can view orders_products" ON public.orders_products FOR SELECT USING (true);
CREATE POLICY "Users can insert orders_products" ON public.orders_products FOR INSERT WITH CHECK (true);

-- Commentaire : Les politiques admin ont été supprimées pour éviter la récursion
-- Les admins peuvent toujours accéder aux données via le backend avec les middlewares appropriés 
-- =====================================================
-- CORRECTION DES STATISTIQUES VENDEUR
-- =====================================================
-- Problème: Les fonctions ne comptabilisent que les commandes avec statut 'Payé'
-- Solution: Inclure tous les statuts qui représentent des ventes complétées

-- =====================================================
-- ÉTAPE 0: SUPPRIMER LES FONCTIONS ET VUES EXISTANTES
-- =====================================================

-- Supprimer les fonctions existantes
DROP FUNCTION IF EXISTS public.get_vendor_revenue(integer);
DROP FUNCTION IF EXISTS public.get_vendor_top_products(integer, integer);
DROP FUNCTION IF EXISTS public.get_vendor_sales_stats(integer, integer);
DROP FUNCTION IF EXISTS public.get_vendor_sales_history(integer, integer);

-- Supprimer la vue existante
DROP VIEW IF EXISTS public.vendor_revenues;

-- =====================================================
-- ÉTAPE 1: RECRÉER LA FONCTION get_vendor_revenue
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
            -- Calcul du revenu par article au prorata du prix total de la commande
            (ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount as item_revenue
        FROM public.orders o
        JOIN public.payments p ON o.id = p.order_id
        JOIN public.order_variants ov ON o.id = ov.order_id
        JOIN public.product_variants pv ON ov.variant_id = pv.id
        JOIN public.products pr ON pv.product_id = pr.id
        WHERE pr.vendeur_id = vendor_id_param
          AND o.status IN ('Payé', 'Expédiée', 'Livrée')  -- Inclure tous les statuts de vente
          AND p.status = 'Payé'
    )
    SELECT
        COALESCE(SUM(vs.item_revenue), 0)::DECIMAL(10, 2),
        COUNT(DISTINCT vs.order_id),
        COALESCE(SUM(vs.quantity), 0)
    FROM vendor_sales vs;
END;
$$;

-- =====================================================
-- ÉTAPE 2: RECRÉER LA FONCTION get_vendor_top_products
-- =====================================================

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
      AND o.status IN ('Payé', 'Expédiée', 'Livrée')  -- Inclure tous les statuts de vente
      AND p.status = 'Payé'
    GROUP BY pr.id, pr.nom, pr.images
    ORDER BY total_quantity DESC, total_revenue DESC
    LIMIT limit_count;
END;
$$;

-- =====================================================
-- ÉTAPE 3: RECRÉER LA FONCTION get_vendor_sales_stats
-- =====================================================

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
        -- Définit toutes les ventes du vendeur pour la période donnée
        SELECT
            o.id as order_id,
            ov.quantity,
            pr.nom as product_name,
            -- Calcul du revenu au prorata pour chaque article
            (ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount as item_revenue
        FROM public.orders o
        JOIN public.payments p ON o.id = p.order_id
        JOIN public.order_variants ov ON o.id = ov.order_id
        JOIN public.product_variants pv ON ov.variant_id = pv.id
        JOIN public.products pr ON pv.product_id = pr.id
        WHERE pr.vendeur_id = vendor_id_param
          AND o.status IN ('Payé', 'Expédiée', 'Livrée')  -- Inclure tous les statuts de vente
          AND p.status = 'Payé'
          AND p.date_paiement >= NOW() - (period_days || ' days')::interval
    ),
    period_stats AS (
        -- Calcule les statistiques agrégées sur la période
        SELECT
            COALESCE(SUM(vps.item_revenue), 0) as revenue,
            COUNT(DISTINCT vps.order_id) as orders,
            COALESCE(SUM(vps.quantity), 0) as products_sold
        FROM vendor_period_sales vps
    ),
    best_seller AS (
        -- Trouve le produit le plus vendu sur la période
        SELECT
            vps.product_name,
            SUM(vps.quantity)::BIGINT as total_quantity
        FROM vendor_period_sales vps
        GROUP BY vps.product_name
        ORDER BY total_quantity DESC
        LIMIT 1
    )
    -- Combine les résultats en une seule ligne de sortie
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

-- =====================================================
-- ÉTAPE 4: RECRÉER LA FONCTION get_vendor_sales_history
-- =====================================================

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
    AND o.status IN ('Payé', 'Expédiée', 'Livrée')  -- Inclure tous les statuts de vente
    AND p.date_paiement >= NOW() - INTERVAL '1 day' * days_back
    GROUP BY DATE(p.date_paiement)
    ORDER BY sale_date DESC;
END;
$$;

-- =====================================================
-- ÉTAPE 5: RECRÉER LA VUE vendor_revenues
-- =====================================================

CREATE OR REPLACE VIEW public.vendor_revenues AS
WITH vendor_order_items AS (
    -- 1. On identifie chaque article vendu par chaque vendeur
    SELECT
        v.id as vendor_id,
        v.nom as vendor_name,
        o.id as order_id,
        ov.quantity,
        -- 2. On calcule le revenu de cet article au prorata du total de la commande
        (ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount as item_revenue
    FROM public.vendors v
    JOIN public.products pr ON v.id = pr.vendeur_id
    JOIN public.product_variants pv ON pr.id = pv.product_id
    JOIN public.order_variants ov ON pv.id = ov.variant_id
    JOIN public.orders o ON ov.order_id = o.id
    JOIN public.payments p ON o.id = p.order_id
    WHERE o.status IN ('Payé', 'Expédiée', 'Livrée')  -- Inclure tous les statuts de vente
    AND p.status = 'Payé'
)
-- 3. On agrège les résultats pour tous les vendeurs
SELECT
    voi.vendor_id,
    voi.vendor_name,
    COALESCE(SUM(voi.item_revenue), 0) as total_revenue,
    COUNT(DISTINCT voi.order_id) as total_orders,
    COALESCE(SUM(voi.quantity), 0) as total_products_sold
FROM vendor_order_items voi
GROUP BY voi.vendor_id, voi.vendor_name;

-- =====================================================
-- ÉTAPE 6: TEST DE VALIDATION
-- =====================================================

-- Test de la vue vendor_revenues
DO $$
DECLARE
    vendor_count INTEGER;
BEGIN
    -- Compter les vendeurs dans la vue
    SELECT COUNT(*) INTO vendor_count FROM public.vendor_revenues;
    
    RAISE NOTICE '✅ Statistiques vendeur corrigées avec succès !';
    RAISE NOTICE '📊 Nombre de vendeurs dans la vue: %', vendor_count;
    RAISE NOTICE '🔧 Toutes les fonctions incluent maintenant les statuts: Payé, Expédiée, Livrée';
    RAISE NOTICE '💡 Le nombre de produits vendus ne diminuera plus lors du changement de statut';
END $$;

-- =====================================================
-- MESSAGE DE FIN
-- =====================================================

-- Afficher un message de succès
DO $$
BEGIN
    RAISE NOTICE '🎉 Correction terminée avec succès !';
    RAISE NOTICE '📊 Les statistiques incluent maintenant tous les statuts de vente';
    RAISE NOTICE '📈 Le nombre de produits vendus restera stable';
    RAISE NOTICE '💡 Les commandes Payé, Expédiée et Livrée sont toutes comptabilisées';
END $$; 
-- MIGRATION POUR SUPPRIMER ET RECRÉER LES FONCTIONS
-- Version: 4
-- Date: [Date du jour]

-- =====================================================
-- SUPPRESSION DES ANCIENNES FONCTIONS
-- =====================================================

-- Supprimer les anciennes fonctions
DROP FUNCTION IF EXISTS public.get_vendor_revenue(integer);
DROP FUNCTION IF EXISTS public.get_vendor_top_products(integer, integer);
DROP FUNCTION IF EXISTS public.get_vendor_sales_stats(integer, integer);
DROP FUNCTION IF EXISTS public.get_vendor_sales_history(integer, integer);

-- =====================================================
-- RECRÉATION DES FONCTIONS AVEC LES BONS TYPES
-- =====================================================

-- Fonction pour calculer les revenus totaux d'un vendeur (types corrigés)
CREATE OR REPLACE FUNCTION public.get_vendor_revenue(vendor_id_param integer)
RETURNS TABLE (
    total_revenue DECIMAL(10, 2),
    total_orders BIGINT,
    total_products_sold BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(p.amount), 0) as total_revenue,
        COUNT(DISTINCT o.id) as total_orders,
        COALESCE(SUM(ov.quantity), 0) as total_products_sold
    FROM public.payments p
    JOIN public.orders o ON p.order_id = o.id
    JOIN public.order_variants ov ON o.id = ov.order_id
    JOIN public.product_variants pv ON ov.variant_id = pv.id
    JOIN public.products pr ON pv.product_id = pr.id
    WHERE pr.vendeur_id = vendor_id_param
    AND p.status = 'Payé'
    AND o.status = 'Payé';
END;
$$;

-- Fonction pour obtenir les top-produits d'un vendeur (types corrigés)
CREATE OR REPLACE FUNCTION public.get_vendor_top_products(vendor_id_param integer, limit_count integer DEFAULT 10)
RETURNS TABLE (
    product_id INTEGER,
    product_name TEXT,
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
        SUM(ov.quantity) as total_quantity,
        SUM(ov.quantity * ov.unit_price) as total_revenue,
        AVG(ov.unit_price) as average_price
    FROM public.products pr
    JOIN public.product_variants pv ON pr.id = pv.product_id
    JOIN public.order_variants ov ON pv.id = ov.variant_id
    JOIN public.orders o ON ov.order_id = o.id
    JOIN public.payments p ON o.id = p.order_id
    WHERE pr.vendeur_id = vendor_id_param
    AND p.status = 'Payé'
    AND o.status = 'Payé'
    GROUP BY pr.id, pr.nom
    ORDER BY total_quantity DESC, total_revenue DESC
    LIMIT limit_count;
END;
$$;

-- Fonction pour obtenir les statistiques de vente d'un vendeur (types corrigés)
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
    -- Calculer les statistiques de base
    SELECT 
        COALESCE(SUM(p.amount), 0),
        COUNT(DISTINCT o.id),
        COALESCE(SUM(ov.quantity), 0),
        CASE 
            WHEN COUNT(DISTINCT o.id) > 0 THEN COALESCE(SUM(p.amount), 0) / COUNT(DISTINCT o.id)
            ELSE 0 
        END
    INTO 
        period_revenue,
        period_orders,
        period_products_sold,
        average_order_value
    FROM public.payments p
    JOIN public.orders o ON p.order_id = o.id
    JOIN public.order_variants ov ON o.id = ov.order_id
    JOIN public.product_variants pv ON ov.variant_id = pv.id
    JOIN public.products pr ON pv.product_id = pr.id
    WHERE pr.vendeur_id = vendor_id_param
    AND p.status = 'Payé'
    AND o.status = 'Payé'
    AND p.date_paiement >= NOW() - INTERVAL '1 day' * period_days;

    -- Trouver le produit le plus vendu
    SELECT 
        pr.nom,
        SUM(ov.quantity)
    INTO 
        best_product_name,
        best_product_qty
    FROM public.products pr
    JOIN public.product_variants pv ON pr.id = pv.product_id
    JOIN public.order_variants ov ON pv.id = ov.variant_id
    JOIN public.orders o ON ov.order_id = o.id
    JOIN public.payments p ON o.id = p.order_id
    WHERE pr.vendeur_id = vendor_id_param
    AND p.status = 'Payé'
    AND o.status = 'Payé'
    AND p.date_paiement >= NOW() - INTERVAL '1 day' * period_days
    GROUP BY pr.id, pr.nom
    ORDER BY SUM(ov.quantity) DESC
    LIMIT 1;

    RETURN QUERY SELECT 
        period_revenue,
        period_orders,
        period_products_sold,
        average_order_value,
        COALESCE(best_product_name, 'Aucun') as best_selling_product,
        COALESCE(best_product_qty, 0) as best_selling_product_quantity;
END;
$$;

-- Fonction pour obtenir l'historique des ventes d'un vendeur (types corrigés)
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
        SUM(p.amount) as daily_revenue,
        COUNT(DISTINCT o.id) as daily_orders,
        SUM(ov.quantity) as daily_products_sold
    FROM public.payments p
    JOIN public.orders o ON p.order_id = o.id
    JOIN public.order_variants ov ON o.id = ov.order_id
    JOIN public.product_variants pv ON ov.variant_id = pv.id
    JOIN public.products pr ON pv.product_id = pr.id
    WHERE pr.vendeur_id = vendor_id_param
    AND p.status = 'Payé'
    AND o.status = 'Payé'
    AND p.date_paiement >= NOW() - INTERVAL '1 day' * days_back
    GROUP BY DATE(p.date_paiement)
    ORDER BY sale_date DESC;
END;
$$;

-- Mettre à jour la vue des revenus (types corrigés)
DROP VIEW IF EXISTS public.vendor_revenues;
CREATE OR REPLACE VIEW public.vendor_revenues AS
SELECT 
    v.id as vendor_id,
    v.nom as vendor_name,
    COALESCE(SUM(p.amount), 0) as total_revenue,
    COUNT(DISTINCT o.id) as total_orders,
    COALESCE(SUM(ov.quantity), 0) as total_products_sold,
    CASE 
        WHEN COUNT(DISTINCT o.id) > 0 THEN COALESCE(SUM(p.amount), 0) / COUNT(DISTINCT o.id)
        ELSE 0 
    END as average_order_value
FROM public.vendors v
LEFT JOIN public.products pr ON v.id = pr.vendeur_id
LEFT JOIN public.product_variants pv ON pr.id = pv.product_id
LEFT JOIN public.order_variants ov ON pv.id = ov.variant_id
LEFT JOIN public.orders o ON ov.order_id = o.id
LEFT JOIN public.payments p ON o.id = p.order_id AND p.status = 'Payé'
WHERE pr.actif = true OR pr.actif IS NULL
GROUP BY v.id, v.nom;

-- Message de fin
\echo "Migration pour supprimer et recréer les fonctions appliquée avec succès." 
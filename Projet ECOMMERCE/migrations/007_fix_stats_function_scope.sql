-- MIGRATION POUR CORRIGER LA PORTÉE DE LA CTE DANS get_vendor_sales_stats
-- Version: 7
-- Date: [Date du jour]
-- Raison: La fonction get_vendor_sales_stats utilisait une CTE (WITH clause) qui n'était pas visible dans toute la fonction,
-- causant une erreur "relation does not exist". Cette migration restructure la fonction pour résoudre ce problème de portée.

-- =====================================================
-- SUPPRESSION DE L'ANCIENNE FONCTION INCORRECTE
-- =====================================================

DROP FUNCTION IF EXISTS public.get_vendor_sales_stats(integer, integer);

-- =====================================================
-- RECRÉATION DE LA FONCTION AVEC LA STRUCTURE CORRIGÉE
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
          AND o.status = 'Payé'
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

-- Message de fin
\echo "Migration pour corriger la fonction get_vendor_sales_stats appliquée avec succès." 
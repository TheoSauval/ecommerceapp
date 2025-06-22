-- MIGRATION POUR RECRÉER LES FONCTIONS MANQUANTES
-- Version: 6
-- Date: [Date du jour]
-- Raison: Les fonctions get_vendor_sales_stats et get_vendor_sales_history ont été supprimées par erreur dans la migration précédente.
-- Cette migration les recrée avec la logique de calcul des revenus corrigée (au prorata).

-- =====================================================
-- RECRÉATION DES FONCTIONS MANQUANTES
-- =====================================================

-- Fonction pour obtenir les statistiques de vente d'un vendeur (calcul au prorata)
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
    -- Sous-requête pour les ventes du vendeur dans la période
    WITH vendor_period_sales AS (
        SELECT
            o.id as order_id,
            ov.quantity,
            pr.id as product_id,
            pr.nom as product_name,
            -- Calcul du revenu au prorata
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
    )
    -- Calcul des statistiques de base
    SELECT
        COALESCE(SUM(vps.item_revenue), 0),
        COUNT(DISTINCT vps.order_id),
        COALESCE(SUM(vps.quantity), 0),
        CASE
            WHEN COUNT(DISTINCT vps.order_id) > 0 THEN COALESCE(SUM(vps.item_revenue), 0) / COUNT(DISTINCT vps.order_id)
            ELSE 0
        END
    INTO
        period_revenue,
        period_orders,
        period_products_sold,
        average_order_value
    FROM vendor_period_sales vps;

    -- Trouver le produit le plus vendu dans la période
    WITH best_seller AS (
        SELECT
            vps.product_name,
            SUM(vps.quantity)::BIGINT as total_quantity
        FROM vendor_period_sales vps
        GROUP BY vps.product_name
        ORDER BY total_quantity DESC
        LIMIT 1
    )
    SELECT
        bs.product_name,
        bs.total_quantity
    INTO
        best_product_name,
        best_product_qty
    FROM best_seller bs;

    RETURN QUERY SELECT
        period_revenue::DECIMAL(10, 2),
        period_orders,
        period_products_sold,
        average_order_value::DECIMAL(10, 2),
        COALESCE(best_product_name, 'Aucun'),
        COALESCE(best_product_qty, 0);
END;
$$;


-- Fonction pour obtenir l'historique des ventes d'un vendeur (calcul au prorata)
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
    WITH daily_sales AS (
         SELECT
            DATE(p.date_paiement) as sale_day,
            o.id as order_id,
            ov.quantity,
            -- Revenu au prorata par article
            (ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount as item_revenue
        FROM public.orders o
        JOIN public.payments p ON o.id = p.order_id
        JOIN public.order_variants ov ON o.id = ov.order_id
        JOIN public.product_variants pv ON ov.variant_id = pv.id
        JOIN public.products pr ON pv.product_id = pr.id
        WHERE pr.vendeur_id = vendor_id_param
          AND o.status = 'Payé'
          AND p.status = 'Payé'
          AND p.date_paiement >= NOW() - (days_back || ' days')::interval
    )
    SELECT
        ds.sale_day,
        SUM(ds.item_revenue)::DECIMAL(10, 2),
        COUNT(DISTINCT ds.order_id),
        SUM(ds.quantity)::BIGINT
    FROM daily_sales ds
    GROUP BY ds.sale_day
    ORDER BY ds.sale_day DESC;
END;
$$;

-- Message de fin
\echo "Migration pour recréer les fonctions manquantes appliquée avec succès." 
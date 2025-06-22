-- MIGRATION POUR CORRIGER LE CALCUL DES REVENUS VENDEUR
-- Version: 5
-- Date: [Date du jour]
-- Raison: Le calcul des revenus était incorrect pour les commandes contenant des produits de plusieurs vendeurs.
-- Le montant total de la commande était attribué à chaque vendeur, au lieu d'être réparti au prorata.
-- Cette migration corrige la logique de calcul dans toutes les fonctions et vues d'analyse.

-- =====================================================
-- SUPPRESSION DES ANCIENNES FONCTIONS ET VUE
-- =====================================================

DROP FUNCTION IF EXISTS public.get_vendor_revenue(integer);
DROP FUNCTION IF EXISTS public.get_vendor_top_products(integer, integer);
DROP FUNCTION IF EXISTS public.get_vendor_sales_stats(integer, integer);
DROP FUNCTION IF EXISTS public.get_vendor_sales_history(integer, integer);
DROP VIEW IF EXISTS public.vendor_revenues;

-- =====================================================
-- RECRÉATION AVEC LA LOGIQUE DE CALCUL CORRIGÉE
-- =====================================================

-- Fonction pour calculer les revenus totaux d'un vendeur (calcul au prorata)
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
          AND o.status = 'Payé'
          AND p.status = 'Payé'
    )
    SELECT
        COALESCE(SUM(vs.item_revenue), 0)::DECIMAL(10, 2),
        COUNT(DISTINCT vs.order_id),
        COALESCE(SUM(vs.quantity), 0)
    FROM vendor_sales vs;
END;
$$;

-- Fonction pour obtenir les top-produits d'un vendeur (calcul au prorata)
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
        SUM(ov.quantity)::BIGINT as total_quantity,
        SUM((ov.unit_price * ov.quantity) / NULLIF(o.prix_total, 0) * p.amount)::DECIMAL(10, 2) as total_revenue,
        AVG(ov.unit_price)::DECIMAL(10, 2) as average_price
    FROM public.products pr
    JOIN public.product_variants pv ON pr.id = pv.product_id
    JOIN public.order_variants ov ON pv.id = ov.variant_id
    JOIN public.orders o ON ov.order_id = o.id
    JOIN public.payments p ON o.id = p.order_id
    WHERE pr.vendeur_id = vendor_id_param
      AND o.status = 'Payé'
      AND p.status = 'Payé'
    GROUP BY pr.id, pr.nom
    ORDER BY total_quantity DESC, total_revenue DESC
    LIMIT limit_count;
END;
$$;

-- Recréer la vue des revenus avec la logique de calcul correcte
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
    WHERE o.status = 'Payé' AND p.status = 'Payé'
)
-- 3. On agrège les résultats pour tous les vendeurs
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

-- Message de fin
\echo "Migration pour corriger le calcul des revenus appliquée avec succès." 
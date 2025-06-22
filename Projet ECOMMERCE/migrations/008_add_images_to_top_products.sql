-- MIGRATION POUR AJOUTER LES IMAGES AUX TOP-PRODUITS
-- Version: 8
-- Date: [Date du jour]
-- Raison: Ajoute le champ images à la fonction get_vendor_top_products pour pouvoir afficher les images des produits dans le dashboard.

-- =====================================================
-- SUPPRESSION DE L'ANCIENNE FONCTION
-- =====================================================

DROP FUNCTION IF EXISTS public.get_vendor_top_products(integer, integer);

-- =====================================================
-- RECRÉATION DE LA FONCTION AVEC LE CHAMP IMAGES
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_vendor_top_products(vendor_id_param integer, limit_count integer DEFAULT 10)
RETURNS TABLE (
    product_id INTEGER,
    product_name TEXT,
    product_images JSONB, -- Colonne ajoutée pour les images
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
        pr.images as product_images, -- Sélectionner les images du produit
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
    GROUP BY pr.id, pr.nom, pr.images -- Ajouter images au group by
    ORDER BY total_quantity DESC, total_revenue DESC
    LIMIT limit_count;
END;
$$;


-- Message de fin
\echo "Migration pour ajouter les images aux top-produits appliquée avec succès." 
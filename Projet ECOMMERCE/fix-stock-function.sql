-- CORRECTION DE LA FONCTION DECREASE_STOCK POUR SUPPORTER LES UUID
-- ================================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS public.decrease_stock(integer);

-- Créer la nouvelle fonction qui accepte un UUID
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

-- FONCTION POUR RESTAURER LE STOCK LORS DE L'ANNULATION
-- =====================================================

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

-- Message de confirmation
SELECT 'Fonctions decrease_stock et restore_stock créées pour supporter les UUID' as message; 
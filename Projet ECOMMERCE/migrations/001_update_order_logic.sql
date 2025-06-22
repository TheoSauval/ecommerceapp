-- MIGRATION POUR LA GESTION DES STOCKS ET DES STATUTS DE COMMANDE
-- Version: 1
-- Date: [Date du jour]

-- Étape 1: Mettre à jour la contrainte de la table 'orders' pour inclure les nouveaux statuts.
-- Pour cela, nous devons supprimer l'ancienne contrainte et en créer une nouvelle.

-- D'abord, on supprime l'ancienne contrainte.
-- NOTE: Le nom 'orders_status_check' peut varier si Postgres en a généré un automatiquement.
-- Vous pouvez trouver le nom exact dans le panneau de définition de votre table sur Supabase.
ALTER TABLE public.orders DROP CONSTRAINT orders_status_check;

-- Ensuite, on ajoute la nouvelle contrainte avec les valeurs à jour.
ALTER TABLE public.orders
ADD CONSTRAINT orders_status_check CHECK (status IN ('En attente', 'Payé', 'Expédiée', 'Livrée', 'Annulée', 'Échec du paiement'));

-- Étape 2: Ajouter la fonction pour décrémenter le stock.
-- CREATE OR REPLACE est sûr, il mettra à jour la fonction si elle existe déjà.
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

-- Message de fin
\echo "Migration pour la gestion des stocks appliquée avec succès." 
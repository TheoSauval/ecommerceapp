-- MIGRATION DES DONNÉES DE SAUVEGARDE VERS LES NOUVELLES TABLES (VERSION CORRIGÉE)
-- À exécuter après la migration des UUIDs pour restaurer les données existantes
-- Version: 1.1
-- Date: 2025-01-27

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DES DONNÉES DE SAUVEGARDE
-- =====================================================

DO $$
DECLARE
    orders_count INTEGER;
    order_variants_count INTEGER;
    payments_count INTEGER;
BEGIN
    -- Vérifier les données de sauvegarde
    SELECT COUNT(*) INTO orders_count FROM public.orders_backup_manual;
    SELECT COUNT(*) INTO order_variants_count FROM public.order_variants_backup_manual;
    SELECT COUNT(*) INTO payments_count FROM public.payments_backup_manual;
    
    RAISE NOTICE '📊 Données de sauvegarde trouvées:';
    RAISE NOTICE '   • Commandes: %', orders_count;
    RAISE NOTICE '   • Variantes de commandes: %', order_variants_count;
    RAISE NOTICE '   • Paiements: %', payments_count;
    
    IF orders_count = 0 THEN
        RAISE NOTICE '⚠️  Aucune donnée de sauvegarde trouvée. Migration terminée.';
        RETURN;
    END IF;
END $$;

-- =====================================================
-- ÉTAPE 2: MIGRATION DES COMMANDES AVEC MAPPING
-- =====================================================

-- Créer une table temporaire pour mapper les anciens IDs vers les nouveaux UUIDs
CREATE TEMP TABLE id_mapping (
    old_order_id INTEGER,
    new_order_id UUID
);

-- Insérer les commandes de sauvegarde avec de nouveaux UUIDs et capturer le mapping
WITH inserted_orders AS (
    INSERT INTO public.orders (
        id,
        prix_total,
        status,
        user_id,
        adresse_livraison,
        methode_paiement,
        created_at,
        updated_at
    )
    SELECT 
        gen_random_uuid() as id,
        prix_total,
        status,
        user_id,
        adresse_livraison,
        methode_paiement,
        created_at,
        updated_at
    FROM public.orders_backup_manual
    RETURNING id, prix_total, user_id, created_at
)
-- Créer le mapping en utilisant des critères uniques
INSERT INTO id_mapping (new_order_id, old_order_id)
SELECT 
    io.id as new_order_id,
    ob.id as old_order_id
FROM inserted_orders io
JOIN public.orders_backup_manual ob ON 
    io.prix_total = ob.prix_total AND 
    io.user_id = ob.user_id AND 
    io.created_at = ob.created_at;

-- =====================================================
-- ÉTAPE 3: MIGRATION DES VARIANTES DE COMMANDES
-- =====================================================

-- Insérer les variantes de commandes avec les nouveaux UUIDs
INSERT INTO public.order_variants (
    order_id,
    variant_id,
    quantity,
    unit_price
)
SELECT 
    im.new_order_id as order_id,
    ovb.variant_id,
    ovb.quantity,
    ovb.unit_price
FROM public.order_variants_backup_manual ovb
JOIN id_mapping im ON ovb.order_id = im.old_order_id;

-- =====================================================
-- ÉTAPE 4: MIGRATION DES PAIEMENTS
-- =====================================================

-- Insérer les paiements avec les nouveaux UUIDs
INSERT INTO public.payments (
    order_id,
    user_id,
    amount,
    status,
    stripe_payment_intent_id,
    refund_amount,
    date_paiement,
    created_at,
    updated_at
)
SELECT 
    im.new_order_id as order_id,
    pb.user_id,
    pb.amount,
    pb.status,
    pb.stripe_payment_intent_id,
    pb.refund_amount,
    pb.date_paiement,
    pb.created_at,
    pb.updated_at
FROM public.payments_backup_manual pb
JOIN id_mapping im ON pb.order_id = im.old_order_id;

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION DE LA MIGRATION
-- =====================================================

DO $$
DECLARE
    new_orders_count INTEGER;
    new_order_variants_count INTEGER;
    new_payments_count INTEGER;
    mapping_count INTEGER;
BEGIN
    -- Compter les nouvelles données
    SELECT COUNT(*) INTO new_orders_count FROM public.orders;
    SELECT COUNT(*) INTO new_order_variants_count FROM public.order_variants;
    SELECT COUNT(*) INTO new_payments_count FROM public.payments;
    SELECT COUNT(*) INTO mapping_count FROM id_mapping;
    
    RAISE NOTICE '✅ Migration terminée !';
    RAISE NOTICE '📊 Données migrées:';
    RAISE NOTICE '   • Commandes: % (avec UUIDs)', new_orders_count;
    RAISE NOTICE '   • Variantes de commandes: %', new_order_variants_count;
    RAISE NOTICE '   • Paiements: %', new_payments_count;
    RAISE NOTICE '   • Mappings d''IDs: %', mapping_count;
    
    -- Afficher quelques exemples d'UUIDs générés
    RAISE NOTICE '📱 Exemples de nouveaux numéros de commande:';
    FOR i IN 1..3 LOOP
        DECLARE
            sample_order RECORD;
        BEGIN
            SELECT id, prix_total INTO sample_order 
            FROM public.orders 
            ORDER BY created_at DESC 
            LIMIT 1 OFFSET (i-1);
            
            IF FOUND THEN
                RAISE NOTICE '   • Commande #% (%.2f€)', 
                    UPPER(LEFT(sample_order.id::text, 8)), 
                    sample_order.prix_total;
            END IF;
        END;
    END LOOP;
END $$;

-- =====================================================
-- ÉTAPE 6: NETTOYAGE
-- =====================================================

-- Supprimer la table temporaire
DROP TABLE id_mapping;

-- =====================================================
-- MESSAGE DE FIN
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Migration des données terminée avec succès !';
    RAISE NOTICE '💾 Toutes vos données existantes ont été restaurées avec des UUIDs';
    RAISE NOTICE '📱 L''application mobile affichera maintenant des numéros de commande uniques';
    RAISE NOTICE '⚠️  Les tables de sauvegarde sont conservées par sécurité';
    RAISE NOTICE '   Vous pouvez les supprimer manuellement si tout fonctionne bien';
END $$; 
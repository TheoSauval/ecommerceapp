-- Script pour identifier et corriger les doublons dans order_variants
-- Ce script va identifier les entrées en double et les supprimer

-- 1. Identifier les doublons
WITH duplicates AS (
    SELECT 
        order_id,
        variant_id,
        COUNT(*) as count,
        MIN(id) as keep_id,
        array_agg(id) as all_ids
    FROM order_variants
    GROUP BY order_id, variant_id
    HAVING COUNT(*) > 1
)
SELECT 
    'DOUBLONS DÉTECTÉS:' as message,
    order_id,
    variant_id,
    count,
    keep_id,
    all_ids
FROM duplicates
ORDER BY order_id, variant_id;

-- 2. Supprimer les doublons (garder seulement la première occurrence)
-- ATTENTION: Exécuter seulement après avoir vérifié les doublons ci-dessus

/*
DELETE FROM order_variants 
WHERE id IN (
    SELECT id FROM (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY order_id, variant_id ORDER BY id) as rn
        FROM order_variants
    ) t
    WHERE rn > 1
);
*/

-- 3. Vérifier qu'il n'y a plus de doublons
SELECT 
    'VÉRIFICATION APRÈS CORRECTION:' as message,
    order_id,
    variant_id,
    COUNT(*) as count
FROM order_variants
GROUP BY order_id, variant_id
HAVING COUNT(*) > 1
ORDER BY order_id, variant_id;

-- 4. Afficher un résumé des commandes avec leurs variantes
SELECT 
    o.id as order_id,
    o.status,
    o.prix_total,
    COUNT(ov.variant_id) as nb_variants,
    array_agg(DISTINCT ov.variant_id) as variant_ids
FROM orders o
LEFT JOIN order_variants ov ON o.id = ov.order_id
GROUP BY o.id, o.status, o.prix_total
ORDER BY o.created_at DESC; 
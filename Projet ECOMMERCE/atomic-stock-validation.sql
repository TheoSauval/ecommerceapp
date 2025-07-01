-- Fonction pour validation atomique du stock (évite les race conditions)
CREATE OR REPLACE FUNCTION validate_and_reserve_stock(
    order_items JSONB
) RETURNS BOOLEAN AS $$
DECLARE
    item JSONB;
    variant_record RECORD;
    current_stock INTEGER;
    missing_variants TEXT[] := ARRAY[]::TEXT[];
    insufficient_stock TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Vérifier chaque item avec verrouillage de ligne
    FOR item IN SELECT * FROM jsonb_array_elements(order_items)
    LOOP
        -- Récupérer le stock avec verrouillage FOR UPDATE (empêche les modifications concurrentes)
        SELECT stock, products.nom as product_name 
        INTO variant_record
        FROM product_variants 
        JOIN products ON product_variants.product_id = products.id
        WHERE product_variants.id = (item->>'variant_id')::INTEGER
        FOR UPDATE;
        
        IF NOT FOUND THEN
            missing_variants := array_append(missing_variants, (item->>'variant_id')::TEXT);
            CONTINUE;
        END IF;
        
        current_stock := variant_record.stock;
        
        -- Vérifier si le stock est suffisant
        IF current_stock < (item->>'quantity')::INTEGER THEN
            insufficient_stock := array_append(insufficient_stock, 
                variant_record.product_name || ' (disponible: ' || current_stock || ', demandé: ' || (item->>'quantity')::TEXT || ')'
            );
            CONTINUE;
        END IF;
        
        -- Décrémenter immédiatement le stock
        UPDATE product_variants 
        SET stock = stock - (item->>'quantity')::INTEGER
        WHERE id = (item->>'variant_id')::INTEGER;
        
        RAISE NOTICE 'Stock réservé: % - % (disponible: %, demandé: %)', 
            variant_record.product_name, 
            (item->>'variant_id')::INTEGER,
            current_stock,
            (item->>'quantity')::INTEGER;
    END LOOP;
    
    -- Lever des exceptions avec des messages clairs
    IF array_length(missing_variants, 1) > 0 THEN
        RAISE EXCEPTION 'Produits non trouvés: %', array_to_string(missing_variants, ', ');
    END IF;
    
    IF array_length(insufficient_stock, 1) > 0 THEN
        RAISE EXCEPTION 'Stock insuffisant pour: %', array_to_string(insufficient_stock, '; ');
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur, annuler toutes les modifications
        RAISE NOTICE 'Erreur lors de la validation du stock: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour créer une commande avec validation atomique
CREATE OR REPLACE FUNCTION create_order_with_stock_validation(
    p_user_id UUID,
    p_items JSONB,
    p_adresse_livraison TEXT,
    p_methode_paiement TEXT
) RETURNS JSONB AS $$
DECLARE
    order_id UUID;
    total_price DECIMAL(10,2) := 0;
    item JSONB;
    result JSONB;
BEGIN
    -- 1. Validation et réservation atomique du stock
    IF NOT validate_and_reserve_stock(p_items) THEN
        RAISE EXCEPTION 'Échec de la validation du stock - vérifiez les quantités disponibles';
    END IF;
    
    -- 2. Calculer le prix total
    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        total_price := total_price + ((item->>'prix')::DECIMAL * (item->>'quantity')::INTEGER);
    END LOOP;
    
    -- 3. Créer la commande
    INSERT INTO orders (user_id, status, adresse_livraison, methode_paiement, prix_total)
    VALUES (p_user_id, 'En attente', p_adresse_livraison, p_methode_paiement, total_price)
    RETURNING id INTO order_id;
    
    -- 4. Créer les lignes de commande
    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO order_variants (order_id, variant_id, quantity, unit_price)
        VALUES (
            order_id,
            (item->>'variant_id')::INTEGER,
            (item->>'quantity')::INTEGER,
            (item->>'prix')::DECIMAL
        );
    END LOOP;
    
    -- 5. Retourner les informations de la commande
    SELECT jsonb_build_object(
        'id', o.id,
        'user_id', o.user_id,
        'status', o.status,
        'prix_total', o.prix_total,
        'created_at', o.created_at
    ) INTO result
    FROM orders o
    WHERE o.id = order_id;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur, restaurer le stock
        PERFORM restore_stock_from_items(p_items);
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour restaurer le stock en cas d'erreur
CREATE OR REPLACE FUNCTION restore_stock_from_items(
    p_items JSONB
) RETURNS VOID AS $$
DECLARE
    item JSONB;
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        UPDATE product_variants 
        SET stock = stock + (item->>'quantity')::INTEGER
        WHERE id = (item->>'variant_id')::INTEGER;
        
        RAISE NOTICE 'Stock restauré: variant %, quantité %', 
            (item->>'variant_id')::INTEGER,
            (item->>'quantity')::INTEGER;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Test de la fonction
-- SELECT create_order_with_stock_validation(
--     'user-uuid-here',
--     '[{"variant_id": 22, "quantity": 200, "prix": 64.99}]',
--     'Adresse de test',
--     'Stripe'
-- ); 
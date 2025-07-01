-- =====================================================
-- CORRECTION DU TRIGGER DE CRÉATION AUTOMATIQUE DES PROFILS
-- =====================================================

-- Supprimer l'ancien trigger et la fonction s'ils existent
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Recréer la fonction avec une meilleure gestion des erreurs
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier si le profil existe déjà (éviter les doublons)
    IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE id = NEW.id) THEN
        -- Insérer le nouveau profil
        INSERT INTO public.user_profiles (id, nom, prenom, age, role)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'nom', 'Utilisateur'),
            COALESCE(NEW.raw_user_meta_data->>'prenom', 'Anonyme'),
            COALESCE((NEW.raw_user_meta_data->>'age')::integer, 18),
            COALESCE(NEW.raw_user_meta_data->>'role', 'user')
        );
        
        -- Log pour le debugging
        RAISE NOTICE 'Profil utilisateur créé automatiquement pour % (ID: %)', NEW.email, NEW.id;
    ELSE
        RAISE NOTICE 'Profil utilisateur existe déjà pour % (ID: %)', NEW.email, NEW.id;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log l'erreur mais ne pas faire échouer l'insertion de l'utilisateur
        RAISE WARNING 'Erreur lors de la création automatique du profil pour % (ID: %): %', NEW.email, NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recréer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- FONCTION POUR CRÉER MANUELLEMENT LES PROFILS MANQUANTS
-- =====================================================

CREATE OR REPLACE FUNCTION public.create_missing_profiles()
RETURNS TABLE(
    user_id UUID,
    email TEXT,
    profile_created BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    auth_user RECORD;
    profile_exists BOOLEAN;
    create_error TEXT;
BEGIN
    -- Parcourir tous les utilisateurs auth.users
    FOR auth_user IN 
        SELECT id, email, raw_user_meta_data 
        FROM auth.users
    LOOP
        -- Vérifier si le profil existe
        SELECT EXISTS(
            SELECT 1 FROM public.user_profiles WHERE id = auth_user.id
        ) INTO profile_exists;
        
        IF NOT profile_exists THEN
            -- Tenter de créer le profil
            BEGIN
                INSERT INTO public.user_profiles (id, nom, prenom, age, role)
                VALUES (
                    auth_user.id,
                    COALESCE(auth_user.raw_user_meta_data->>'nom', 'Utilisateur'),
                    COALESCE(auth_user.raw_user_meta_data->>'prenom', 'Anonyme'),
                    COALESCE((auth_user.raw_user_meta_data->>'age')::integer, 18),
                    COALESCE(auth_user.raw_user_meta_data->>'role', 'user')
                );
                
                -- Retourner succès
                user_id := auth_user.id;
                email := auth_user.email;
                profile_created := true;
                error_message := NULL;
                RETURN NEXT;
                
            EXCEPTION WHEN OTHERS THEN
                -- Retourner erreur
                user_id := auth_user.id;
                email := auth_user.email;
                profile_created := false;
                error_message := SQLERRM;
                RETURN NEXT;
            END;
        END IF;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FONCTION POUR VÉRIFIER L'ÉTAT DES PROFILS
-- =====================================================

CREATE OR REPLACE FUNCTION public.check_profiles_status()
RETURNS TABLE(
    total_users INTEGER,
    total_profiles INTEGER,
    missing_profiles INTEGER,
    users_without_metadata INTEGER
) AS $$
BEGIN
    -- Compter les utilisateurs auth.users
    SELECT COUNT(*) INTO total_users FROM auth.users;
    
    -- Compter les profils user_profiles
    SELECT COUNT(*) INTO total_profiles FROM public.user_profiles;
    
    -- Compter les utilisateurs sans profil
    SELECT COUNT(*) INTO missing_profiles 
    FROM auth.users u
    WHERE NOT EXISTS (SELECT 1 FROM public.user_profiles p WHERE p.id = u.id);
    
    -- Compter les utilisateurs sans métadonnées
    SELECT COUNT(*) INTO users_without_metadata 
    FROM auth.users 
    WHERE raw_user_meta_data IS NULL OR raw_user_meta_data = '{}';
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- MESSAGE DE CONFIRMATION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Trigger de création automatique des profils recréé avec succès !';
    RAISE NOTICE '🔧 Fonction create_missing_profiles() créée pour corriger les profils manquants';
    RAISE NOTICE '📊 Fonction check_profiles_status() créée pour diagnostiquer l''état des profils';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Utilisation:';
    RAISE NOTICE '  SELECT * FROM public.create_missing_profiles();  -- Créer les profils manquants';
    RAISE NOTICE '  SELECT * FROM public.check_profiles_status();    -- Vérifier l''état';
END $$; 